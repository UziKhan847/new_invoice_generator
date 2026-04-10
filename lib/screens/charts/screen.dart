import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:new_invoice_generator/providers/customer.dart';
import 'package:new_invoice_generator/providers/employee.dart';
import 'package:new_invoice_generator/providers/invoice.dart';
import 'package:new_invoice_generator/screens/charts/data.dart';
import 'package:new_invoice_generator/screens/charts/widgets/card.dart';
import 'package:new_invoice_generator/screens/charts/widgets/filter_chips.dart';

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

  @override
  Widget build(BuildContext context) {
    final invoicesAsync = ref.watch(invoiceProvider);
    final isLandscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      appBar: AppBar(title: const Text('Charts')),
      body: invoicesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (invoices) {
          final data = ChartData.fromInvoices(
            invoices: invoices,
            filterYear: _filterYear,
            filterCustomerId: _filterCustomerId,
            filterSenderId: _filterSenderId,
          );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Controls (always on top, compact in landscape) ───
              _ControlBar(
                chartIndex: _chartIndex,
                filterYear: _filterYear,
                filterCustomerId: _filterCustomerId,
                filterCustomerName: _filterCustomerName,
                filterSenderId: _filterSenderId,
                filterSenderName: _filterSenderName,
                compact: isLandscape,
                onChartChanged: (i) => setState(() => _chartIndex = i),
                onYearChanged: (v) => setState(() => _filterYear = v),
                onCustomerChanged: (id, name) => setState(() {
                  _filterCustomerId = id;
                  _filterCustomerName = name;
                }),
                onSenderChanged: (id, name) => setState(() {
                  _filterSenderId = id;
                  _filterSenderName = name;
                }),
                onRemoveYear: () => setState(() => _filterYear = null),
                onRemoveCustomer: () => setState(() {
                  _filterCustomerId = null;
                  _filterCustomerName = null;
                }),
                onRemoveSender: () => setState(() {
                  _filterSenderId = null;
                  _filterSenderName = null;
                }),
              ),

              // ── Chart fills all remaining space ──────────────────
              Expanded(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                      12, 4, 12, bottom + (isLandscape ? 8 : 12)),
                  child: ChartCard(
                    chartIndex: _chartIndex,
                    data: data,
                    labelSize: isLandscape ? 10 : 12,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── Combined control bar: filters + tab selector ──────────────────────────────
class _ControlBar extends ConsumerWidget {
  final int chartIndex;
  final int? filterYear;
  final String? filterCustomerId;
  final String? filterCustomerName;
  final String? filterSenderId;
  final String? filterSenderName;
  final bool compact; // true = landscape, lay everything in one Row
  final ValueChanged<int> onChartChanged;
  final ValueChanged<int?> onYearChanged;
  final void Function(String? id, String? name) onCustomerChanged;
  final void Function(String? id, String? name) onSenderChanged;
  final VoidCallback onRemoveYear;
  final VoidCallback onRemoveCustomer;
  final VoidCallback onRemoveSender;

  const _ControlBar({
    required this.chartIndex,
    required this.filterYear,
    required this.filterCustomerId,
    required this.filterCustomerName,
    required this.filterSenderId,
    required this.filterSenderName,
    required this.compact,
    required this.onChartChanged,
    required this.onYearChanged,
    required this.onCustomerChanged,
    required this.onSenderChanged,
    required this.onRemoveYear,
    required this.onRemoveCustomer,
    required this.onRemoveSender,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customersAsync = ref.watch(customerProvider);
    final employeesAsync = ref.watch(employeeProvider);
    final now = DateTime.now();
    final hasChip = filterYear != null ||
        filterCustomerName != null ||
        filterSenderName != null;

    final tabs = SegmentedButton<int>(
      segments: const [
        ButtonSegment(value: 0, label: Text('Revenue')),
        ButtonSegment(value: 1, label: Text('Paid/Unpaid')),
        ButtonSegment(value: 2, label: Text('Count')),
      ],
      selected: {chartIndex},
      onSelectionChanged: (s) => onChartChanged(s.first),
      style: SegmentedButton.styleFrom(
        textStyle: const TextStyle(fontSize: 12),
        minimumSize: const Size(0, 36),
      ),
    );

    if (compact) {
      // ── Landscape: one single row: [Year▾] [Customer▾] [Sender▾] │ [tabs]
      return Padding(
        padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
        child: Row(
          children: [
            // Year
            _SmallDropdown<int>(
              label: 'Year',
              value: filterYear,
              items: [
                const DropdownMenuItem(value: null, child: Text('All')),
                ...List.generate(5, (i) => DropdownMenuItem(
                    value: now.year - i, child: Text('${now.year - i}'))),
              ],
              onChanged: onYearChanged,
            ),
            const SizedBox(width: 6),
            // Customer
            customersAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
              data: (customers) => _SmallDropdown<String>(
                label: 'Customer',
                value: filterCustomerId,
                items: [
                  const DropdownMenuItem(value: null, child: Text('All')),
                  ...customers.map((c) => DropdownMenuItem(
                      value: c.id,
                      child: Text(c.name,
                          overflow: TextOverflow.ellipsis, maxLines: 1))),
                ],
                onChanged: (v) {
                  final name = v == null
                      ? null
                      : customers
                          .cast<dynamic>()
                          .firstWhere((c) => c.id == v, orElse: () => null)
                          ?.name as String?;
                  onCustomerChanged(v, name);
                },
              ),
            ),
            const SizedBox(width: 6),
            // Sender
            employeesAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
              data: (employees) => employees.isEmpty
                  ? const SizedBox.shrink()
                  : _SmallDropdown<String>(
                      label: 'Sender',
                      value: filterSenderId,
                      items: [
                        const DropdownMenuItem(value: null, child: Text('All')),
                        ...employees.map((e) => DropdownMenuItem(
                            value: e.id,
                            child: Text(e.name,
                                overflow: TextOverflow.ellipsis, maxLines: 1))),
                      ],
                      onChanged: (v) {
                        final name = v == null
                            ? null
                            : employees
                                .cast<dynamic>()
                                .firstWhere((e) => e.id == v,
                                    orElse: () => null)
                                ?.name as String?;
                        onSenderChanged(v, name);
                      },
                    ),
            ),
            const SizedBox(width: 10),
            const VerticalDivider(width: 1, indent: 4, endIndent: 4),
            const SizedBox(width: 10),
            // Tab selector on the right
            Expanded(child: tabs),
          ],
        ),
      );
    }

    // ── Portrait: filters row, optional chips, then tab selector ─────────────
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Filters
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: Row(
            children: [
              // Year
              Expanded(
                child: _PortraitDropdown<int>(
                  label: 'Year',
                  value: filterYear,
                  items: [
                    const DropdownMenuItem(
                        value: null, child: Text('All years')),
                    ...List.generate(5, (i) => DropdownMenuItem(
                        value: now.year - i,
                        child: Text('${now.year - i}'))),
                  ],
                  onChanged: onYearChanged,
                ),
              ),
              const SizedBox(width: 8),
              // Customer
              Expanded(
                child: customersAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, _) => const SizedBox.shrink(),
                  data: (customers) => _PortraitDropdown<String>(
                    label: 'Customer',
                    value: filterCustomerId,
                    items: [
                      const DropdownMenuItem(value: null, child: Text('All')),
                      ...customers.map((c) => DropdownMenuItem(
                          value: c.id,
                          child: Text(c.name,
                              overflow: TextOverflow.ellipsis, maxLines: 1))),
                    ],
                    onChanged: (v) {
                      final name = v == null
                          ? null
                          : customers
                              .cast<dynamic>()
                              .firstWhere((c) => c.id == v,
                                  orElse: () => null)
                              ?.name as String?;
                      onCustomerChanged(v, name);
                    },
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
                      : _PortraitDropdown<String>(
                          label: 'Sender',
                          value: filterSenderId,
                          items: [
                            const DropdownMenuItem(
                                value: null, child: Text('All')),
                            ...employees.map((e) => DropdownMenuItem(
                                value: e.id,
                                child: Text(e.name,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1))),
                          ],
                          onChanged: (v) {
                            final name = v == null
                                ? null
                                : employees
                                    .cast<dynamic>()
                                    .firstWhere((e) => e.id == v,
                                        orElse: () => null)
                                    ?.name as String?;
                            onSenderChanged(v, name);
                          },
                        ),
                ),
              ),
            ],
          ),
        ),

        // Chips
        if (hasChip)
          ChartFilterChips(
            filterYear: filterYear,
            filterCustomerName: filterCustomerName,
            filterSenderName: filterSenderName,
            onRemoveYear: onRemoveYear,
            onRemoveCustomer: onRemoveCustomer,
            onRemoveSender: onRemoveSender,
          ),

        const SizedBox(height: 8),

        // Tab selector
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: tabs,
        ),
        const SizedBox(height: 6),
      ],
    );
  }
}

// ── Shared dropdown widgets ────────────────────────────────────────────────────

// Compact dropdown for landscape (no label, just the value + arrow)
class _SmallDropdown<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  const _SmallDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 110),
      child: DropdownButtonFormField<T>(
        initialValue: value,
        isDense: true,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          border: const OutlineInputBorder(),
        ),
        items: items,
        onChanged: onChanged,
      ),
    );
  }
}

// Portrait dropdown with full InputDecoration
class _PortraitDropdown<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  const _PortraitDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      isDense: true,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      items: items,
      onChanged: onChanged,
    );
  }
}