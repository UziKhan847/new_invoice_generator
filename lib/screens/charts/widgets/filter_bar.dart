import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:new_invoice_generator/providers/customer.dart';
import 'package:new_invoice_generator/providers/employee.dart';

class ChartFilterBar extends ConsumerWidget {
  final int? filterYear;
  final String? filterCustomerId;
  final String? filterSenderId;
  final ValueChanged<int?> onYearChanged;
  final void Function(String? id, String? name) onCustomerChanged;
  final void Function(String? id, String? name) onSenderChanged;

  const ChartFilterBar({
    super.key,
    required this.filterYear,
    required this.filterCustomerId,
    required this.filterSenderId,
    required this.onYearChanged,
    required this.onCustomerChanged,
    required this.onSenderChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customersAsync = ref.watch(customerProvider);
    final employeesAsync = ref.watch(employeeProvider);
    final now = DateTime.now();

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<int>(
              initialValue: filterYear,
              isDense: true,
              decoration: const InputDecoration(
                labelText: 'Year',
                isDense: true,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('All years')),
                ...List.generate(
                  5,
                  (i) => DropdownMenuItem(
                      value: now.year - i, child: Text('${now.year - i}')),
                ),
              ],
              onChanged: onYearChanged,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: customersAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
              data: (customers) => DropdownButtonFormField<String>(
                initialValue: filterCustomerId,
                isDense: true,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Customer',
                  isDense: true,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('All')),
                  ...customers.map((c) => DropdownMenuItem(
                        value: c.id,
                        child: Text(c.name,
                            overflow: TextOverflow.ellipsis, maxLines: 1),
                      )),
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
          ),
          const SizedBox(width: 8),
          Expanded(
            child: employeesAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
              data: (employees) => employees.isEmpty
                  ? const SizedBox.shrink()
                  : DropdownButtonFormField<String>(
                      initialValue: filterSenderId,
                      isDense: true,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Sender',
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                      ),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('All')),
                        ...employees.map((e) => DropdownMenuItem(
                              value: e.id,
                              child: Text(e.name,
                                  overflow: TextOverflow.ellipsis, maxLines: 1),
                            )),
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
    );
  }
}