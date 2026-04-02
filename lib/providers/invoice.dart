import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:new_invoice_generator/providers/company.dart';
import 'package:new_invoice_generator/repositories/invoice.dart';
import 'package:new_invoice_generator/services/invoice_number.dart';
import '../models/invoice.dart';

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
    final invoiceNumber =
        await InvoiceNumberService().generateNextInvoiceNumber(company['id']);
    // Preserve ALL fields from the passed invoice — do not reconstruct
    final numbered = Invoice(
      invoiceNumber: invoiceNumber,
      customerName: invoice.customerName,
      customerId: invoice.customerId,
      customerEmail: invoice.customerEmail,
      items: invoice.items,
      issueDate: invoice.issueDate,
      dueDate: invoice.dueDate,
      senderEmployeeId: invoice.senderEmployeeId,
      senderName: invoice.senderName,
      senderRole: invoice.senderRole,
      senderEmail: invoice.senderEmail,
    );
    await repo.createInvoice(numbered, company['id']);
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
}

final invoiceProvider = AsyncNotifierProvider<InvoiceNotifier, List<Invoice>>(
  InvoiceNotifier.new,
);