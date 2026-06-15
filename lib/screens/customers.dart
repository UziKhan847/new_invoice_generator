import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:new_invoice_generator/models/customer.dart';
import 'package:new_invoice_generator/providers/customer.dart';
import 'package:new_invoice_generator/widgets/add_customer_dialog.dart';

class CustomersScreen extends ConsumerStatefulWidget {
  const CustomersScreen({super.key});

  @override
  ConsumerState<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends ConsumerState<CustomersScreen> {
  final Set<String> _selected = {};
  bool get _selecting => _selected.isNotEmpty;

  void _toggle(String id) {
    setState(() {
      if (_selected.contains(id)) {
        _selected.remove(id);
      } else {
        _selected.add(id);
      }
    });
  }

  void _clearSelection() => setState(() => _selected.clear());

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(customerProvider);
    final cs = Theme.of(context).colorScheme;
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      appBar: _selecting
          ? AppBar(
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: _clearSelection,
              ),
              title: Text('${_selected.length} selected'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Delete selected',
                  onPressed: () => _confirmDeleteSelected(context),
                ),
              ],
            )
          : AppBar(title: const Text('Customers')),
      body: customersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (customers) {
          if (customers.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 64,
                    color: cs.onSurface.withAlpha(60),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No customers yet',
                    style: TextStyle(color: cs.onSurface.withAlpha(120)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap + to add your first customer',
                    style: TextStyle(
                      fontSize: 12,
                      color: cs.onSurface.withAlpha(100),
                    ),
                  ),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: EdgeInsets.fromLTRB(12, 12, 12, bottom + 80),
            itemCount: customers.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final c = customers[i];
              final selected = _selected.contains(c.id);
              return _CustomerTile(
                customer: c,
                selected: selected,
                selecting: _selecting,
                onTap: () {
                  if (_selecting) {
                    _toggle(c.id);
                  } else {
                    showAddCustomerSheet(context, existing: c);
                  }
                },
                onLongPress: () => _toggle(c.id),
              );
            },
          );
        },
      ),
      floatingActionButton: _selecting
          ? null
          : FloatingActionButton(
              onPressed: () => showAddCustomerSheet(context),
              child: const Icon(Icons.add),
            ),
    );
  }

  void _confirmDeleteSelected(BuildContext context) {
    final count = _selected.length;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Delete $count customer${count == 1 ? '' : 's'}?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              final notifier = ref.read(customerProvider.notifier);
              for (final id in _selected) {
                await notifier.deleteCustomer(id);
              }
              _clearSelection();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _CustomerTile extends StatelessWidget {
  final Customer customer;
  final bool selected;
  final bool selecting;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _CustomerTile({
    required this.customer,
    required this.selected,
    required this.selecting,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final c = customer;
    const radius = 14.0;

    return Material(
      // Material + clipBehavior makes the ink splash respect the rounded corners
      color: selected ? cs.primaryContainer.withAlpha(90) : cs.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
        side: BorderSide(
          color: selected
              ? cs.primary.withAlpha(140)
              : cs.outlineVariant.withAlpha(160),
          width: selected ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              // Avatar or selection check
              selecting
                  ? _SelectCircle(selected: selected, cs: cs)
                  : CircleAvatar(
                      backgroundColor: cs.primaryContainer,
                      child: Text(
                        c.name.isNotEmpty ? c.name[0].toUpperCase() : '?',
                        style: TextStyle(
                          color: cs.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c.name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    if (c.email.isNotEmpty)
                      Text(
                        c.email,
                        style: TextStyle(
                          fontSize: 13,
                          color: cs.onSurface.withAlpha(170),
                        ),
                      ),
                    if (c.phone.isNotEmpty)
                      Text(
                        c.phone,
                        style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurface.withAlpha(140),
                        ),
                      ),
                    if (c.address.isNotEmpty)
                      Text(
                        c.address.singleLine,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurface.withAlpha(130),
                        ),
                      ),
                  ],
                ),
              ),
              if (!selecting)
                Icon(
                  Icons.chevron_right,
                  color: cs.onSurface.withAlpha(90),
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectCircle extends StatelessWidget {
  final bool selected;
  final ColorScheme cs;
  const _SelectCircle({required this.selected, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? cs.primary : Colors.transparent,
        border: Border.all(
          color: selected ? cs.primary : cs.outlineVariant,
          width: 2,
        ),
      ),
      child: selected ? Icon(Icons.check, size: 20, color: cs.onPrimary) : null,
    );
  }
}
