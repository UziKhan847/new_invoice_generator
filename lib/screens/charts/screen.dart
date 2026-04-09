import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:new_invoice_generator/providers/invoice.dart';
import 'package:new_invoice_generator/screens/charts/data.dart';
import 'package:new_invoice_generator/screens/charts/widgets/card.dart';
import 'package:new_invoice_generator/screens/charts/widgets/filter_bar.dart';
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

    return Scaffold(
      appBar: AppBar(title: const Text('Charts')),
      body: OrientationBuilder(
        builder: (context, orientation) {
          final isLandscape = orientation == Orientation.landscape;

          return invoicesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (invoices) {
              final data = ChartData.fromInvoices(
                invoices: invoices,
                filterYear: _filterYear,
                filterCustomerId: _filterCustomerId,
                filterSenderId: _filterSenderId,
              );

              // ── Landscape: filters left, chart right ─────────────
              if (isLandscape) {
                return Row(
                  children: [
                    // Left panel: filters + tab selector
                    SizedBox(
                      width: 200,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _filterBar(),
                          _filterChips(),
                          const SizedBox(height: 8),
                          _tabSelector(vertical: true),
                        ],
                      ),
                    ),
                    const VerticalDivider(width: 1),
                    // Right panel: chart
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: ChartCard(chartIndex: _chartIndex, data: data),
                      ),
                    ),
                  ],
                );
              }

              // ── Portrait: stacked ─────────────────────────────────
              return Column(
                children: [
                  _filterBar(),
                  _filterChips(),
                  const SizedBox(height: 8),
                  _tabSelector(),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: ChartCard(chartIndex: _chartIndex, data: data),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _filterBar() {
    return ChartFilterBar(
      filterYear: _filterYear,
      filterCustomerId: _filterCustomerId,
      filterSenderId: _filterSenderId,
      onYearChanged: (v) => setState(() => _filterYear = v),
      onCustomerChanged: (id, name) => setState(() {
        _filterCustomerId = id;
        _filterCustomerName = name;
      }),
      onSenderChanged: (id, name) => setState(() {
        _filterSenderId = id;
        _filterSenderName = name;
      }),
    );
  }

  Widget _filterChips() {
    return ChartFilterChips(
      filterYear: _filterYear,
      filterCustomerName: _filterCustomerName,
      filterSenderName: _filterSenderName,
      onRemoveYear: () => setState(() => _filterYear = null),
      onRemoveCustomer: () => setState(() {
        _filterCustomerId = null;
        _filterCustomerName = null;
      }),
      onRemoveSender: () => setState(() {
        _filterSenderId = null;
        _filterSenderName = null;
      }),
    );
  }

  Widget _tabSelector({bool vertical = false}) {
    if (vertical) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _tabButton(0, 'Revenue'),
            const SizedBox(height: 6),
            _tabButton(1, 'Paid / Unpaid'),
            const SizedBox(height: 6),
            _tabButton(2, 'Count'),
          ],
        ),
      );
    }

    return Padding(
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
    );
  }

  Widget _tabButton(int index, String label) {
    final cs = Theme.of(context).colorScheme;
    final isActive = _chartIndex == index;
    return FilledButton.tonal(
      style: FilledButton.styleFrom(
        backgroundColor: isActive
            ? cs.primaryContainer
            : cs.surfaceContainerHighest,
        foregroundColor: isActive ? cs.onPrimaryContainer : cs.onSurface,
        minimumSize: const Size.fromHeight(36),
        textStyle: TextStyle(
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      onPressed: () => setState(() => _chartIndex = index),
      child: Text(label),
    );
  }
}
