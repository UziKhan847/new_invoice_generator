import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:new_invoice_generator/app_theme.dart';
import 'package:new_invoice_generator/desktop/widgets.dart';
import 'package:new_invoice_generator/providers/customer.dart';
import 'package:new_invoice_generator/providers/employee.dart';
import 'package:new_invoice_generator/providers/invoice/invoice.dart';
import 'package:new_invoice_generator/screens/charts/data.dart';
import 'package:new_invoice_generator/screens/charts/widgets/card.dart';

class DesktopCharts extends ConsumerStatefulWidget {
  const DesktopCharts({super.key});

  @override
  ConsumerState<DesktopCharts> createState() => _DesktopChartsState();
}

class _DesktopChartsState extends ConsumerState<DesktopCharts> {
  int _chartIndex = 0; // 0 revenue, 1 paid/unpaid, 2 count
  int? _filterYear;
  String? _filterCustomerId;
  String? _filterSenderId;

  @override
  Widget build(BuildContext context) {
    final invoicesAsync = ref.watch(invoiceProvider);
    final customers = ref.watch(customerProvider).asData?.value ?? [];
    final employees = ref.watch(employeeProvider).asData?.value ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DesktopTopBar(
          title: 'Charts',
          subtitle: 'Visual breakdowns',
          actions: [
            _FilterDropdown<int?>(
              label: 'Year',
              value: _filterYear,
              items: [
                const DropdownMenuItem(value: null, child: Text('All')),
                ..._years(
                  invoicesAsync.asData?.value,
                ).map((y) => DropdownMenuItem(value: y, child: Text('$y'))),
              ],
              onChanged: (v) => setState(() => _filterYear = v),
            ),
            const SizedBox(width: 10),
            _FilterDropdown<String?>(
              label: 'Customer',
              value: _filterCustomerId,
              items: [
                const DropdownMenuItem(value: null, child: Text('All')),
                ...customers.map(
                  (c) => DropdownMenuItem(value: c.id, child: Text(c.name)),
                ),
              ],
              onChanged: (v) => setState(() => _filterCustomerId = v),
            ),
            const SizedBox(width: 10),
            _FilterDropdown<String?>(
              label: 'Sender',
              value: _filterSenderId,
              items: [
                const DropdownMenuItem(value: null, child: Text('All')),
                ...employees.map(
                  (e) => DropdownMenuItem(value: e.id, child: Text(e.name)),
                ),
              ],
              onChanged: (v) => setState(() => _filterSenderId = v),
            ),
          ],
        ),
        Expanded(
          child: invoicesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (invoices) {
              final data = ChartData.fromInvoices(
                invoices: invoices,
                filterYear: _filterYear,
                filterCustomerId: _filterCustomerId,
                filterSenderId: _filterSenderId,
              );

              return ListView(
                padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
                children: [
                  // Tabs
                  _ChartTabs(
                    value: _chartIndex,
                    onChanged: (i) => setState(() => _chartIndex = i),
                  ),
                  const SizedBox(height: 18),
                  // Main chart (revenue if index 0, else whatever is selected)
                  DesktopPanel(
                    child: SizedBox(
                      height: 320,
                      child: ChartCard(
                        chartIndex: _chartIndex,
                        data: data,
                        labelSize: 11,
                      ),
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

  List<int> _years(List<dynamic>? invoices) {
    if (invoices == null) return [];
    final set = <int>{};
    for (final i in invoices) {
      set.add((i.issueDate as DateTime).year);
    }
    final list = set.toList()..sort((a, b) => b.compareTo(a));
    return list;
  }
}

class _ChartTabs extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  const _ChartTabs({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final p = AppColors.of(context);
    Widget tab(String label, int i) {
      final active = i == value;
      return GestureDetector(
        onTap: () => onChanged(i),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
          decoration: BoxDecoration(
            color: active ? p.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Text(
            label,
            style: active
                ? AppTypography.title(Colors.white).copyWith(fontSize: 13)
                : AppTypography.body(p.textSecondary).copyWith(fontSize: 13),
          ),
        ),
      );
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: p.surfaceAlt,
          borderRadius: BorderRadius.circular(11),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            tab('Revenue', 0),
            tab('Paid / Unpaid', 1),
            tab('Count', 2),
          ],
        ),
      ),
    );
  }
}

class _FilterDropdown<T> extends StatelessWidget {
  final String label;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final p = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(AppRadii.button),
        border: Border.all(color: p.cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: AppTypography.label(p.textTertiary)),
          const SizedBox(width: 8),
          DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              items: items,
              onChanged: onChanged,
              isDense: true,
              borderRadius: BorderRadius.circular(AppRadii.button),
              style: AppTypography.body(p.ink).copyWith(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
