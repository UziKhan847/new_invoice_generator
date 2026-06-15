import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:new_invoice_generator/models/customer.dart';
import 'package:new_invoice_generator/providers/customer.dart';
import 'package:new_invoice_generator/screens/invoice/create/widgets/invoice_form_helpers.dart';

class CustomerSection extends ConsumerWidget {
  final String? selectedId;
  final void Function(Customer? customer) onChanged;

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
        Customer? selected;
        for (final c in customers) {
          if (c.id == selectedId) {
            selected = c;
            break;
          }
        }

        return SectionCard(
          title: 'Customer',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                initialValue: selectedId,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Select customer'),
                items: customers
                    .map(
                      (c) => DropdownMenuItem(value: c.id, child: Text(c.name)),
                    )
                    .toList(),
                onChanged: (v) {
                  Customer? picked;
                  for (final c in customers) {
                    if (c.id == v) {
                      picked = c;
                      break;
                    }
                  }
                  onChanged(picked);
                },
              ),
              if (selected != null) ...[
                const SizedBox(height: 8),
                if (selected.email.isNotEmpty)
                  _row(cs, Icons.email_outlined, selected.email),
                if (selected.phone.isNotEmpty)
                  _row(cs, Icons.phone_outlined, selected.phone),
                if (selected.address.isNotEmpty)
                  _row(
                    cs,
                    Icons.location_on_outlined,
                    selected.address.singleLine,
                  ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _row(ColorScheme cs, IconData icon, String text) => Padding(
    padding: const EdgeInsets.only(top: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 13, color: cs.onSurface.withAlpha(130)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 12, color: cs.onSurface.withAlpha(150)),
          ),
        ),
      ],
    ),
  );
}
