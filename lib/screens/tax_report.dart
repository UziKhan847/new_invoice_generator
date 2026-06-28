import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:new_invoice_generator/app_theme.dart';
import 'package:new_invoice_generator/providers/company.dart';
import 'package:new_invoice_generator/providers/expense.dart';
import 'package:new_invoice_generator/providers/invoice/invoice.dart';
import 'package:new_invoice_generator/screens/home/widgets/ui_kit.dart';
import 'package:new_invoice_generator/services/tax_report.dart';
import 'package:new_invoice_generator/utils/loading_overlay.dart';

class TaxReportScreen extends ConsumerStatefulWidget {
  const TaxReportScreen({super.key});

  @override
  ConsumerState<TaxReportScreen> createState() => _TaxReportScreenState();
}

class _TaxReportScreenState extends ConsumerState<TaxReportScreen> {
  int _year = DateTime.now().year;

  @override
  Widget build(BuildContext context) {
    final invoicesAsync = ref.watch(invoiceProvider);
    final expensesAsync = ref.watch(expenseProvider);
    final p = AppColors.of(context);
    final now = DateTime.now();

    return Scaffold(
      appBar: AppBar(title: const Text('Tax Report')),
      body: invoicesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (invoices) => expensesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (expenses) {
            final yearInvoices = invoices
                .where(
                  (i) => i.isPaid && !i.isPrivate && i.issueDate.year == _year,
                )
                .toList();
            final yearExpenses = expenses
                .where((e) => e.date.year == _year)
                .toList();

            final totalRevenue = yearInvoices.fold(
              0.0,
              (s, i) => s + i.taxableSubtotal,
            );
            final taxCollected = yearInvoices.fold(0.0, (s, i) => s + i.tax);
            final totalExpenses = yearExpenses.fold(
              0.0,
              (s, e) => s + e.amount,
            );
            final inputTax = yearExpenses.fold(0.0, (s, e) => s + e.taxAmount);
            final netTax = taxCollected - inputTax;
            final netProfit = totalRevenue - totalExpenses;

            return ListView(
              padding: EdgeInsets.fromLTRB(
                16,
                8,
                16,
                MediaQuery.paddingOf(context).bottom + 24,
              ),
              children: [
                // Year selector
                AppCard(
                  padding: const EdgeInsets.symmetric(
                    vertical: 6,
                    horizontal: 8,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _RoundIconBtn(
                        icon: Icons.chevron_left,
                        onTap: () => setState(() => _year--),
                      ),
                      Text(
                        '$_year',
                        style: AppTypography.display(
                          p.ink,
                        ).copyWith(fontSize: 22),
                      ),
                      _RoundIconBtn(
                        icon: Icons.chevron_right,
                        onTap: _year >= now.year
                            ? null
                            : () => setState(() => _year++),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Net tax owing hero
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const AppLabel('NET TAX OWING'),
                          AppPill(
                            label: netTax >= 0 ? 'Owing' : 'Refund',
                            bg: netTax >= 0 ? p.dangerBg : p.successBg,
                            border: netTax >= 0
                                ? p.dangerBorder
                                : p.successBorder,
                            text: netTax >= 0 ? p.dangerText : p.successText,
                            dot: Icons.circle,
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '\$${netTax.abs().toStringAsFixed(2)}',
                        style: AppTypography.amount(
                          netTax >= 0 ? p.dangerText : p.successText,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'HST/GST collected − input tax credits',
                        style: AppTypography.bodyMuted(p.textSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // 2x2 tinted stat grid
                Row(
                  children: [
                    Expanded(
                      child: _TaxStat(
                        label: 'Revenue (pre-tax)',
                        value: '\$${totalRevenue.toStringAsFixed(2)}',
                        icon: Icons.trending_up,
                        tint: p.successBg,
                        fg: p.successText,
                        p: p,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _TaxStat(
                        label: 'HST/GST collected',
                        value: '\$${taxCollected.toStringAsFixed(2)}',
                        icon: Icons.account_balance_outlined,
                        tint: p.primaryTint,
                        fg: p.primary,
                        p: p,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _TaxStat(
                        label: 'Total expenses',
                        value: '\$${totalExpenses.toStringAsFixed(2)}',
                        icon: Icons.trending_down,
                        tint: p.warningBg,
                        fg: p.warningText,
                        p: p,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _TaxStat(
                        label: 'Input tax credits',
                        value: '\$${inputTax.toStringAsFixed(2)}',
                        icon: Icons.receipt_outlined,
                        tint: p.successBg,
                        fg: p.successText,
                        p: p,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Net profit banner
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: netProfit >= 0 ? p.successText : p.dangerText,
                    borderRadius: BorderRadius.circular(AppRadii.card),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(50),
                          borderRadius: BorderRadius.circular(AppRadii.tile),
                        ),
                        child: const Icon(
                          Icons.account_balance_wallet_outlined,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'NET PROFIT',
                            style: AppTypography.label(
                              Colors.white.withAlpha(210),
                            ),
                          ),
                          Text(
                            '\$${netProfit.toStringAsFixed(2)}',
                            style: AppTypography.amount(
                              Colors.white,
                            ).copyWith(fontSize: 26),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Info rows
                AppCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      _InfoRow(
                        label: 'Paid invoices in $_year',
                        value: '${yearInvoices.length}',
                      ),
                      Divider(height: 1, color: p.border),
                      _InfoRow(
                        label: 'Expenses logged in $_year',
                        value: '${yearExpenses.length}',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Export button
                FilledButton.icon(
                  icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                  label: const Text('Export Full Tax Report PDF'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                  ),
                  onPressed: (yearInvoices.isEmpty && yearExpenses.isEmpty)
                      ? null
                      : () async {
                          final company = await ref.read(
                            companyProvider.future,
                          );
                          if (!context.mounted) return;
                          await withLoadingOverlay(
                            context,
                            message: 'Generating tax report…',
                            task: () => TaxReportService.generateAndShare(
                              context: context,
                              invoices: yearInvoices,
                              expenses: yearExpenses,
                              year: _year,
                              company: company,
                            ),
                          );
                        },
                ),
                if (yearInvoices.isEmpty && yearExpenses.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'No data for $_year. Add paid invoices or expenses first.',
                      textAlign: TextAlign.center,
                      style: AppTypography.caption(p.textTertiary),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _RoundIconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _RoundIconBtn({required this.icon, this.onTap});
  @override
  Widget build(BuildContext context) {
    final p = AppColors.of(context);
    final enabled = onTap != null;
    return Material(
      color: p.surfaceAlt,
      borderRadius: BorderRadius.circular(AppRadii.button),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.button),
        child: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.button),
            border: Border.all(color: p.cardBorder),
          ),
          child: Icon(
            icon,
            color: enabled ? p.ink : p.textTertiary.withAlpha(120),
          ),
        ),
      ),
    );
  }
}

class _TaxStat extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color tint, fg;
  final AppPalette p;
  const _TaxStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.tint,
    required this.fg,
    required this.p,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: fg.withAlpha(40)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: p.surface.withAlpha(150),
              borderRadius: BorderRadius.circular(AppRadii.tile),
            ),
            child: Icon(icon, color: fg, size: 17),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.amount(p.ink).copyWith(fontSize: 21),
          ),
          const SizedBox(height: 2),
          Text(label, style: AppTypography.caption(p.textSecondary)),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label, value;
  const _InfoRow({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    final p = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTypography.body(p.ink)),
          Text(value, style: AppTypography.title(p.ink).copyWith(fontSize: 16)),
        ],
      ),
    );
  }
}
