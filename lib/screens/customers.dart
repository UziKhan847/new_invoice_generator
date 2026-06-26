import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:new_invoice_generator/app_theme.dart';
import 'package:new_invoice_generator/models/customer.dart';
import 'package:new_invoice_generator/providers/customer.dart';
import 'package:new_invoice_generator/screens/home/widgets/ui_kit.dart';
import 'package:new_invoice_generator/screens/import_customers.dart';
import 'package:new_invoice_generator/widgets/add_customer_dialog.dart';

class CustomersScreen extends ConsumerStatefulWidget {
  const CustomersScreen({super.key});

  @override
  ConsumerState<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends ConsumerState<CustomersScreen> {
  final Set<String> _selected = {};
  final _searchCtrl = TextEditingController();
  String _query = '';
  bool get _selecting => _selected.isNotEmpty;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

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
    final p = AppColors.of(context);
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
          : AppBar(
              title: const Text('Customers'),
              actions: [
                _SquareIconButton(icon: Icons.search, onTap: () {}),
                const SizedBox(width: 8),
                _SquareIconButton(
                  icon: Icons.upload_outlined,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ImportCustomersScreen(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
            ),
      body: customersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (allCustomers) {
          final customers = _query.isEmpty
              ? allCustomers
              : allCustomers.where((c) {
                  final q = _query.toLowerCase();
                  return c.name.toLowerCase().contains(q) ||
                      c.email.toLowerCase().contains(q);
                }).toList();

          return Column(
            children: [
              // Search field
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (v) => setState(() => _query = v),
                  decoration: InputDecoration(
                    hintText: 'Search by name or email',
                    prefixIcon: Icon(Icons.search, color: p.textTertiary),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            icon: Icon(Icons.clear, color: p.textTertiary),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _query = '');
                            },
                          ),
                  ),
                ),
              ),
              // Count label
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: AppLabel(
                    '${customers.length} customer${customers.length == 1 ? '' : 's'}',
                  ),
                ),
              ),
              Expanded(
                child: customers.isEmpty
                    ? _EmptyOrNoResults(hasQuery: _query.isNotEmpty)
                    : ListView.separated(
                        padding: EdgeInsets.fromLTRB(16, 4, 16, bottom + 90),
                        itemCount: customers.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, i) {
                          final c = customers[i];
                          return _CustomerTile(
                            customer: c,
                            selected: _selected.contains(c.id),
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
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: _selecting
          ? null
          : FloatingActionButton(
              onPressed: () => showAddCustomerSheet(context),
              backgroundColor: p.primary,
              foregroundColor: Colors.white,
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

class _SquareIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _SquareIconButton({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final p = AppColors.of(context);
    return Material(
      color: p.surface,
      borderRadius: BorderRadius.circular(AppRadii.button),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.button),
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.button),
            border: Border.all(color: p.cardBorder),
          ),
          child: Icon(icon, size: 20, color: p.ink),
        ),
      ),
    );
  }
}

class _CustomerTile extends StatelessWidget {
  final Customer customer;
  final bool selected, selecting;
  final VoidCallback onTap, onLongPress;

  const _CustomerTile({
    required this.customer,
    required this.selected,
    required this.selecting,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final p = AppColors.of(context);
    final c = customer;
    // Tags pulled from any free-text after the email-ish heuristics? We don't
    // store tags, so this is omitted unless present in future. Keeping layout
    // ready for name/email/phone.

    return Material(
      color: selected ? p.primaryTint : p.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.card),
        side: BorderSide(
          color: selected ? p.primary.withAlpha(120) : p.cardBorder,
          width: selected ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Avatar / select
              selecting
                  ? _SelectCircle(selected: selected, p: p)
                  : Container(
                      width: 46,
                      height: 46,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: p.primaryTint,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        c.name.isNotEmpty ? c.name[0].toUpperCase() : '?',
                        style: AppTypography.title(
                          p.primary,
                        ).copyWith(fontSize: 18),
                      ),
                    ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c.name,
                      style: AppTypography.title(p.ink).copyWith(fontSize: 16),
                    ),
                    if (c.email.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        c.email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodyMuted(p.textSecondary),
                      ),
                    ],
                    if (c.phone.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(
                            Icons.phone_outlined,
                            size: 13,
                            color: p.textTertiary,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            c.phone,
                            style: AppTypography.caption(p.textTertiary),
                          ),
                        ],
                      ),
                    ],
                    if (c.address.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 13,
                            color: p.gold,
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              c.address.singleLine,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.caption(p.gold),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              if (!selecting)
                Icon(Icons.chevron_right, color: p.textTertiary, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectCircle extends StatelessWidget {
  final bool selected;
  final AppPalette p;
  const _SelectCircle({required this.selected, required this.p});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? p.primary : Colors.transparent,
        border: Border.all(color: selected ? p.primary : p.border, width: 2),
      ),
      child: selected
          ? const Icon(Icons.check, size: 22, color: Colors.white)
          : null,
    );
  }
}

class _EmptyOrNoResults extends StatelessWidget {
  final bool hasQuery;
  const _EmptyOrNoResults({required this.hasQuery});
  @override
  Widget build(BuildContext context) {
    final p = AppColors.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            hasQuery ? Icons.search_off : Icons.people_outline,
            size: 64,
            color: p.textTertiary.withAlpha(120),
          ),
          const SizedBox(height: 16),
          Text(
            hasQuery ? 'No matches' : 'No customers yet',
            style: AppTypography.body(p.textSecondary),
          ),
          if (!hasQuery) ...[
            const SizedBox(height: 4),
            Text(
              'Tap + to add your first customer',
              style: AppTypography.caption(p.textTertiary),
            ),
          ],
        ],
      ),
    );
  }
}
