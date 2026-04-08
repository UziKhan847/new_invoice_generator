import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:new_invoice_generator/models/invoice.dart';
import 'package:new_invoice_generator/models/monthly_bar.dart';
import 'package:new_invoice_generator/providers/customer.dart';
import 'package:new_invoice_generator/providers/employee.dart';
import 'package:new_invoice_generator/providers/home_analytics.dart';
import 'package:new_invoice_generator/providers/invoice.dart';
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
  String? _filterCustomerName;
  String? _filterSenderId;
  String? _filterSenderName;

  // ── Compute chart data from filtered invoices ──────────────────────────────
  _ChartData _buildChartData(List<Invoice> invoices) {
    // Apply filters
    var filtered = invoices.where((inv) {
      if (_filterYear != null && inv.issueDate.year != _filterYear) return false;
      if (_filterCustomerId != null && inv.customerId != _filterCustomerId) return false;
      if (_filterSenderId != null && inv.senderEmployeeId != _filterSenderId) return false;
      return true;
    }).toList();

    // Aggregate monthly revenue bars
    final Map<String, double> revenueByMonth = {};
    final Map<String, int> countByMonth = {};
    double paid = 0, unpaid = 0;
    double totalRevenue = 0;
    int totalCount = filtered.length;

    for (final inv in filtered) {
      final key =
          '${inv.issueDate.year}-${inv.issueDate.month.toString().padLeft(2, '0')}';
      final amount = inv.total;
      if (inv.isPaid) {
        revenueByMonth[key] = (revenueByMonth[key] ?? 0) + amount;
        paid += amount;
        totalRevenue += amount;
      } else {
        unpaid += amount;
      }
      countByMonth[key] = (countByMonth[key] ?? 0) + 1;
    }

    const monthNames = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];

    final sortedKeys = <dynamic>{...revenueByMonth.keys, ...countByMonth.keys}
        .toList()
      ..sort();

    final revenueBars = sortedKeys.map((k) {
      final parts = k.split('-');
      final monthIdx = int.parse(parts[1]) - 1;
      final year = parts[0];
      final label = _filterYear != null
          ? monthNames[monthIdx]
          : '${monthNames[monthIdx]} $year';
      return MonthlyBar(
        label: label,
        value: revenueByMonth[k] ?? 0,
        count: countByMonth[k] ?? 0,
      );
    }).toList();

    final countBars = sortedKeys.map((k) {
      final parts = k.split('-');
      final monthIdx = int.parse(parts[1]) - 1;
      final year = parts[0];
      final label = _filterYear != null
          ? monthNames[monthIdx]
          : '${monthNames[monthIdx]} $year';
      return MonthlyBar(
        label: label,
        value: (countByMonth[k] ?? 0).toDouble(),
        count: countByMonth[k] ?? 0,
      );
    }).toList();

    return _ChartData(
      revenueBars: revenueBars,
      countBars: countBars,
      paid: paid,
      unpaid: unpaid,
      totalRevenue: totalRevenue,
      totalCount: totalCount,
    );
  }

  @override
  Widget build(BuildContext context) {
    final invoicesAsync = ref.watch(invoiceProvider);
    final customersAsync = ref.watch(customerProvider);
    final employeesAsync = ref.watch(employeeProvider);
    // Still watch analytics for home-screen summary stats
    final _ = ref.watch(homeAnalyticsProvider);
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
                // Year
                Expanded(
                  child: DropdownButtonFormField<int>(
                    initialValue: _filterYear,
                    isDense: true,
                    decoration: const InputDecoration(
                        labelText: 'Year',
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10)),
                    items: [
                      const DropdownMenuItem(
                          value: null, child: Text('All years')),
                      ...List.generate(
                          5,
                          (i) => DropdownMenuItem(
                              value: now.year - i,
                              child: Text('${now.year - i}'))),
                    ],
                    onChanged: (v) => setState(() => _filterYear = v),
                  ),
                ),
                const SizedBox(width: 8),
                // Customer
                Expanded(
                  child: customersAsync.when(
                    loading: () => const SizedBox.shrink(),
                    error: (_, _) => const SizedBox.shrink(),
                    data: (customers) => DropdownButtonFormField<String>(
                      initialValue: _filterCustomerId,
                      isDense: true,
                      isExpanded: true,
                      decoration: const InputDecoration(
                          labelText: 'Customer',
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10)),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('All')),
                        ...customers.map((c) => DropdownMenuItem(
                            value: c.id,
                            child: Text(c.name,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1))),
                      ],
                      onChanged: (v) => setState(() {
                        _filterCustomerId = v;
                        _filterCustomerName = customers
                            .cast<dynamic>()
                            .firstWhere((c) => c.id == v,
                                orElse: () => null)
                            ?.name as String?;
                      }),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Sender
                Expanded(
                  child: employeesAsync.when(
                    loading: () => const SizedBox.shrink(),
                    error: (_, _) => const SizedBox.shrink(),
                    data: (employees) => employees.isEmpty
                        ? const SizedBox.shrink()
                        : DropdownButtonFormField<String>(
                            initialValue: _filterSenderId,
                            isDense: true,
                            isExpanded: true,
                            decoration: const InputDecoration(
                                labelText: 'Sender',
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10)),
                            items: [
                              const DropdownMenuItem(
                                  value: null, child: Text('All')),
                              ...employees.map((e) => DropdownMenuItem(
                                  value: e.id,
                                  child: Text(e.name,
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1))),
                            ],
                            onChanged: (v) => setState(() {
                              _filterSenderId = v;
                              _filterSenderName = employees
                                  .cast<dynamic>()
                                  .firstWhere((e) => e.id == v,
                                      orElse: () => null)
                                  ?.name as String?;
                            }),
                          ),
                  ),
                ),
              ],
            ),
          ),

          // Active filter chips
          if (_filterYear != null ||
              _filterCustomerId != null ||
              _filterSenderId != null)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Row(
                children: [
                  if (_filterYear != null)
                    _FilterChip(
                      label: '$_filterYear',
                      onRemove: () => setState(() => _filterYear = null),
                    ),
                  if (_filterCustomerName != null)
                    _FilterChip(
                      label: _filterCustomerName!,
                      onRemove: () => setState(() {
                        _filterCustomerId = null;
                        _filterCustomerName = null;
                      }),
                    ),
                  if (_filterSenderName != null)
                    _FilterChip(
                      label: _filterSenderName!,
                      onRemove: () => setState(() {
                        _filterSenderId = null;
                        _filterSenderName = null;
                      }),
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
              onSelectionChanged: (s) =>
                  setState(() => _chartIndex = s.first),
            ),
          ),
          const SizedBox(height: 12),

          // ── Chart ────────────────────────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: invoicesAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
                data: (invoices) {
                  final data = _buildChartData(invoices);

                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_chartTitle(_chartIndex),
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 2),
                          Text(_chartSubtitle(_chartIndex, data),
                              style: TextStyle(
                                  fontSize: 12,
                                  color: cs.onSurface.withAlpha(140))),
                          const SizedBox(height: 16),
                          Expanded(
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              child: KeyedSubtree(
                                key: ValueKey(_chartIndex),
                                child: _chartIndex == 0
                                    ? RevenueBarChart(
                                        bars: data.revenueBars)
                                    : _chartIndex == 1
                                        ? PaidUnpaidDonut(
                                            paid: data.paid,
                                            unpaid: data.unpaid)
                                        : CountLineChart(
                                            bars: data.countBars),
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
      case 0:  return 'Monthly Revenue';
      case 1:  return 'Paid vs Unpaid';
      default: return 'Invoice Count';
    }
  }

  String _chartSubtitle(int i, _ChartData data) {
    switch (i) {
      case 0:
        return 'Total paid: \$${data.totalRevenue.toStringAsFixed(2)}';
      case 1:
        final total = data.paid + data.unpaid;
        final pct = total == 0
            ? '0'
            : (data.paid / total * 100).toStringAsFixed(1);
        return '$pct% collected  ·  \$${data.unpaid.toStringAsFixed(2)} outstanding';
      default:
        return '${data.totalCount} invoice${data.totalCount == 1 ? '' : 's'}';
    }
  }
}

// ── Data class ────────────────────────────────────────────────────────────────
class _ChartData {
  final List<MonthlyBar> revenueBars;
  final List<MonthlyBar> countBars;
  final double paid;
  final double unpaid;
  final double totalRevenue;
  final int totalCount;

  _ChartData({
    required this.revenueBars,
    required this.countBars,
    required this.paid,
    required this.unpaid,
    required this.totalRevenue,
    required this.totalCount,
  });
}

// ── Filter chip ───────────────────────────────────────────────────────────────
class _FilterChip extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;
  const _FilterChip({required this.label, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Chip(
        label: Text(label, style: const TextStyle(fontSize: 12)),
        deleteIcon: const Icon(Icons.close, size: 14),
        onDeleted: onRemove,
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}