import 'package:new_invoice_generator/main.dart';
import 'package:new_invoice_generator/models/invoice/event.dart';

class InvoiceEventRepository {
  Future<List<InvoiceEvent>> fetchForInvoice(String invoiceId) async {
    final rows = await supabase
        .from('invoice_events')
        .select()
        .eq('invoice_id', invoiceId)
        .order('created_at', ascending: false);
    return (rows as List)
        .map((r) => InvoiceEvent.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  Future<void> log({
    required String invoiceId,
    required String companyId,
    required String type,
    String? detail,
  }) async {
    await supabase.from('invoice_events').insert({
      'invoice_id': invoiceId,
      'company_id': companyId,
      'type': type,
      'detail': ?detail,
    });
  }
}
