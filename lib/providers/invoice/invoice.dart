import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:new_invoice_generator/providers/company.dart';
import 'package:new_invoice_generator/repositories/invoice.dart';
import 'package:new_invoice_generator/services/invoice_number.dart';
import '../../models/invoice/invoice.dart';

class InvoiceNotifier extends AsyncNotifier<List<Invoice>> {
  final repo = InvoiceRepository();

  Future<List<Invoice>> _fetch() async {
    final company = await ref.read(companyProvider.future);
    return repo.fetchInvoices(company['id']);
  }

  @override
  Future<List<Invoice>> build() => _fetch();

  Future<void> addInvoice(Invoice invoice) async {
    final company = await ref.read(companyProvider.future);
    final invoiceNumber = await InvoiceNumberService()
        .generateNextInvoiceNumber(company['id']);
    // copyWith preserves ALL fields (including address snapshots & company info)
    final numbered = invoice.copyWith(invoiceNumber: invoiceNumber);
    await repo.createInvoice(numbered, company['id']);
    ref.invalidateSelf();
    await future;
  }

  /// Update an existing invoice in place. Preserves id + invoice number.
  Future<void> updateInvoice(Invoice invoice) async {
    await repo.updateInvoice(invoice);
    ref.invalidateSelf();
    await future;
  }

  Future<void> markPaid(String id) async {
    await repo.markPaid(id);
    ref.invalidateSelf();
    await future;
  }

  Future<void> deleteInvoice(String id) async {
    await repo.deleteInvoice(id);
    ref.invalidateSelf();
    await future;
  }

  /// Duplicates an existing invoice: same items/customer/sender/notes,
  /// new invoice number, today's issue date, unpaid status.
  /// Build a duplicate Invoice object preserving ALL settings except
  /// invoice number, issue date, and paid status. Doesn't save —
  /// the caller decides whether to edit or save directly.
  Invoice buildDuplicate(Invoice source) => Invoice(
    invoiceNumber: '',
    customerName: source.customerName,
    customerId: source.customerId,
    customerEmail: source.customerEmail,
    customerPhone: source.customerPhone,
    items: source.items,
    issueDate: DateTime.now(),
    dueDate: source.dueDate,
    senderEmployeeId: source.senderEmployeeId,
    senderName: source.senderName,
    senderRole: source.senderRole,
    senderEmail: source.senderEmail,
    notes: source.notes,
    taxRate: source.taxRate,
    taxLabel: source.taxLabel,
    isExport: source.isExport,
    isPrivate: source.isPrivate,
    stripePaymentLink: source.stripePaymentLink,
    paymentMethod: source.paymentMethod,
  );

  /// Duplicate and save immediately (no editing).
  Future<void> duplicateInvoice(Invoice source) async {
    await addInvoice(buildDuplicate(source));
  }
}

final invoiceProvider = AsyncNotifierProvider<InvoiceNotifier, List<Invoice>>(
  InvoiceNotifier.new,
);
