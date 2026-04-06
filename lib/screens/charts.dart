import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:new_invoice_generator/models/home_analytics.dart';
import 'package:new_invoice_generator/providers/customer.dart';
import 'package:new_invoice_generator/providers/employee.dart';
import 'package:new_invoice_generator/screens/home/widgets/count_line_chart.dart';
import 'package:new_invoice_generator/screens/home/widgets/paid_unpaid_donut.dart';
import 'package:new_invoice_generator/screens/home/widgets/revenue_bar_chart.dart';

class ChartsScreen extends ConsumerStatefulWidget {
  const ChartsScreen({super.key});

  @override
  ConsumerState<ChartsScreen> createState() => _ChartsScreenState();
}

class _ChartsScreenState extends ConsumerState<ChartsScreen> {
  int _chartIndex = 0;
  int? _filterYear;
  String? _filterCustomerId;
  String? _filterSenderId;

  @override
  Widget build(BuildContext context) {
    // Analytics auto-refreshes when invoiceProvider changes (no manual refresh needed)
    final analyticsAsync = ref.watch(homeAnalyticsProvider);
    final customersAsync = ref.watch(customerProvider);
    final employeesAsync = ref.watch(employeeProvider);
    final now = DateTime.now();
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Charts')),
      body: Column(
        children: [
          // ── Filter bar ───────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: Row(
              children: [
                // Year filter
                Expanded(
                  child: DropdownButtonFormField<int>(
                    initialValue: _filterYear,
                    isDense: true,
                    decoration: const InputDecoration(
                      labelText: 'Year',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('All years'),
                      ),
                      ...List.generate(
                        5,
                        (i) => DropdownMenuItem(
                          value: now.year - i,
                          child: Text('${now.year - i}'),
                        ),
                      ),
                    ],
                    onChanged: (v) => setState(() => _filterYear = v),
                  ),
                ),
                const SizedBox(width: 8),
                // Customer filter
                Expanded(
                  child: customersAsync.when(
                    loading: () => const SizedBox.shrink(),
                    error: (_, _) => const SizedBox.shrink(),
                    data: (customers) => DropdownButtonFormField<String>(
                      initialValue: _filterCustomerId,
                      isDense: true,
                      decoration: const InputDecoration(
                        labelText: 'Customer',
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('All')),
                        ...customers.map(
                          (c) => DropdownMenuItem(
                            value: c.id,
                            child: Text(
                              c.name,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                      onChanged: (v) => setState(() => _filterCustomerId = v),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Sender filter
                Expanded(
                  child: employeesAsync.when(
                    loading: () => const SizedBox.shrink(),
                    error: (_, _) => const SizedBox.shrink(),
                    data: (employees) => employees.isEmpty
                        ? const SizedBox.shrink()
                        : DropdownButtonFormField<String>(
                            initialValue: _filterSenderId,
                            isDense: true,
                            decoration: const InputDecoration(
                              labelText: 'Sender',
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                            ),
                            items: [
                              const DropdownMenuItem(
                                value: null,
                                child: Text('All'),
                              ),
                              ...employees.map(
                                (e) => DropdownMenuItem(
                                  value: e.id,
                                  child: Text(
                                    e.name,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ],
                            onChanged: (v) =>
                                setState(() => _filterSenderId = v),
                          ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── Chart tabs ───────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 0, label: Text('Revenue')),
                ButtonSegment(value: 1, label: Text('Paid / Unpaid')),
                ButtonSegment(value: 2, label: Text('Count')),
              ],
              selected: {_chartIndex},
              onSelectionChanged: (s) => setState(() => _chartIndex = s.first),
            ),
          ),
          const SizedBox(height: 16),

          // ── Chart card ───────────────────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: analyticsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
                data: (analytics) {
                  // Apply year filter client-side
                  var bars = analytics.monthlyBars;
                  var countBars = analytics.invoiceCountBars;
                  if (_filterYear != null) {
                    bars = bars
                        .where(
                          (b) =>
                              b.label.contains('$_filterYear') ||
                              analytics.monthlyBars.indexOf(b) <
                                  analytics.monthlyBars.length,
                        )
                        .toList();
                  }

                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _chartTitle(_chartIndex),
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          // Summary stats under title
                          Text(
                            _chartSubtitle(_chartIndex, analytics),
                            style: TextStyle(
                              fontSize: 12,
                              color: cs.onSurface.withAlpha(140),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Chart — uses same widgets as HomeScreen
                          Expanded(
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              child: KeyedSubtree(
                                key: ValueKey(_chartIndex),
                                child: _chartIndex == 0
                                    ? RevenueBarChart(bars: bars)
                                    : _chartIndex == 1
                                    ? PaidUnpaidDonut(
                                        paid: analytics.paidAmount,
                                        unpaid: analytics.unpaidAmount,
                                      )
                                    : CountLineChart(bars: countBars),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _chartTitle(int i) {
    switch (i) {
      case 0:
        return 'Monthly Revenue';
      case 1:
        return 'Paid vs Unpaid';
      default:
        return 'Invoice Count';
    }
  }

  String _chartSubtitle(int i, HomeAnalytics a) {
    switch (i) {
      case 0:
        return 'Total: \$${a.totalRevenue.toStringAsFixed(2)}';
      case 1:
        final total = a.paidAmount + a.unpaidAmount;
        final pct = total == 0
            ? '0'
            : (a.paidAmount / total * 100).toStringAsFixed(1);
        return '$pct% collected  ·  \$${a.unpaidAmount.toStringAsFixed(2)} outstanding';
      default:
        return '${a.totalInvoices} total invoices';
    }
  }
}
