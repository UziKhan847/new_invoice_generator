import 'package:new_invoice_generator/main.dart';
import 'package:new_invoice_generator/models/invoice/invoice.dart';

class InvoiceRepository {
  Future<List<Invoice>> fetchInvoices(String companyId) async {
    final response = await supabase
        .from('invoices')
        .select(
          // Join customers for email, employees via explicit FK hint
          '*, invoice_items(*), customers(email, phone), employees!invoices_sender_employee_id_fkey(name, role, email)',
        )
        .eq('company_id', companyId)
        .order('issue_date', ascending: false)
        .order('created_at', ascending: false);
    return response.map<Invoice>((json) => Invoice.fromJson(json)).toList();
  }

  Future<void> createInvoice(Invoice invoice, String companyId) async {
    final inserted = await supabase
        .from('invoices')
        .insert(invoice.toInsertMap(companyId))
        .select()
        .single();
    final invoiceId = inserted['id'];
    for (final item in invoice.items) {
      await supabase.from('invoice_items').insert(item.toInsertMap(invoiceId));
    }
  }

  /// Update an existing invoice in place (same id, same invoice number).
  /// Replaces the invoice row's fields and rewrites its line items.
  Future<void> updateInvoice(Invoice invoice) async {
    if (invoice.id == null) {
      throw ArgumentError('Cannot update an invoice without an id');
    }
    final id = invoice.id!;

    // 1. Update the invoice row (toUpdateMap omits company_id/created_at)
    await supabase.from('invoices').update(invoice.toUpdateMap()).eq('id', id);

    // 2. Replace line items: delete existing, insert current
    await supabase.from('invoice_items').delete().eq('invoice_id', id);
    for (final item in invoice.items) {
      await supabase.from('invoice_items').insert(item.toInsertMap(id));
    }
  }

  Future<void> markPaid(String invoiceId) async {
    await supabase
        .from('invoices')
        .update({'is_paid': true, 'status': 'paid'})
        .eq('id', invoiceId);
  }

  Future<void> markManyPaid(List<String> invoiceIds) async {
    await supabase
        .from('invoices')
        .update({'is_paid': true, 'status': 'paid'})
        .inFilter('id', invoiceIds);
  }

  Future<void> deleteInvoice(String invoiceId) async {
    await supabase.from('invoices').delete().eq('id', invoiceId);
  }

  Future<void> deleteMany(List<String> invoiceIds) async {
    await supabase.from('invoices').delete().inFilter('id', invoiceIds);
  }
}
