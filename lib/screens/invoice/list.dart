import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:new_invoice_generator/models/invoice_filter.dart';
import 'package:new_invoice_generator/providers/invoice.dart';
import 'package:new_invoice_generator/providers/invoice_filter.dart';
import 'package:new_invoice_generator/screens/invoice/create/create.dart';
import 'package:new_invoice_generator/screens/invoice/widgets/filter_sheet.dart';
import 'package:new_invoice_generator/screens/invoice/widgets/tile.dart';

class InvoiceListScreen extends ConsumerStatefulWidget {
  const InvoiceListScreen({super.key});

  @override
  ConsumerState<InvoiceListScreen> createState() => _InvoiceListScreenState();
}

class _InvoiceListScreenState extends ConsumerState<InvoiceListScreen> {
  final Set<String> _selected = {};
  bool get _isSelecting => _selected.isNotEmpty;

  void _toggleSelect(String id) {
    setState(() {
      if (_selected.contains(id)) {
        _selected.remove(id);
      } else {
        _selected.add(id);
      }
    });
  }

  void _clearSelection() => setState(() => _selected.clear());

  void _selectAll(List<String> ids) => setState(() => _selected.addAll(ids));

  Future<void> _deleteSelected() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          'Delete ${_selected.length} invoice${_selected.length == 1 ? '' : 's'}?',
        ),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    final notifier = ref.read(invoiceProvider.notifier);
    for (final id in _selected.toList()) {
      await notifier.deleteInvoice(id);
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${_selected.length} invoice(s) deleted')),
      );
      _clearSelection();
    }
  }

  Future<void> _markSelectedPaid() async {
    final unpaidIds = _selected.toList();
    if (unpaidIds.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          'Mark ${unpaidIds.length} invoice${unpaidIds.length == 1 ? '' : 's'} as paid?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Mark Paid',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    final notifier = ref.read(invoiceProvider.notifier);
    for (final id in unpaidIds) {
      await notifier.markPaid(id);
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${unpaidIds.length} invoice(s) marked as paid'),
        ),
      );
      _clearSelection();
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredAsync = ref.watch(filteredInvoicesProvider);
    final filter = ref.watch(invoiceFilterProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: _isSelecting
          ? _selectionAppBar(filteredAsync, cs)
          : _normalAppBar(filter, cs),
      body: Column(
        children: [
          if (filter.isActive && !_isSelecting)
            _FilterChips(filter: filter, ref: ref),
          Expanded(
            child: filteredAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (invoices) {
                if (invoices.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 64,
                          color: cs.onSurface.withAlpha(60),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          filter.isActive
                              ? 'No invoices match your filters'
                              : 'No invoices yet',
                          style: TextStyle(color: cs.onSurface.withAlpha(120)),
                        ),
                      ],
                    ),
                  );
                }

                // final ids = invoices
                //     .where((i) => i.id != null)
                //     .map((i) => i.id!)
                //     .toList();

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: invoices.length,
                  itemBuilder: (context, i) {
                    final inv = invoices[i];
                    final id = inv.id ?? '';
                    return InvoiceTile(
                      key: ValueKey(id),
                      invoice: inv,
                      isSelecting: _isSelecting,
                      isSelected: _selected.contains(id),
                      onLongPress: () => _toggleSelect(id),
                      onToggleSelect: () => _toggleSelect(id),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: _isSelecting
          ? null
          : FloatingActionButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreateInvoiceScreen()),
              ),
              child: const Icon(Icons.add),
            ),
    );
  }

  // ── Normal app bar ────────────────────────────────────────────────────────
  AppBar _normalAppBar(InvoiceFilter filter, ColorScheme cs) {
    return AppBar(
      title: const Text('Invoices'),
      actions: [
        Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.filter_list),
              tooltip: 'Filter',
              onPressed: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                builder: (_) => const InvoiceFilterSheet(),
              ),
            ),
            if (filter.isActive)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: cs.error,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
        if (filter.isActive)
          IconButton(
            icon: const Icon(Icons.clear),
            tooltip: 'Clear filters',
            onPressed: () => ref.read(invoiceFilterProvider.notifier).clear(),
          ),
      ],
    );
  }

  // ── Selection app bar ─────────────────────────────────────────────────────
  AppBar _selectionAppBar(AsyncValue<dynamic> filteredAsync, ColorScheme cs) {
    final allIds = (filteredAsync.asData?.value ?? [])
        .where((i) => i.id != null)
        .map<String>((i) => i.id as String)
        .toList();

    return AppBar(
      backgroundColor: cs.primaryContainer,
      leading: IconButton(
        icon: const Icon(Icons.close),
        tooltip: 'Cancel selection',
        onPressed: _clearSelection,
      ),
      title: Text('${_selected.length} selected'),
      actions: [
        // Select all
        IconButton(
          icon: const Icon(Icons.select_all),
          tooltip: 'Select all',
          onPressed: () => _selectAll(allIds),
        ),
        // Mark paid
        IconButton(
          icon: const Icon(Icons.check_circle_outline),
          tooltip: 'Mark selected as paid',
          onPressed: _markSelectedPaid,
        ),
        // Delete
        IconButton(
          icon: const Icon(Icons.delete_outline),
          tooltip: 'Delete selected',
          onPressed: _deleteSelected,
        ),
      ],
    );
  }
}

// ── Active filter chips ───────────────────────────────────────────────────────
class _FilterChips extends StatelessWidget {
  final InvoiceFilter filter;
  final WidgetRef ref;
  const _FilterChips({required this.filter, required this.ref});

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(invoiceFilterProvider.notifier);
    final chips = <Widget>[
      if (filter.customerName != null)
        _Chip(
          label: filter.customerName!,
          onRemove: () => notifier.update(filter.copyWith(clearCustomer: true)),
        ),
      if (filter.senderName != null)
        _Chip(
          label: 'Sender: ${filter.senderName}',
          onRemove: () => notifier.update(filter.copyWith(clearSender: true)),
        ),
      if (filter.serviceName != null)
        _Chip(
          label: filter.serviceName!,
          onRemove: () => notifier.update(filter.copyWith(clearService: true)),
        ),
      if (filter.month != null || filter.year != null)
        _Chip(
          label: [
            if (filter.month != null)
              const [
                'Jan',
                'Feb',
                'Mar',
                'Apr',
                'May',
                'Jun',
                'Jul',
                'Aug',
                'Sep',
                'Oct',
                'Nov',
                'Dec',
              ][filter.month! - 1],
            if (filter.year != null) '${filter.year}',
          ].join(' '),
          onRemove: () => notifier.update(
            filter.copyWith(clearMonth: true, clearYear: true),
          ),
        ),
      if (filter.isPaid != null)
        _Chip(
          label: filter.isPaid! ? 'Paid' : 'Unpaid',
          onRemove: () => notifier.update(filter.copyWith(clearStatus: true)),
        ),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Row(children: chips),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;
  const _Chip({required this.label, required this.onRemove});

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
