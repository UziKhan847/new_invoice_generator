import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:new_invoice_generator/models/employee.dart';
import 'package:new_invoice_generator/providers/employee.dart';
import 'package:new_invoice_generator/screens/invoice/create/widgets/invoice_form_helpers.dart';

class SenderSection extends ConsumerWidget {
  final Employee? selected;
  final ValueChanged<Employee?> onChanged;

  const SenderSection({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final employeesAsync = ref.watch(employeeProvider);

    return employeesAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (employees) {
        if (employees.isEmpty) return const SizedBox.shrink();
        return SectionCard(
          title: 'Sender / Employee',
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                initialValue: selected?.id,
                decoration: const InputDecoration(
                  labelText: 'Select employee (optional)',
                ),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('No employee'),
                  ),
                  ...employees.map(
                    (e) => DropdownMenuItem(
                      value: e.id,
                      child: Text('${e.name} · ${e.role}'),
                    ),
                  ),
                ],
                onChanged: (v) => onChanged(
                  v == null ? null : employees.firstWhere((e) => e.id == v),
                ),
              ),
              if (selected?.email != null && selected!.email.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.withAlpha(60)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.account_balance_wallet_outlined,
                        size: 14,
                        color: Colors.green,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'E-transfer to: ${selected!.email}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.green,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
