import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:new_invoice_generator/providers/customer.dart';
import 'package:new_invoice_generator/screens/invoice/create/widgets/invoice_form_helpers.dart';

class CustomerSection extends ConsumerWidget {
  final String? selectedId;
  final void Function(String? id, String? name, String? email, String? phone) onChanged;

  const CustomerSection({
    super.key,
    required this.selectedId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customersAsync = ref.watch(customerProvider);
    final cs = Theme.of(context).colorScheme;

    return customersAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (e, _) => Text('Error: $e'),
      data: (customers) {
        final selected = selectedId == null
            ? null
            : customers.cast<dynamic>().firstWhere(
                (c) => c.id == selectedId,
                orElse: () => null);

        return SectionCard(
          title: 'Customer',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                initialValue: selectedId,
                decoration:
                    const InputDecoration(labelText: 'Select customer'),
                items: customers
                    .map((c) =>
                        DropdownMenuItem(value: c.id, child: Text(c.name)))
                    .toList(),
                onChanged: (v) {
                  final c = customers.cast<dynamic>().firstWhere(
                      (c) => c.id == v,
                      orElse: () => null);
                  onChanged(
                    v,
                    c?.name as String?,
                    c?.email as String?,
                    c?.phone as String?,
                  );
                },
              ),
              if (selected?.email != null &&
                  (selected!.email as String).isNotEmpty) ...[
                const SizedBox(height: 6),
                Row(children: [
                  Icon(Icons.email_outlined,
                      size: 13, color: cs.onSurface.withAlpha(130)),
                  const SizedBox(width: 6),
                  Text(selected.email as String,
                      style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurface.withAlpha(140))),
                ]),
              ],
              if (selected?.phone != null &&
                  (selected!.phone as String).isNotEmpty) ...[
                const SizedBox(height: 4),
                Row(children: [
                  Icon(Icons.phone_outlined,
                      size: 13, color: cs.onSurface.withAlpha(130)),
                  const SizedBox(width: 6),
                  Text(selected.phone as String,
                      style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurface.withAlpha(140))),
                ]),
              ],
            ],
          ),
        );
      },
    );
  }
}