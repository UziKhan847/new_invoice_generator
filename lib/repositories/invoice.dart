import 'package:new_invoice_generator/main.dart';
import 'package:new_invoice_generator/models/invoice.dart';

class InvoiceRepository {
  Future<List<Invoice>> fetchInvoices(String companyId) async {
    final response = await supabase
        .from('invoices')
        .select(
          // Join customers for email, employees via explicit FK hint
          '*, invoice_items(*), customers(email), employees!invoices_sender_employee_id_fkey(name, role, email)',
        )
        .eq('company_id', companyId)
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

  Future<void> markPaid(String invoiceId) async {
    await supabase.from('invoices').update({
      'is_paid': true,
      'status': 'paid',
    }).eq('id', invoiceId);
  }

  Future<void> deleteInvoice(String invoiceId) async {
    await supabase.from('invoices').delete().eq('id', invoiceId);
  }
}