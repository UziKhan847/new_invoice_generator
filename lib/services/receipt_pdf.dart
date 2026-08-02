import 'package:new_invoice_generator/models/invoice/invoice.dart';
import 'package:new_invoice_generator/services/pdf_fonts.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ReceiptPdfService {
  static Future<void> generateReceipt(Invoice invoice) async {
    await PdfFonts.ensureLoaded();
    final pdf = pw.Document(theme: PdfFonts.theme);
    final datePaid = DateTime.now();
    final formattedDate =
        '${datePaid.year}-${datePaid.month.toString().padLeft(2, '0')}-${datePaid.day.toString().padLeft(2, '0')}';

    pdf.addPage(
      pw.Page(
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'Receipt',
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 16),
            pw.Text('Invoice: ${invoice.invoiceNumber}'),
            pw.Text('Customer: ${invoice.customerName}'),
            pw.Text('Subtotal: \$${invoice.subtotal.toStringAsFixed(2)}'),
            pw.Text('Tax (13%): \$${invoice.tax.toStringAsFixed(2)}'),
            pw.Text('Total Paid: \$${invoice.total.toStringAsFixed(2)}'),
            pw.Text('Date Paid: $formattedDate'),
          ],
        ),
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }
}
