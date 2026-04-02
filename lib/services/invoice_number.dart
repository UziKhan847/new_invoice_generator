
import 'package:new_invoice_generator/main.dart';

class InvoiceNumberService {
  Future<String> generateNextInvoiceNumber(String companyId) async {
    final response = await supabase
        .from('invoices')
        .select('invoice_number')
        .eq('company_id', companyId)
        .order('created_at', ascending: false)
        .limit(1);

    if (response.isEmpty) {
      return 'INV-0001';
    }

    final lastNumber = response.first['invoice_number'] as String;
    final numeric =
        int.tryParse(lastNumber.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    final next = (numeric + 1).toString().padLeft(4, '0');
    return 'INV-$next';
  }
}