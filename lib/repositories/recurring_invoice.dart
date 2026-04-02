import 'package:new_invoice_generator/main.dart';
import 'package:new_invoice_generator/models/recurring_invoice.dart';

class RecurringInvoiceRepository {
  Future<List<RecurringInvoice>> fetchAll(String companyId) async {
    final response = await supabase
        .from('recurring_invoices')
        .select(
          '*, services(name, unit_price), customers(name, email), employees!recurring_invoices_sender_employee_id_fkey(name, role, email)',
        )
        .eq('company_id', companyId)
        .eq('is_active', true)
        .order('created_at', ascending: false);
    return response
        .map<RecurringInvoice>((j) => RecurringInvoice.fromJson(j))
        .toList();
  }

  Future<void> create(RecurringInvoice r, String companyId) async {
    await supabase.from('recurring_invoices').insert(r.toInsertMap(companyId));
  }

  Future<void> update(
    String id, {
    required String label,
    required double price,
    required String frequency,
    String? senderEmployeeId,
  }) async {
    await supabase
        .from('recurring_invoices')
        .update({
          'label': label,
          'price': price,
          'frequency': frequency,
          'sender_employee_id': senderEmployeeId,
        })
        .eq('id', id);
  }

  Future<void> deactivate(String id) async {
    await supabase
        .from('recurring_invoices')
        .update({'is_active': false})
        .eq('id', id);
  }

  Future<void> updateLastGenerated(
    String id,
    String frequency,
    DateTime generated,
  ) async {
    final next = RecurringInvoice.computeNextDue(frequency, from: generated);
    await supabase
        .from('recurring_invoices')
        .update({
          'last_generated_at': generated.toIso8601String().split('T')[0],
          'next_due_date': next.toIso8601String().split('T')[0],
        })
        .eq('id', id);
  }
}
