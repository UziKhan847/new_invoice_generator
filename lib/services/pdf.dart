import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:new_invoice_generator/models/invoice.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PdfService {
  /// Returns raw PDF bytes — used by email, preview, and print
  static Future<Uint8List> buildPdfBytes(Invoice invoice) async {
    final pdf = pw.Document();

    // Fetch logo bytes if URL is available
    pw.MemoryImage? logoImage;
    if (invoice.companyLogoUrl != null && invoice.companyLogoUrl!.isNotEmpty) {
      try {
        final response = await http.get(Uri.parse(invoice.companyLogoUrl!));
        if (response.statusCode == 200) {
          logoImage = pw.MemoryImage(Uint8List.fromList(response.bodyBytes));
        }
      } catch (_) {
        // Logo fetch failed — render without it
      }
    }

    pdf.addPage(
      pw.Page(
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // ── Header: logo + invoice title + sender ────────────────
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Left: logo + INVOICE title
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      if (logoImage != null) ...[
                        pw.Image(
                          logoImage,
                          width: 72,
                          height: 72,
                          fit: pw.BoxFit.contain,
                        ),
                        pw.SizedBox(height: 8),
                      ],
                      pw.Text(
                        'INVOICE',
                        style: pw.TextStyle(
                          fontSize: 28,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blueGrey800,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        '#${invoice.invoiceNumber}',
                        style: const pw.TextStyle(
                          fontSize: 14,
                          color: PdfColors.grey600,
                        ),
                      ),
                    ],
                  ),
                  // Right: sender info
                  if (invoice.senderName != null)
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          invoice.senderName!,
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        if (invoice.senderRole != null)
                          pw.Text(
                            invoice.senderRole!,
                            style: const pw.TextStyle(
                              fontSize: 11,
                              color: PdfColors.grey600,
                            ),
                          ),
                        if (invoice.senderEmail != null)
                          pw.Text(
                            invoice.senderEmail!,
                            style: const pw.TextStyle(
                              fontSize: 11,
                              color: PdfColors.grey600,
                            ),
                          ),
                      ],
                    ),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Divider(color: PdfColors.grey300),
              pw.SizedBox(height: 16),

              // ── Billed to + dates ─────────────────────────────────────
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'BILLED TO',
                        style: pw.TextStyle(
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.grey500,
                          letterSpacing: 1.2,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        invoice.customerName,
                        style: pw.TextStyle(
                          fontSize: 13,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      if (invoice.customerEmail != null)
                        pw.Text(
                          invoice.customerEmail!,
                          style: const pw.TextStyle(
                            fontSize: 11,
                            color: PdfColors.grey600,
                          ),
                        ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'Issue: ${invoice.issueDate.toLocal().toString().split(' ')[0]}',
                        style: const pw.TextStyle(fontSize: 11),
                      ),
                      if (invoice.dueDate != null)
                        pw.Text(
                          'Due: ${invoice.dueDate!.toLocal().toString().split(' ')[0]}',
                          style: const pw.TextStyle(
                            fontSize: 11,
                            color: PdfColors.orange700,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 24),

              // ── Items table header ────────────────────────────────────
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 12,
                ),
                decoration: const pw.BoxDecoration(color: PdfColors.blueGrey50),
                child: pw.Row(
                  children: [
                    pw.Expanded(
                      flex: 5,
                      child: pw.Text(
                        'Description',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    pw.Expanded(
                      flex: 1,
                      child: pw.Text(
                        'Qty',
                        textAlign: pw.TextAlign.center,
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    pw.Expanded(
                      flex: 2,
                      child: pw.Text(
                        'Unit Price',
                        textAlign: pw.TextAlign.right,
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    pw.Expanded(
                      flex: 2,
                      child: pw.Text(
                        'Total',
                        textAlign: pw.TextAlign.right,
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Items ─────────────────────────────────────────────────
              ...invoice.items.asMap().entries.map((entry) {
                final item = entry.value;
                final isEven = entry.key % 2 == 0;
                return pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 12,
                  ),
                  decoration: pw.BoxDecoration(
                    color: isEven ? PdfColors.white : PdfColors.grey50,
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        children: [
                          pw.Expanded(
                            flex: 5,
                            child: pw.Text(
                              item.description,
                              style: const pw.TextStyle(fontSize: 11),
                            ),
                          ),
                          pw.Expanded(
                            flex: 1,
                            child: pw.Text(
                              '${item.quantity}',
                              textAlign: pw.TextAlign.center,
                              style: const pw.TextStyle(fontSize: 11),
                            ),
                          ),
                          pw.Expanded(
                            flex: 2,
                            child: pw.Text(
                              '\$${item.unitPrice.toStringAsFixed(2)}',
                              textAlign: pw.TextAlign.right,
                              style: const pw.TextStyle(fontSize: 11),
                            ),
                          ),
                          pw.Expanded(
                            flex: 2,
                            child: pw.Text(
                              '\$${item.total.toStringAsFixed(2)}',
                              textAlign: pw.TextAlign.right,
                              style: pw.TextStyle(
                                fontSize: 11,
                                fontWeight: item.hasDiscount
                                    ? pw.FontWeight.bold
                                    : null,
                              ),
                            ),
                          ),
                        ],
                      ),
                      // Discount line — only shown when a discount exists
                      if (item.hasDiscount)
                        pw.Padding(
                          padding: const pw.EdgeInsets.only(top: 2),
                          child: pw.Row(
                            children: [
                              pw.Expanded(
                                flex: 5,
                                child: pw.Text(
                                  '  Discount: ${item.discountLabel}  (−\$${item.discountAmount.toStringAsFixed(2)})',
                                  style: const pw.TextStyle(
                                    fontSize: 9,
                                    color: PdfColors.green700,
                                  ),
                                ),
                              ),
                              pw.Expanded(
                                flex: 5,
                                child: pw.Text(
                                  'Was: \$${item.subtotal.toStringAsFixed(2)}',
                                  textAlign: pw.TextAlign.right,
                                  style: const pw.TextStyle(
                                    fontSize: 9,
                                    color: PdfColors.grey500,
                                    decoration: pw.TextDecoration.lineThrough,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                );
              }),

              pw.SizedBox(height: 16),
              pw.Divider(color: PdfColors.grey300),
              pw.SizedBox(height: 8),

              // ── Totals ────────────────────────────────────────────────
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.SizedBox(
                  width: 200,
                  child: pw.Column(
                    children: [
                      _totalRow(
                        'Subtotal',
                        '\$${invoice.subtotal.toStringAsFixed(2)}',
                      ),
                      _totalRow(
                        'Tax (13%)',
                        '\$${invoice.tax.toStringAsFixed(2)}',
                      ),
                      pw.Divider(color: PdfColors.grey400),
                      _totalRow(
                        'Total',
                        '\$${invoice.total.toStringAsFixed(2)}',
                        bold: true,
                        large: true,
                      ),
                    ],
                  ),
                ),
              ),
              pw.SizedBox(height: 32),

              // ── Payment info ────────────────────────────────────────────
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: const pw.BorderRadius.all(
                    pw.Radius.circular(6),
                  ),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'PAYMENT',
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.grey500,
                        letterSpacing: 1.2,
                      ),
                    ),
                    pw.SizedBox(height: 6),
                    if (invoice.isPaid)
                      pw.Text(
                        '✓ PAID',
                        style: pw.TextStyle(
                          fontSize: 13,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.green700,
                        ),
                      )
                    else ...[
                      if (invoice.dueDate != null)
                        pw.Text(
                          'Due by: \${invoice.dueDate!.toLocal().toString().split(\' \')[0]}',
                          style: const pw.TextStyle(
                            fontSize: 11,
                            color: PdfColors.orange700,
                          ),
                        ),
                      if (invoice.senderEmail != null) ...[
                        pw.SizedBox(height: 6),
                        pw.Row(
                          children: [
                            pw.Text(
                              'E-Transfer to: ',
                              style: pw.TextStyle(
                                fontSize: 11,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                            pw.Text(
                              invoice.senderEmail!,
                              style: const pw.TextStyle(
                                fontSize: 11,
                                color: PdfColors.blue800,
                              ),
                            ),
                          ],
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          'Please include invoice #\${invoice.invoiceNumber} in the e-transfer message.',
                          style: const pw.TextStyle(
                            fontSize: 9,
                            color: PdfColors.grey600,
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  /// Print / layout the invoice PDF via the system print dialog
  static Future<void> generateInvoicePdf(Invoice invoice) async {
    final bytes = await buildPdfBytes(invoice);
    await Printing.layoutPdf(onLayout: (_) async => bytes);
  }

  static pw.Widget _totalRow(
    String label,
    String value, {
    bool bold = false,
    bool large = false,
  }) {
    final style = bold
        ? pw.TextStyle(
            fontWeight: pw.FontWeight.bold,
            fontSize: large ? 14 : 11,
          )
        : const pw.TextStyle(fontSize: 11);
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: style),
          pw.Text(value, style: style),
        ],
      ),
    );
  }
}
