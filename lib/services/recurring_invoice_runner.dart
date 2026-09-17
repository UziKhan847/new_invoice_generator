import 'package:new_invoice_generator/main.dart';
import 'package:new_invoice_generator/models/invoice/invoice.dart';
import 'package:new_invoice_generator/models/invoice/item.dart';
import 'package:new_invoice_generator/models/recurring_invoice.dart';
import 'package:new_invoice_generator/repositories/recurring_invoice.dart';
import 'package:new_invoice_generator/services/invoice_number.dart';
import 'package:new_invoice_generator/services/notification.dart';

/// Runs entirely outside of Flutter's widget tree — safe to call from
/// Workmanager background tasks or from AuthGate on app resume.
///
/// Returns the number of invoices that were auto-generated.
class RecurringInvoiceRunner {
  // A single recurring template should never generate more than this many
  // invoices in one run, even if next_due_date is stale by years — caps a
  // runaway catch-up loop from bad/ancient data instead of flooding the
  // company with invoices.
  static const _maxCatchUpPerTemplate = 24;

  static Future<int> checkAndGenerate() async {
    try {
      // 1. Get authenticated user's company
      final user = supabase.auth.currentUser;
      if (user == null) return 0;

      final companyRes = await _fetchCompanyByOwner(
        user.id,
        columns: 'id, tax_rate, tax_label',
      );
      if (companyRes == null) return 0;

      final companyId  = companyRes['id'] as String;
      final taxRate    = (companyRes['tax_rate'] as num?)?.toDouble() ?? 0.13;
      final taxLabel   = companyRes['tax_label'] as String? ?? 'HST';

      // 2. Fetch active recurring invoices that are due (next_due_date <= today)
      final today = DateTime.now();
      final todayStr = today.toIso8601String().split('T')[0];

      final rows = await supabase
          .from('recurring_invoices')
          .select('*, customers(name, email, phone), employees!recurring_invoices_sender_employee_id_fkey(name, role, email)')
          .eq('company_id', companyId)
          .eq('is_active', true)
          .lte('next_due_date', todayStr);

      if (rows.isEmpty) return 0;

      final repo = RecurringInvoiceRepository();
      final numberService = InvoiceNumberService();
      int generated = 0;

      for (final row in rows) {
        try {
          final r = RecurringInvoice.fromJson(row);
          if (r.id == null || r.customerName == null) continue;

          final cust = row['customers'] as Map<String, dynamic>?;
          final emp  = row['employees'] as Map<String, dynamic>?;

          // Catch up every period that fell due while the app was closed
          // instead of collapsing missed periods into one and re-anchoring
          // the schedule to "now" (which silently drops the rest).
          var periodDue = r.nextDueDate ?? today;
          var iterations = 0;
          while (!periodDue.isAfter(today) &&
              iterations < _maxCatchUpPerTemplate) {
            iterations++;

            final invoiceNumber =
                await numberService.generateNextInvoiceNumber(companyId);

            // 3. Build the invoice, dated for the period it represents
            final invoice = Invoice(
              invoiceNumber:     invoiceNumber,
              customerName:      r.customerName!,
              customerId:        r.customerId,
              customerEmail:     cust?['email'] as String?,
              customerPhone:     cust?['phone'] as String?,
              items: [
                InvoiceItem(
                  description: r.label,
                  quantity:    1,
                  unitPrice:   r.price,
                ),
              ],
              issueDate:         periodDue,
              dueDate:           RecurringInvoice.computeNextDue(
                r.frequency,
                from: periodDue,
                dayOfMonth: r.dayOfMonth,
              ),
              senderEmployeeId:  r.senderEmployeeId,
              senderName:        emp?['name'] as String?,
              senderRole:        emp?['role'] as String?,
              senderEmail:       emp?['email'] as String?,
              taxRate:           row['is_export'] == true ? 0.0 : taxRate,
              taxLabel:          row['is_export'] == true ? 'Export (0%)' : taxLabel,
              isExport:          row['is_export'] as bool? ?? false,
              paymentMethod:     row['payment_method'] as String? ?? 'etransfer',
            );

            // 4. Insert invoice
            await supabase.from('invoices').insert(invoice.toInsertMap(companyId));
            generated++;

            // 5. Fire local notification
            await NotificationService.showRecurringGenerated(
              index:         generated,
              customerName:  r.customerName!,
              amount:        '\$${(r.price * (1 + (row['is_export'] == true ? 0 : taxRate))).toStringAsFixed(2)} CAD',
            );

            periodDue = RecurringInvoice.computeNextDue(
              r.frequency,
              from: periodDue,
              dayOfMonth: r.dayOfMonth,
            );
          }

          // 6. Persist the template's last-run timestamp and the next
          // still-in-the-future due date reached by the loop above.
          if (iterations > 0) {
            await repo.updateLastGenerated(r.id!, today, periodDue);
          }
        } catch (_) {
          // Skip this one, continue with others
          continue;
        }
      }

      return generated;
    } catch (_) {
      return 0;
    }
  }

  /// Check for overdue invoices and fire notifications.
  /// Called on app open, not in background (no sensitive data needed).
  static Future<void> checkOverdue() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final companyRes = await _fetchCompanyByOwner(user.id, columns: 'id');
      if (companyRes == null) return;

      final today = DateTime.now();
      final todayStr = today.toIso8601String().split('T')[0];

      final rows = await supabase
          .from('invoices')
          .select('invoice_number, customer_name, due_date')
          .eq('company_id', companyRes['id'])
          .eq('is_paid', false)
          .eq('is_private', false)
          .not('due_date', 'is', null)
          .lte('due_date', todayStr)
          .order('due_date')
          .limit(5); // max 5 overdue notifications at once

      for (int i = 0; i < rows.length; i++) {
        final row = rows[i];
        // Compute days overdue from due_date
        // We don't have due_date in this query - just show the alert
        final dueDate = DateTime.tryParse(row['due_date'] as String? ?? '');
        final daysOverdue = dueDate != null
            ? today.difference(dueDate).inDays
            : 1;
        await NotificationService.showOverdueAlert(
          index:         i,
          invoiceNumber: row['invoice_number'] as String? ?? '',
          customerName:  row['customer_name'] as String? ?? '',
          daysOverdue:   daysOverdue.clamp(1, 999),
        );
      }
    } catch (_) {
      // Silently fail — notifications are non-critical
    }
  }

  /// `.maybeSingle()` throws PostgrestException if more than one row
  /// matches. A company that still has a leftover duplicate row shouldn't
  /// make every background check fail silently forever — take the oldest
  /// matching row deterministically instead (mirrors CompanyRepository).
  static Future<Map<String, dynamic>?> _fetchCompanyByOwner(
    String ownerId, {
    required String columns,
  }) async {
    final rows = await supabase
        .from('companies')
        .select(columns)
        .eq('owner_id', ownerId)
        .order('created_at', ascending: true)
        .limit(1);
    return rows.isEmpty ? null : rows.first;
  }
}
