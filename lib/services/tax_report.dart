import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:new_invoice_generator/models/expense.dart';
import 'package:new_invoice_generator/models/invoice/invoice.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class TaxReportService {
  static const _navy = PdfColor.fromInt(0xFF172234);
  static const _indigo = PdfColor.fromInt(0xFF2C56B5);
  static const _ink = PdfColor.fromInt(0xFF172234);
  static const _muted = PdfColor.fromInt(0xFF5C6878);
  static const _greenText = PdfColor.fromInt(0xFF157A45);
  static const _greenBg = PdfColor.fromInt(0xFFE7F4EC);
  static const _indigoBg = PdfColor.fromInt(0xFFEEF3FC);
  static const _amberText = PdfColor.fromInt(0xFFA87A22);
  static const _amberBg = PdfColor.fromInt(0xFFFBF1DE);
  static const _redText = PdfColor.fromInt(0xFFC2453E);
  static const _redBg = PdfColor.fromInt(0xFFFBEAEA);
  static const _rowAlt = PdfColor.fromInt(0xFFF7F9FC);
  static const _totalBg = PdfColor.fromInt(0xFFEEF3FC);
  static const _hairline = PdfColor.fromInt(0xFFE5E9F0);

  static Future<void> generateAndShare({
    required BuildContext context,
    required List<Invoice> invoices,
    required List<Expense> expenses,
    required int year,
    required Map<String, dynamic> company,
  }) async {
    final bytes = await _buildPdf(
      invoices: invoices,
      expenses: expenses,
      year: year,
      company: company,
    );

    final fileName = 'tax_report_$year.pdf';

    // Share/save on all platforms
    await Printing.sharePdf(bytes: bytes, filename: fileName);
  }

  static Future<Uint8List> _buildPdf({
    required List<Invoice> invoices,
    required List<Expense> expenses,
    required int year,
    required Map<String, dynamic> company,
  }) async {
    final pdf = pw.Document();
    const monthNames = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    // ── Revenue data ──────────────────────────────────────────────────────
    final paidInvoices =
        invoices
            .where((i) => i.isPaid && !i.isPrivate && i.issueDate.year == year)
            .toList()
          ..sort((a, b) => a.issueDate.compareTo(b.issueDate));

    final totalRevenue = paidInvoices.fold(
      0.0,
      (s, i) => s + i.taxableSubtotal,
    );
    final totalTaxCollected = paidInvoices.fold(0.0, (s, i) => s + i.tax);
    final totalRevenueWithTax = paidInvoices.fold(0.0, (s, i) => s + i.total);

    // ── Expense data ──────────────────────────────────────────────────────
    final yearExpenses = expenses.where((e) => e.date.year == year).toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    final totalExpenses = yearExpenses.fold(0.0, (s, e) => s + e.amount);
    final totalInputTax = yearExpenses.fold(0.0, (s, e) => s + e.taxAmount);

    final netTaxOwing = totalTaxCollected - totalInputTax;
    final netProfit = totalRevenue - totalExpenses;

    // ── Build monthly breakdown ───────────────────────────────────────────
    final monthlyRevenue = List.filled(12, 0.0);
    final monthlyExpenses = List.filled(12, 0.0);
    for (final inv in paidInvoices) {
      monthlyRevenue[inv.issueDate.month - 1] += inv.total;
    }
    for (final exp in yearExpenses) {
      monthlyExpenses[exp.date.month - 1] += exp.amount;
    }

    final companyName = company['name'] as String? ?? 'My Company';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        build: (ctx) => [
          // ── Dark hero header ───────────────────────────────────────
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(
              horizontal: 22,
              vertical: 20,
            ),
            decoration: const pw.BoxDecoration(color: _navy),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.RichText(
                        text: pw.TextSpan(
                          children: [
                            pw.TextSpan(
                              text: 'Tax Report ',
                              style: pw.TextStyle(
                                color: PdfColors.white,
                                fontSize: 22,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                            pw.TextSpan(
                              text: '· $year',
                              style: pw.TextStyle(
                                color: PdfColor.fromInt(0xFF8B97AD),
                                fontSize: 22,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        '$companyName · Generated ${DateTime.now().toLocal().toString().split(' ')[0]}',
                        style: const pw.TextStyle(
                          color: PdfColor.fromInt(0xFF9AA4B6),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'NET TAX OWING',
                      style: pw.TextStyle(
                        color: const PdfColor.fromInt(0xFF9AA4B6),
                        fontSize: 9,
                        letterSpacing: 1,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 3),
                    pw.Text(
                      '\$${netTaxOwing.toStringAsFixed(2)}',
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 22,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 22),

          // ── Tinted 6-card grid ──────────────────────────────────────
          pw.Row(
            children: [
              _statCard(
                'Total Revenue (pre-tax)',
                '\$${totalRevenue.toStringAsFixed(2)}',
                _greenBg,
                _greenText,
              ),
              pw.SizedBox(width: 12),
              _statCard(
                'HST / GST Collected',
                '\$${totalTaxCollected.toStringAsFixed(2)}',
                _indigoBg,
                _indigo,
              ),
              pw.SizedBox(width: 12),
              _statCard(
                'Total Expenses',
                '\$${totalExpenses.toStringAsFixed(2)}',
                _amberBg,
                _amberText,
              ),
            ],
          ),
          pw.SizedBox(height: 12),
          pw.Row(
            children: [
              _statCard(
                'Input Tax Credits',
                '\$${totalInputTax.toStringAsFixed(2)}',
                _indigoBg,
                _greenText,
              ),
              pw.SizedBox(width: 12),
              _statCard(
                'Net Tax Owing',
                '\$${netTaxOwing.toStringAsFixed(2)}',
                netTaxOwing >= 0 ? _redBg : _greenBg,
                netTaxOwing >= 0 ? _redText : _greenText,
              ),
              pw.SizedBox(width: 12),
              _statCard(
                'Net Profit',
                '\$${netProfit.toStringAsFixed(2)}',
                _greenBg,
                netProfit >= 0 ? _greenText : _redText,
              ),
            ],
          ),
          pw.SizedBox(height: 26),

          // ── Monthly summary table ───────────────────────────────────
          pw.Text(
            'Monthly Summary',
            style: pw.TextStyle(
              fontSize: 15,
              fontWeight: pw.FontWeight.bold,
              color: _ink,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Table(
            columnWidths: {
              0: const pw.FlexColumnWidth(2),
              1: const pw.FlexColumnWidth(2),
              2: const pw.FlexColumnWidth(2),
              3: const pw.FlexColumnWidth(2),
            },
            children: [
              _tableHeader(['Month', 'Revenue', 'Expenses', 'Net']),
              ...List.generate(12, (i) {
                final net = monthlyRevenue[i] - monthlyExpenses[i];
                return _tableRow([
                  monthNames[i],
                  monthlyRevenue[i] > 0
                      ? '\$${monthlyRevenue[i].toStringAsFixed(2)}'
                      : '—',
                  monthlyExpenses[i] > 0
                      ? '\$${monthlyExpenses[i].toStringAsFixed(2)}'
                      : '—',
                  net != 0 ? '\$${net.toStringAsFixed(2)}' : '—',
                ], alt: i.isOdd);
              }),
              _tableRow([
                'TOTAL',
                '\$${totalRevenueWithTax.toStringAsFixed(2)}',
                '\$${totalExpenses.toStringAsFixed(2)}',
                '\$${(totalRevenueWithTax - totalExpenses).toStringAsFixed(2)}',
              ], bold: true),
            ],
          ),
          pw.SizedBox(height: 24),

          // ── Paid invoices ────────────────────────────────────────────
          if (paidInvoices.isNotEmpty) ...[
            pw.Text(
              'Paid Invoices ($year)',
              style: pw.TextStyle(
                fontSize: 15,
                fontWeight: pw.FontWeight.bold,
                color: _ink,
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Table(
              columnWidths: {
                0: const pw.FlexColumnWidth(1),
                1: const pw.FlexColumnWidth(3),
                2: const pw.FlexColumnWidth(2),
                3: const pw.FlexColumnWidth(2),
                4: const pw.FlexColumnWidth(2),
              },
              children: [
                _tableHeader([
                  'Date',
                  'Customer',
                  'Pre-tax',
                  'Tax (13%)',
                  'Total',
                ]),
                ...paidInvoices.asMap().entries.map(
                  (e) => _tableRow([
                    e.value.issueDate.toLocal().toString().split(' ')[0],
                    e.value.customerName,
                    '\$${e.value.taxableSubtotal.toStringAsFixed(2)}',
                    '\$${e.value.tax.toStringAsFixed(2)}',
                    '\$${e.value.total.toStringAsFixed(2)}',
                  ], alt: e.key.isOdd),
                ),
                _tableRow([
                  '',
                  'TOTAL',
                  '\$${totalRevenue.toStringAsFixed(2)}',
                  '\$${totalTaxCollected.toStringAsFixed(2)}',
                  '\$${totalRevenueWithTax.toStringAsFixed(2)}',
                ], bold: true),
              ],
            ),
            pw.SizedBox(height: 24),
          ],

          // ── Expenses ─────────────────────────────────────────────────
          if (yearExpenses.isNotEmpty) ...[
            pw.Text(
              'Expenses ($year)',
              style: pw.TextStyle(
                fontSize: 15,
                fontWeight: pw.FontWeight.bold,
                color: _ink,
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Table(
              columnWidths: {
                0: const pw.FlexColumnWidth(1),
                1: const pw.FlexColumnWidth(3),
                2: const pw.FlexColumnWidth(2),
                3: const pw.FlexColumnWidth(2),
                4: const pw.FlexColumnWidth(2),
              },
              children: [
                _tableHeader([
                  'Date',
                  'Description',
                  'Category',
                  'Tax Paid',
                  'Amount',
                ]),
                ...yearExpenses.asMap().entries.map(
                  (e) => _tableRow([
                    e.value.date.toLocal().toString().split(' ')[0],
                    e.value.description,
                    e.value.category,
                    e.value.taxAmount > 0
                        ? '\$${e.value.taxAmount.toStringAsFixed(2)}'
                        : '—',
                    '\$${e.value.amount.toStringAsFixed(2)}',
                  ], alt: e.key.isOdd),
                ),
                _tableRow([
                  '',
                  '',
                  'TOTAL',
                  '\$${totalInputTax.toStringAsFixed(2)}',
                  '\$${totalExpenses.toStringAsFixed(2)}',
                ], bold: true),
              ],
            ),
          ],
        ],
      ),
    );

    return pdf.save();
  }

  static pw.Widget _statCard(
    String label,
    String value,
    PdfColor bg,
    PdfColor fg,
  ) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(14),
        decoration: pw.BoxDecoration(
          color: bg,
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              label,
              style: const pw.TextStyle(fontSize: 9, color: _muted),
            ),
            pw.SizedBox(height: 8),
            pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
                color: fg,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static pw.TableRow _tableHeader(List<String> cells) {
    return pw.TableRow(
      decoration: const pw.BoxDecoration(color: _rowAlt),
      children: List.generate(cells.length, (i) {
        final right = i != 0;
        return pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 7),
          child: pw.Text(
            cells[i].toUpperCase(),
            textAlign: right ? pw.TextAlign.right : pw.TextAlign.left,
            style: pw.TextStyle(
              fontSize: 8,
              letterSpacing: 0.5,
              color: _muted,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        );
      }),
    );
  }

  static pw.TableRow _tableRow(
    List<String> cells, {
    bool bold = false,
    bool alt = false,
  }) {
    final bg = bold ? _totalBg : (alt ? _rowAlt : PdfColors.white);
    return pw.TableRow(
      decoration: pw.BoxDecoration(
        color: bg,
        border: const pw.Border(
          bottom: pw.BorderSide(color: _hairline, width: 0.5),
        ),
      ),
      children: List.generate(cells.length, (i) {
        final right = i != 0;
        return pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: pw.Text(
            cells[i],
            textAlign: right ? pw.TextAlign.right : pw.TextAlign.left,
            style: pw.TextStyle(
              fontSize: 9,
              color: _ink,
              fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        );
      }),
    );
  }
}
