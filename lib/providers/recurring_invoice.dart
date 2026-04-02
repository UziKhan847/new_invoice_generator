import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:new_invoice_generator/models/invoice.dart';
import 'package:new_invoice_generator/models/invoice_item.dart';
import 'package:new_invoice_generator/models/recurring_invoice.dart';
import 'package:new_invoice_generator/providers/company.dart';
import 'package:new_invoice_generator/providers/invoice.dart';
import 'package:new_invoice_generator/repositories/recurring_invoice.dart';

class RecurringInvoiceNotifier
    extends AsyncNotifier<List<RecurringInvoice>> {
  final _repo = RecurringInvoiceRepository();

  @override
  Future<List<RecurringInvoice>> build() async {
    final company = await ref.read(companyProvider.future);
    return _repo.fetchAll(company['id'] as String);
  }

  Future<void> create(RecurringInvoice r) async {
    final company = await ref.read(companyProvider.future);
    await _repo.create(r, company['id'] as String);
    ref.invalidateSelf();
    await future;
  }

  // Named parameters match exactly what the screen passes
  Future<void> updateTemplate(
    String id, {
    required String label,
    required double price,
    required String frequency,
    String? senderEmployeeId,
  }) async {
    await _repo.update(
      id,
      label: label,
      price: price,
      frequency: frequency,
      senderEmployeeId: senderEmployeeId,
    );
    ref.invalidateSelf();
    await future;
  }

  Future<void> deactivate(String id) async {
    await _repo.deactivate(id);
    ref.invalidateSelf();
    await future;
  }

  // Named parameters match exactly what the screen passes
  Future<void> generateNow(
    RecurringInvoice r, {
    required String customerName,
    required double adjustedPrice,
    required String adjustedLabel,
    String? senderEmployeeId,
    String? senderName,
    String? senderRole,
    String? senderEmail,
  }) async {
    final now = DateTime.now();
    final invoice = Invoice(
      invoiceNumber: '',
      customerName: customerName,
      customerId: r.customerId,
      items: [
        InvoiceItem(
          description: adjustedLabel,
          quantity: 1,
          unitPrice: adjustedPrice,
        ),
      ],
      issueDate: now,
      dueDate: RecurringInvoice.computeNextDue(r.frequency, from: now),
      senderEmployeeId: senderEmployeeId,
      senderName: senderName,
      senderRole: senderRole,
      senderEmail: senderEmail,
    );
    await ref.read(invoiceProvider.notifier).addInvoice(invoice);
    // Repo signature: updateLastGenerated(String id, String frequency, DateTime)
    await _repo.updateLastGenerated(r.id!, r.frequency, now);
    ref.invalidateSelf();
    await future;
  }
}

final recurringInvoiceProvider =
    AsyncNotifierProvider<RecurringInvoiceNotifier, List<RecurringInvoice>>(
  RecurringInvoiceNotifier.new,
);