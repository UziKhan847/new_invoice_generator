import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:new_invoice_generator/models/invoice_filter.dart';
import 'package:new_invoice_generator/providers/invoice_filter.dart';
import 'package:new_invoice_generator/screens/invoice/create.dart';
import 'package:new_invoice_generator/screens/invoice/widgets/filter_sheet.dart';
import 'package:new_invoice_generator/screens/invoice/widgets/tile.dart';

class InvoiceListScreen extends ConsumerWidget {
  const InvoiceListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filteredAsync = ref.watch(filteredInvoicesProvider);
    final filter = ref.watch(invoiceFilterProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
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
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
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
      ),
      body: Column(
        children: [
          // Active filter chips
          if (filter.isActive) _FilterChips(filter: filter, ref: ref),

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
                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: invoices.length,
                  itemBuilder: (context, i) =>
                      InvoiceTile(invoice: invoices[i]),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CreateInvoiceScreen()),
        ),
        child: const Icon(Icons.add),
      ),
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
