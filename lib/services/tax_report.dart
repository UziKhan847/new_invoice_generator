import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:new_invoice_generator/models/expense.dart';
import 'package:new_invoice_generator/models/invoice.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class TaxReportService {
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
          // ── Header ─────────────────────────────────────────────────
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Tax Report — $year',
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  companyName,
                  style: pw.TextStyle(
                    color: PdfColors.white.shade(0.7),
                    fontSize: 12,
                  ),
                ),
                pw.Text(
                  'Generated: ${DateTime.now().toLocal().toString().split(' ')[0]}',
                  style: pw.TextStyle(
                    color: PdfColors.white.shade(0.7),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 20),

          // ── Summary cards ───────────────────────────────────────────
          pw.Row(
            children: [
              _summaryBox(
                'Total Revenue\n(pre-tax)',
                '\$${totalRevenue.toStringAsFixed(2)}',
                PdfColors.green700,
              ),
              pw.SizedBox(width: 8),
              _summaryBox(
                'HST/GST Collected',
                '\$${totalTaxCollected.toStringAsFixed(2)}',
                PdfColors.blue700,
              ),
              pw.SizedBox(width: 8),
              _summaryBox(
                'Total Expenses',
                '\$${totalExpenses.toStringAsFixed(2)}',
                PdfColors.orange700,
              ),
              pw.SizedBox(width: 8),
              _summaryBox(
                'Net Profit',
                '\$${netProfit.toStringAsFixed(2)}',
                netProfit >= 0 ? PdfColors.green700 : PdfColors.red700,
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            children: [
              _summaryBox(
                'Input Tax Credits',
                '\$${totalInputTax.toStringAsFixed(2)}',
                PdfColors.teal700,
              ),
              pw.SizedBox(width: 8),
              _summaryBox(
                'Net Tax Owing',
                '\$${netTaxOwing.toStringAsFixed(2)}',
                netTaxOwing >= 0 ? PdfColors.red700 : PdfColors.green700,
              ),
              pw.SizedBox(width: 8),
              pw.Expanded(child: pw.SizedBox()),
              pw.SizedBox(width: 8),
              pw.Expanded(child: pw.SizedBox()),
            ],
          ),
          pw.SizedBox(height: 24),

          // ── Monthly summary table ───────────────────────────────────
          pw.Text(
            'Monthly Summary',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300),
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
                ], highlight: net < 0);
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
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300),
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
                ...paidInvoices.map(
                  (inv) => _tableRow([
                    inv.issueDate.toLocal().toString().split(' ')[0],
                    inv.customerName,
                    '\$${inv.taxableSubtotal.toStringAsFixed(2)}',
                    '\$${inv.tax.toStringAsFixed(2)}',
                    '\$${inv.total.toStringAsFixed(2)}',
                  ]),
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
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300),
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
                ...yearExpenses.map(
                  (exp) => _tableRow([
                    exp.date.toLocal().toString().split(' ')[0],
                    exp.description,
                    exp.category,
                    exp.taxAmount > 0
                        ? '\$${exp.taxAmount.toStringAsFixed(2)}'
                        : '—',
                    '\$${exp.amount.toStringAsFixed(2)}',
                  ]),
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

  static pw.Widget _summaryBox(String label, String value, PdfColor color) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          color: color.shade(0.9),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
          border: pw.Border.all(color: color.shade(0.7)),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(label, style: pw.TextStyle(fontSize: 9, color: color)),
            pw.SizedBox(height: 4),
            pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 13,
                fontWeight: pw.FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static pw.TableRow _tableHeader(List<String> cells) {
    return pw.TableRow(
      decoration: const pw.BoxDecoration(color: PdfColors.blueGrey100),
      children: cells
          .map(
            (c) => pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text(
                c,
                style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  static pw.TableRow _tableRow(
    List<String> cells, {
    bool bold = false,
    bool highlight = false,
  }) {
    return pw.TableRow(
      decoration: highlight
          ? const pw.BoxDecoration(color: PdfColors.red50)
          : null,
      children: cells
          .map(
            (c) => pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text(
                c,
                style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}
