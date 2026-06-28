import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:new_invoice_generator/app_theme.dart';
import 'package:new_invoice_generator/providers/company.dart';
import 'package:new_invoice_generator/providers/expense.dart';
import 'package:new_invoice_generator/providers/invoice.dart';
import 'package:new_invoice_generator/screens/desktop/widgets.dart';
import 'package:new_invoice_generator/services/tax_report.dart';
import 'package:new_invoice_generator/utils/loading_overlay.dart';

class DesktopTaxReport extends ConsumerStatefulWidget {
  const DesktopTaxReport({super.key});

  @override
  ConsumerState<DesktopTaxReport> createState() => _DesktopTaxReportState();
}

class _DesktopTaxReportState extends ConsumerState<DesktopTaxReport> {
  int _year = DateTime.now().year;

  static const _months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  @override
  Widget build(BuildContext context) {
    final p = AppColors.of(context);
    final invoicesAsync = ref.watch(invoiceProvider);
    final expensesAsync = ref.watch(expenseProvider);
    final now = DateTime.now();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DesktopTopBar(
          title: 'Tax Report',
          subtitle: 'HST/GST · fiscal year',
          actions: [
            // Year stepper
            Container(
              decoration: BoxDecoration(
                color: p.surface,
                borderRadius: BorderRadius.circular(AppRadii.button),
                border: Border.all(color: p.cardBorder),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left, size: 20),
                    onPressed: () => setState(() => _year--),
                  ),
                  Text(
                    '$_year',
                    style: AppTypography.title(p.ink).copyWith(fontSize: 15),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right, size: 20),
                    onPressed: _year >= now.year
                        ? null
                        : () => setState(() => _year++),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Consumer(
              builder: (context, ref, _) {
                return FilledButton.icon(
                  onPressed: () async {
                    final invoices =
                        ref.read(invoiceProvider).asData?.value ?? [];
                    final expenses =
                        ref.read(expenseProvider).asData?.value ?? [];
                    final yearInv = invoices
                        .where(
                          (i) =>
                              i.isPaid &&
                              !i.isPrivate &&
                              i.issueDate.year == _year,
                        )
                        .toList();
                    final yearExp = expenses
                        .where((e) => e.date.year == _year)
                        .toList();
                    if (yearInv.isEmpty && yearExp.isEmpty) return;
                    final company = await ref.read(companyProvider.future);
                    if (!context.mounted) return;
                    await withLoadingOverlay(
                      context,
                      message: 'Generating tax report…',
                      task: () => TaxReportService.generateAndShare(
                        context: context,
                        invoices: yearInv,
                        expenses: yearExp,
                        year: _year,
                        company: company,
                      ),
                    );
                  },
                  icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                  label: const Text('Export PDF'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 13,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        Expanded(
          child: invoicesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (invoices) {
              final expenses = expensesAsync.asData?.value ?? [];
              final yearInv = invoices
                  .where(
                    (i) =>
                        i.isPaid && !i.isPrivate && i.issueDate.year == _year,
                  )
                  .toList();
              final yearExp = expenses
                  .where((e) => e.date.year == _year)
                  .toList();

              final totalRevenue = yearInv.fold<double>(
                0,
                (s, i) => s + i.taxableSubtotal,
              );
              final taxCollected = yearInv.fold<double>(0, (s, i) => s + i.tax);
              final totalExpenses = yearExp.fold<double>(
                0,
                (s, e) => s + e.amount,
              );
              final inputTax = yearExp.fold<double>(
                0,
                (s, e) => s + e.taxAmount,
              );
              final netTax = taxCollected - inputTax;
              final netProfit = totalRevenue - totalExpenses;

              // Monthly aggregates
              final monthlyRev = List<double>.filled(12, 0);
              final monthlyExp = List<double>.filled(12, 0);
              for (final i in yearInv) {
                monthlyRev[i.issueDate.month - 1] += i.taxableSubtotal;
              }
              for (final e in yearExp) {
                monthlyExp[e.date.month - 1] += e.amount;
              }

              return ListView(
                padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
                children: [
                  // Heroes: net owing + net profit
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: DesktopPanel(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'NET TAX OWING',
                                      style: AppTypography.label(
                                        p.textTertiary,
                                      ),
                                    ),
                                    _pill(
                                      context,
                                      netTax >= 0 ? 'Owing' : 'Refund',
                                      netTax >= 0
                                          ? p.dangerText
                                          : p.successText,
                                      netTax >= 0 ? p.dangerBg : p.successBg,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '\$${netTax.abs().toStringAsFixed(2)}',
                                  style: AppTypography.amount(
                                    netTax >= 0 ? p.dangerText : p.successText,
                                  ).copyWith(fontSize: 34),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'HST/GST collected − input tax credits',
                                  style: AppTypography.bodyMuted(
                                    p.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: netProfit >= 0
                                  ? p.successText
                                  : p.dangerText,
                              borderRadius: BorderRadius.circular(
                                AppRadii.card,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'NET PROFIT',
                                  style: AppTypography.label(
                                    Colors.white.withAlpha(210),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '\$${netProfit.toStringAsFixed(2)}',
                                  style: AppTypography.amount(
                                    Colors.white,
                                  ).copyWith(fontSize: 34),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Revenue − expenses, after tax',
                                  style: AppTypography.bodyMuted(
                                    Colors.white.withAlpha(210),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 4-card stat strip
                  Row(
                    children: [
                      Expanded(
                        child: _stat(
                          context,
                          'Revenue (pre-tax)',
                          totalRevenue,
                          p.successText,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _stat(
                          context,
                          'HST / GST collected',
                          taxCollected,
                          p.primary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _stat(
                          context,
                          'Total expenses',
                          totalExpenses,
                          p.warningText,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _stat(
                          context,
                          'Input tax credits',
                          inputTax,
                          p.successText,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Monthly summary table
                  DesktopPanel(
                    padding: EdgeInsets.zero,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
                          child: Text(
                            'Monthly Summary',
                            style: AppTypography.title(
                              p.ink,
                            ).copyWith(fontSize: 16),
                          ),
                        ),
                        // header
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          color: p.surfaceAlt,
                          child: Row(
                            children: [
                              Expanded(flex: 3, child: _h(context, 'MONTH')),
                              Expanded(
                                flex: 2,
                                child: _h(context, 'REVENUE', right: true),
                              ),
                              Expanded(
                                flex: 2,
                                child: _h(context, 'EXPENSES', right: true),
                              ),
                              Expanded(
                                flex: 2,
                                child: _h(context, 'NET', right: true),
                              ),
                            ],
                          ),
                        ),
                        ...List.generate(12, (m) {
                          final rev = monthlyRev[m];
                          final exp = monthlyExp[m];
                          final net = rev - exp;
                          return _row(
                            context,
                            month: _months[m],
                            rev: rev,
                            exp: exp,
                            net: net,
                            alt: m.isOdd,
                          );
                        }),
                        // total
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: p.primaryTint,
                            borderRadius: const BorderRadius.vertical(
                              bottom: Radius.circular(AppRadii.card),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Text(
                                  'Total',
                                  style: AppTypography.title(
                                    p.ink,
                                  ).copyWith(fontSize: 14),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: _money(
                                  context,
                                  totalRevenue,
                                  bold: true,
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: _money(
                                  context,
                                  totalExpenses,
                                  bold: true,
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: _money(
                                  context,
                                  totalRevenue - totalExpenses,
                                  bold: true,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _pill(BuildContext c, String label, Color fg, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 7, color: fg),
          const SizedBox(width: 5),
          Text(label, style: AppTypography.caption(fg).copyWith(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _stat(BuildContext c, String label, double value, Color fg) {
    final p = AppColors.of(c);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: p.cardBorder),
        boxShadow: p.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTypography.bodyMuted(p.textSecondary)),
          const SizedBox(height: 8),
          Text(
            '\$${value.toStringAsFixed(2)}',
            style: AppTypography.amount(fg).copyWith(fontSize: 22),
          ),
        ],
      ),
    );
  }

  Widget _h(BuildContext c, String t, {bool right = false}) {
    final p = AppColors.of(c);
    return Text(
      t,
      textAlign: right ? TextAlign.right : TextAlign.left,
      style: AppTypography.label(p.textTertiary),
    );
  }

  Widget _row(
    BuildContext c, {
    required String month,
    required double rev,
    required double exp,
    required double net,
    required bool alt,
  }) {
    final p = AppColors.of(c);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
      decoration: BoxDecoration(
        color: alt ? p.surfaceAlt : p.surface,
        border: Border(bottom: BorderSide(color: p.border, width: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              '$month $_year',
              style: AppTypography.body(p.ink).copyWith(fontSize: 13),
            ),
          ),
          Expanded(flex: 2, child: _money(c, rev)),
          Expanded(flex: 2, child: _money(c, exp)),
          Expanded(flex: 2, child: _money(c, net)),
        ],
      ),
    );
  }

  Widget _money(BuildContext c, double v, {bool bold = false}) {
    final p = AppColors.of(c);
    return Text(
      v == 0 ? '—' : '\$${v.toStringAsFixed(2)}',
      textAlign: TextAlign.right,
      style: bold
          ? AppTypography.title(p.ink).copyWith(fontSize: 14)
          : AppTypography.body(
              v == 0 ? p.textTertiary : p.ink,
            ).copyWith(fontSize: 13),
    );
  }
}
