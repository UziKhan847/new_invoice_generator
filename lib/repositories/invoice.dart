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
    if (invoice.items.isNotEmpty) {
      // One batch insert instead of one round trip per item — also avoids
      // leaving the invoice with a subset of its items if a later request
      // in the loop failed partway through.
      await supabase
          .from('invoice_items')
          .insert(invoice.items.map((i) => i.toInsertMap(invoiceId)).toList());
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

    // 2. Replace line items: delete existing, insert current in one batch.
    // A batch insert can't fail partway through an item-by-item loop and
    // leave the invoice with only some of its lines while its header
    // (subtotal/tax/total) already reflects all of them.
    await supabase.from('invoice_items').delete().eq('invoice_id', id);
    if (invoice.items.isNotEmpty) {
      await supabase
          .from('invoice_items')
          .insert(invoice.items.map((i) => i.toInsertMap(id)).toList());
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
