import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:new_invoice_generator/models/address.dart';
import 'package:new_invoice_generator/models/customer.dart';
import 'package:new_invoice_generator/models/invoice/invoice.dart';
import 'package:new_invoice_generator/services/pdf_fonts.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PdfService {
  // Design palette (matches the app's refined-indigo theme)
  static const _brandIndigo = PdfColor.fromInt(0xFF2C56B5);
  static const _inkColor = PdfColor.fromInt(0xFF172234);
  static const _mutedColor = PdfColor.fromInt(0xFF5C6878);
  static const _tintIndigo = PdfColor.fromInt(0xFFEEF3FC);
  static const _tintBorder = PdfColor.fromInt(0xFFD7E2F6);
  static const _successGreen = PdfColor.fromInt(0xFF157A45);

  /// Returns raw PDF bytes — used by email, preview, and print.
  /// [company] is the live company record used as a fallback for invoices
  /// created before business-info snapshots existed (or when snapshot is empty).
  static Future<Uint8List> buildPdfBytes(
    Invoice invoice, {
    Map<String, dynamic>? company,
    Customer? customer,
  }) async {
    await PdfFonts.ensureLoaded();
    final pdf = pw.Document(theme: PdfFonts.theme);

    // Resolve effective business info: prefer the invoice snapshot, fall back
    // to the live company record so the PDF is never missing the header.
    String? pick(String? snap, String key) {
      if (snap != null && snap.isNotEmpty) return snap;
      final v = company?[key] as String?;
      return (v != null && v.isNotEmpty) ? v : null;
    }

    final bizName = pick(invoice.companyName, 'name') ?? 'My Company';
    final bizEmail = pick(invoice.companyEmail, 'email');
    final bizPhone = pick(invoice.companyPhone, 'phone');
    final bizBN = pick(invoice.businessNumber, 'business_number');
    final bizRT = pick(invoice.rtNumber, 'rt_number');
    final bizAddr = invoice.companyAddress.isNotEmpty
        ? invoice.companyAddress
        : (company != null
              ? Address(
                  line: company['address_line'] as String? ?? '',
                  city: company['city'] as String? ?? '',
                  province: company['province_region'] as String? ?? '',
                  postalCode: company['postal_code'] as String? ?? '',
                  country: company['country'] as String? ?? 'Canada',
                )
              : invoice.companyAddress);
    final bizTaxLine = _businessTaxLineFrom(bizBN, bizRT);

    // Resolve effective customer info: prefer the invoice's frozen snapshot,
    // fall back to the live customer record so older invoices still show details.
    final custName = invoice.customerName.isNotEmpty
        ? invoice.customerName
        : (customer?.name ?? '');
    final custEmail =
        (invoice.customerEmail != null && invoice.customerEmail!.isNotEmpty)
        ? invoice.customerEmail
        : (customer?.email.isNotEmpty == true ? customer!.email : null);
    final custPhone =
        (invoice.customerPhone != null && invoice.customerPhone!.isNotEmpty)
        ? invoice.customerPhone
        : (customer?.phone.isNotEmpty == true ? customer!.phone : null);
    final custAddr = invoice.customerAddress.isNotEmpty
        ? invoice.customerAddress
        : (customer?.address ?? const Address());

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
              // ── Header: business identity (left) + logo (right) ─────
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Left: business name + BN/RT + address + contact
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          bizName,
                          style: pw.TextStyle(
                            fontSize: 20,
                            fontWeight: pw.FontWeight.bold,
                            color: _inkColor,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        if (bizTaxLine.isNotEmpty)
                          pw.Text(
                            bizTaxLine,
                            style: const pw.TextStyle(
                              fontSize: 9,
                              color: PdfColors.grey700,
                            ),
                          ),
                        ...bizAddr.lines.map(
                          (l) => pw.Text(
                            l,
                            style: const pw.TextStyle(
                              fontSize: 9,
                              color: PdfColors.grey700,
                            ),
                          ),
                        ),
                        if (bizEmail != null)
                          pw.Text(
                            bizEmail,
                            style: const pw.TextStyle(
                              fontSize: 9,
                              color: PdfColors.grey700,
                            ),
                          ),
                        if (bizPhone != null)
                          pw.Text(
                            bizPhone,
                            style: const pw.TextStyle(
                              fontSize: 9,
                              color: PdfColors.grey700,
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Right: logo + doc type (INVOICE/RECEIPT)
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      if (logoImage != null) ...[
                        pw.Image(
                          logoImage,
                          width: 80,
                          height: 80,
                          fit: pw.BoxFit.contain,
                        ),
                        pw.SizedBox(height: 4),
                      ],
                      pw.Text(
                        invoice.isPaid ? 'RECEIPT' : 'INVOICE',
                        style: pw.TextStyle(
                          fontSize: 13,
                          fontWeight: pw.FontWeight.bold,
                          letterSpacing: 2,
                          color: _brandIndigo,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 8),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text(
                    '#${invoice.invoiceNumber}',
                    style: pw.TextStyle(
                      fontSize: 22,
                      fontWeight: pw.FontWeight.bold,
                      color: _inkColor,
                    ),
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 5,
                    ),
                    decoration: pw.BoxDecoration(
                      color: invoice.isPaid
                          ? const PdfColor.fromInt(0xFFE7F4EC)
                          : const PdfColor.fromInt(0xFFFBF1DE),
                      borderRadius: const pw.BorderRadius.all(
                        pw.Radius.circular(20),
                      ),
                    ),
                    child: pw.Row(
                      mainAxisSize: pw.MainAxisSize.min,
                      children: [
                        pw.Container(
                          width: 7,
                          height: 7,
                          decoration: pw.BoxDecoration(
                            color: invoice.isPaid
                                ? _successGreen
                                : const PdfColor.fromInt(0xFFA87A22),
                            shape: pw.BoxShape.circle,
                          ),
                        ),
                        pw.SizedBox(width: 6),
                        pw.Text(
                          invoice.isPaid ? 'Paid' : 'Unpaid',
                          style: pw.TextStyle(
                            fontSize: 11,
                            fontWeight: pw.FontWeight.bold,
                            color: invoice.isPaid
                                ? _successGreen
                                : const PdfColor.fromInt(0xFFA87A22),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 16),
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
                        custName,
                        style: pw.TextStyle(
                          fontSize: 13,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      ...custAddr.lines.map(
                        (l) => pw.Text(
                          l,
                          style: const pw.TextStyle(
                            fontSize: 10,
                            color: PdfColors.grey700,
                          ),
                        ),
                      ),
                      if (custPhone != null)
                        pw.Text(
                          custPhone,
                          style: const pw.TextStyle(
                            fontSize: 10,
                            color: PdfColors.grey600,
                          ),
                        ),
                      if (custEmail != null)
                        pw.Text(
                          custEmail,
                          style: const pw.TextStyle(
                            fontSize: 10,
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
                              item.quantityDisplay,
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
                        'Pre-discount Subtotal',
                        '\$${invoice.taxableSubtotal.toStringAsFixed(2)}',
                      ),
                      if (invoice.totalDiscountAmount > 0)
                        _totalRow(
                          'Total Discounts',
                          '−\$${invoice.totalDiscountAmount.toStringAsFixed(2)}',
                          color: PdfColors.green700,
                        ),
                      if (invoice.totalDiscountAmount > 0)
                        _totalRow(
                          'Subtotal after discounts',
                          '\$${invoice.subtotal.toStringAsFixed(2)}',
                        ),
                      _totalRow(
                        invoice.isExport
                            ? 'Export - 0% Tax'
                            : '${invoice.taxLabel} (${_pctStr(invoice.effectiveTaxRate)})',
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

              // ── Payment info — conditional on paymentMethod ────────────
              pw.Container(
                padding: const pw.EdgeInsets.all(14),
                decoration: pw.BoxDecoration(
                  color: _tintIndigo,
                  border: pw.Border.all(color: _tintBorder),
                  borderRadius: const pw.BorderRadius.all(
                    pw.Radius.circular(10),
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
                      pw.Row(
                        mainAxisSize: pw.MainAxisSize.min,
                        children: [
                          pw.Container(
                            width: 14,
                            height: 14,
                            decoration: const pw.BoxDecoration(
                              color: PdfColors.green700,
                              shape: pw.BoxShape.circle,
                            ),
                            alignment: pw.Alignment.center,
                            child: pw.Text(
                              'P',
                              style: pw.TextStyle(
                                fontSize: 9,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.white,
                              ),
                            ),
                          ),
                          pw.SizedBox(width: 6),
                          pw.Text(
                            'PAID',
                            style: pw.TextStyle(
                              fontSize: 13,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.green700,
                            ),
                          ),
                        ],
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
                      pw.SizedBox(height: 6),
                      // E-Transfer
                      if (invoice.paymentMethod == 'etransfer' &&
                          invoice.senderEmail != null) ...[
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
                      // Stripe
                      if (invoice.paymentMethod == 'stripe') ...[
                        pw.Text(
                          'Pay online via Stripe',
                          style: pw.TextStyle(
                            fontSize: 11,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.deepPurple,
                          ),
                        ),
                        if (invoice.stripePaymentLink != null) ...[
                          pw.SizedBox(height: 4),
                          pw.UrlLink(
                            destination: invoice.stripePaymentLink!,
                            child: pw.Text(
                              invoice.stripePaymentLink!,
                              style: const pw.TextStyle(
                                fontSize: 10,
                                color: PdfColors.blue700,
                                decoration: pw.TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                        pw.SizedBox(height: 2),
                        pw.Text(
                          'Amount: \$${invoice.total.toStringAsFixed(2)} CAD',
                          style: const pw.TextStyle(
                            fontSize: 9,
                            color: PdfColors.grey600,
                          ),
                        ),
                      ],
                      // Other — no instructions
                      if (invoice.paymentMethod == 'other')
                        pw.Text(
                          'See notes for payment details.',
                          style: const pw.TextStyle(
                            fontSize: 11,
                            color: PdfColors.grey600,
                          ),
                        ),
                    ],
                  ],
                ),
              ),

              // ── Notes (inline, if present) ─────────────────────────
              if (invoice.notes != null && invoice.notes!.isNotEmpty) ...[
                pw.SizedBox(height: 16),
                pw.Text(
                  'NOTES',
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.grey500,
                    letterSpacing: 1.2,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  invoice.notes!,
                  style: const pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey700,
                  ),
                ),
              ],

              // ── Thank-you footer ───────────────────────────────────
              pw.Spacer(),
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(
                      'Thank you for your business!',
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                        color: _brandIndigo,
                      ),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      'We look forward to serving you again',
                      style: const pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey600,
                      ),
                    ),
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

  /// Business/tax registration line: "BN: 123456789 RT 0001"
  static String _businessTaxLineFrom(String? bn, String? rt) {
    final parts = <String>[];
    if (bn != null && bn.isNotEmpty) parts.add('BN: $bn');
    if (rt != null && rt.isNotEmpty) parts.add('RT $rt');
    return parts.join('  ');
  }

  /// Percentage string: 0.13 -> "13%", 0.14975 -> "14.975%"
  static String _pctStr(double rate) {
    final pct = rate * 100;
    if (pct == pct.truncateToDouble()) return '${pct.toInt()}%';
    return '${pct.toStringAsFixed(3).replaceAll(RegExp(r'0+\$'), '').replaceAll(RegExp(r'\.\$'), '')}%';
  }

  static pw.Widget _totalRow(
    String label,
    String value, {
    bool bold = false,
    bool large = false,
    PdfColor? color,
    PdfColor? valueColor,
  }) {
    final labelStyle = pw.TextStyle(
      fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
      fontSize: large ? 15 : 11,
      color: color ?? (large ? _inkColor : _mutedColor),
    );
    final valueStyle = pw.TextStyle(
      fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
      fontSize: large ? 18 : 11,
      color: valueColor ?? color ?? (large ? _brandIndigo : _inkColor),
    );
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: labelStyle),
          pw.Text(value, style: valueStyle),
        ],
      ),
    );
  }
}
