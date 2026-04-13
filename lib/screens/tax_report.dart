import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:new_invoice_generator/providers/company.dart';
import 'package:new_invoice_generator/providers/expense.dart';
import 'package:new_invoice_generator/providers/invoice.dart';
import 'package:new_invoice_generator/services/tax_report.dart';
import 'package:new_invoice_generator/utils/with_loading_overlay.dart';

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
    final cs = Theme.of(context).colorScheme;
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
                .where((i) => i.isPaid && i.issueDate.year == _year)
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
                16,
                16,
                MediaQuery.paddingOf(context).bottom + 24,
              ),
              children: [
                // Year selector
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left),
                          onPressed: () => setState(() => _year--),
                        ),
                        const SizedBox(width: 24),
                        Text(
                          '$_year',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 24),
                        IconButton(
                          icon: const Icon(Icons.chevron_right),
                          onPressed: _year >= now.year
                              ? null
                              : () => setState(() => _year++),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Summary cards
                _SummaryGrid(
                  children: [
                    _SummaryCard(
                      label: 'Revenue (pre-tax)',
                      value: '\$${totalRevenue.toStringAsFixed(2)}',
                      icon: Icons.trending_up,
                      color: Colors.green,
                    ),
                    _SummaryCard(
                      label: 'HST/GST Collected',
                      value: '\$${taxCollected.toStringAsFixed(2)}',
                      icon: Icons.account_balance_outlined,
                      color: Colors.blue,
                    ),
                    _SummaryCard(
                      label: 'Total Expenses',
                      value: '\$${totalExpenses.toStringAsFixed(2)}',
                      icon: Icons.trending_down,
                      color: Colors.orange,
                    ),
                    _SummaryCard(
                      label: 'Input Tax Credits',
                      value: '\$${inputTax.toStringAsFixed(2)}',
                      icon: Icons.receipt_outlined,
                      color: Colors.teal,
                    ),
                    _SummaryCard(
                      label: 'Net Tax Owing',
                      value: '\$${netTax.toStringAsFixed(2)}',
                      icon: Icons.calculate_outlined,
                      color: netTax >= 0 ? Colors.red : Colors.green,
                      subtitle: netTax < 0 ? 'You may have a refund' : null,
                    ),
                    _SummaryCard(
                      label: 'Net Profit',
                      value: '\$${netProfit.toStringAsFixed(2)}',
                      icon: Icons.savings_outlined,
                      color: netProfit >= 0 ? Colors.green : Colors.red,
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Invoice count
                _InfoRow(
                  label: 'Paid invoices in $_year',
                  value: '${yearInvoices.length}',
                ),
                _InfoRow(
                  label: 'Expenses logged in $_year',
                  value: '${yearExpenses.length}',
                ),
                const SizedBox(height: 24),

                // Export button
                ElevatedButton.icon(
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  label: const Text('Export Full Tax Report PDF'),
                  style: ElevatedButton.styleFrom(
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
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurface.withAlpha(120),
                      ),
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

class _SummaryGrid extends StatelessWidget {
  final List<Widget> children;
  const _SummaryGrid({required this.children});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 2.2,
      children: children,
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String? subtitle;
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withAlpha(18),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(50)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 10, color: color.withAlpha(200)),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: color,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: TextStyle(fontSize: 9, color: color.withAlpha(180)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withAlpha(160),
            ),
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
