import 'dart:io';
import 'package:flutter/material.dart';
import 'package:new_invoice_generator/models/invoice.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class EmailService {
  static Future<void> emailInvoice({
    required BuildContext context,
    required Invoice invoice,
    required String recipientEmail,
  }) async {
    // 1. Build PDF
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        build: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Invoice #${invoice.invoiceNumber}',
                style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 6),
            pw.Text('Customer: ${invoice.customerName}'),
            pw.Text('Date: ${invoice.issueDate.toLocal().toString().split(' ')[0]}'),
            if (invoice.dueDate != null)
              pw.Text('Due: ${invoice.dueDate!.toLocal().toString().split(' ')[0]}'),
            pw.SizedBox(height: 14),
            pw.Divider(),
            pw.SizedBox(height: 8),
            pw.Row(children: [
              pw.Expanded(child: pw.Text('Description')),
              pw.Text('Qty   Unit Price   Total'),
            ]),
            pw.SizedBox(height: 6),
            ...invoice.items.map((item) => pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 3),
                  child: pw.Row(children: [
                    pw.Expanded(child: pw.Text(item.description)),
                    pw.Text(
                        '${item.quantity}   \$${item.unitPrice.toStringAsFixed(2)}   \$${item.total.toStringAsFixed(2)}'),
                  ]),
                )),
            pw.SizedBox(height: 10),
            pw.Divider(),
            pw.SizedBox(height: 8),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text('Subtotal: \$${invoice.subtotal.toStringAsFixed(2)}'),
                  pw.Text('Tax (13%): \$${invoice.tax.toStringAsFixed(2)}'),
                  pw.SizedBox(height: 4),
                  pw.Text('Total: \$${invoice.total.toStringAsFixed(2)}',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    // 2. Save to temp file
    final dir = await getTemporaryDirectory();
    final filePath = '${dir.path}/invoice_${invoice.invoiceNumber}.pdf';
    final file = File(filePath);
    await file.writeAsBytes(await pdf.save());

    // 3. Open native mail app with pre-filled fields
    final subject = Uri.encodeComponent('Invoice ${invoice.invoiceNumber}');
    final body = Uri.encodeComponent(
      'Please find attached invoice ${invoice.invoiceNumber} for \$${invoice.total.toStringAsFixed(2)}.\n\nThank you.',
    );
    final mailUri = Uri.parse('mailto:$recipientEmail?subject=$subject&body=$body');

    if (await canLaunchUrl(mailUri)) {
      await launchUrl(mailUri);
    }

    // 4. Open share sheet so user can attach the PDF
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(filePath, mimeType: 'application/pdf')],
        subject: 'Invoice ${invoice.invoiceNumber}',
        text: 'Invoice PDF attached',
      ),
    );
  }
}

// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:new_invoice_generator/models/invoice.dart';
// import 'package:open_filex/open_filex.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:pdf/widgets.dart' as pw;
// import 'package:url_launcher/url_launcher.dart';

// class EmailService {
//   /// Generates the invoice PDF, saves it to temp dir, then opens the
//   /// native mail app with the recipient pre-filled.
//   /// The user attaches the PDF manually from their downloads/files.
//   /// (Direct attachment requires platform-specific share sheet.)
//   static Future<void> emailInvoice({
//     required BuildContext context,
//     required Invoice invoice,
//     required String recipientEmail,
//   }) async {
//     // 1. Build PDF bytes
//     final pdf = pw.Document();
//     pdf.addPage(
//       pw.Page(
//         build: (ctx) => pw.Column(
//           crossAxisAlignment: pw.CrossAxisAlignment.start,
//           children: [
//             pw.Text('Invoice #${invoice.invoiceNumber}',
//                 style: pw.TextStyle(
//                     fontSize: 22, fontWeight: pw.FontWeight.bold)),
//             pw.SizedBox(height: 6),
//             pw.Text('Customer: ${invoice.customerName}'),
//             pw.Text(
//                 'Date: ${invoice.issueDate.toLocal().toString().split(' ')[0]}'),
//             if (invoice.dueDate != null)
//               pw.Text(
//                   'Due: ${invoice.dueDate!.toLocal().toString().split(' ')[0]}'),
//             pw.SizedBox(height: 14),
//             pw.Divider(),
//             pw.SizedBox(height: 8),
//             pw.Row(
//               children: [
//                 pw.Expanded(child: pw.Text('Description')),
//                 pw.Text('Qty   Unit Price   Total'),
//               ],
//             ),
//             pw.SizedBox(height: 6),
//             ...invoice.items.map((item) => pw.Padding(
//                   padding: const pw.EdgeInsets.symmetric(vertical: 3),
//                   child: pw.Row(children: [
//                     pw.Expanded(child: pw.Text(item.description)),
//                     pw.Text(
//                         '${item.quantity}   \$${item.unitPrice.toStringAsFixed(2)}   \$${item.total.toStringAsFixed(2)}'),
//                   ]),
//                 )),
//             pw.SizedBox(height: 10),
//             pw.Divider(),
//             pw.SizedBox(height: 8),
//             pw.Align(
//               alignment: pw.Alignment.centerRight,
//               child: pw.Column(
//                 crossAxisAlignment: pw.CrossAxisAlignment.end,
//                 children: [
//                   pw.Text(
//                       'Subtotal: \$${invoice.subtotal.toStringAsFixed(2)}'),
//                   pw.Text('Tax (13%): \$${invoice.tax.toStringAsFixed(2)}'),
//                   pw.SizedBox(height: 4),
//                   pw.Text('Total: \$${invoice.total.toStringAsFixed(2)}',
//                       style:
//                           pw.TextStyle(fontWeight: pw.FontWeight.bold)),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );

//     // 2. Save to temp file
//     final dir = await getTemporaryDirectory();
//     final file = File('${dir.path}/invoice_${invoice.invoiceNumber}.pdf');
//     await file.writeAsBytes(await pdf.save());

//     // 3. Open mail app with pre-filled fields
//     final subject =
//         Uri.encodeComponent('Invoice ${invoice.invoiceNumber}');
//     final body = Uri.encodeComponent(
//       'Please find attached invoice ${invoice.invoiceNumber} for \$${invoice.total.toStringAsFixed(2)}.\n\nThank you.',
//     );
//     final mailUri =
//         Uri.parse('mailto:$recipientEmail?subject=$subject&body=$body');

//     if (await canLaunchUrl(mailUri)) {
//       await launchUrl(mailUri);
//       // Open the saved PDF so user can attach it manually
//       await OpenFilex.open(file.path);
//     } else {
//       if (context.mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Could not open mail app')),
//         );
//       }
//     }
//   }
// }