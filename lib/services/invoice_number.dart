
import 'package:new_invoice_generator/main.dart';

class InvoiceNumberService {
  Future<String> generateNextInvoiceNumber(String companyId) async {
    // Take the max numeric suffix across all of the company's invoices
    // rather than the most-recently-created row: `created_at` order isn't
    // guaranteed to match invoice-number order (backdated invoices, or a
    // row inserted with a blank number get corrected out of sequence), and
    // an empty/non-numeric invoice_number would otherwise reset the
    // counter back to INV-0001 and collide with an existing invoice.
    final rows = await supabase
        .from('invoices')
        .select('invoice_number')
        .eq('company_id', companyId);

    var maxNumeric = 0;
    for (final row in rows) {
      final raw = row['invoice_number'] as String?;
      if (raw == null || raw.isEmpty) continue;
      final numeric = int.tryParse(raw.replaceAll(RegExp(r'[^0-9]'), ''));
      if (numeric != null && numeric > maxNumeric) maxNumeric = numeric;
    }

    final next = (maxNumeric + 1).toString().padLeft(4, '0');
    return 'INV-$next';
  }
}
