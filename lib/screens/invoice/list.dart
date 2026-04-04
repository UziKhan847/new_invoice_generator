import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:new_invoice_generator/models/invoice.dart';
import 'package:new_invoice_generator/models/invoice_filter.dart';
import 'package:new_invoice_generator/providers/company.dart';
import 'package:new_invoice_generator/providers/customer.dart';
import 'package:new_invoice_generator/providers/employee.dart';
import 'package:new_invoice_generator/providers/invoice.dart';
import 'package:new_invoice_generator/providers/invoice_filter.dart';
import 'package:new_invoice_generator/providers/service.dart';
import 'package:new_invoice_generator/screens/invoice/create.dart';
import 'package:new_invoice_generator/screens/invoice/detail.dart';
import 'package:new_invoice_generator/services/download.dart';
import 'package:new_invoice_generator/services/email.dart';
import 'package:new_invoice_generator/services/pdf.dart';
import 'package:new_invoice_generator/services/storage.dart';
import 'package:printing/printing.dart';

class InvoiceListScreen extends ConsumerWidget {
  const InvoiceListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filteredAsync = ref.watch(filteredInvoicesProvider);
    final filter = ref.watch(invoiceFilterProvider);

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
                onPressed: () => _showFilterSheet(context, ref),
              ),
              if (filter.isActive)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.red,
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
          if (filter.isActive) _ActiveFilterChips(filter: filter, ref: ref),
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
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          filter.isActive
                              ? 'No invoices match your filters'
                              : 'No invoices yet',
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: invoices.length,
                  itemBuilder: (context, i) =>
                      _InvoiceTile(invoice: invoices[i]),
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

  void _showFilterSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _FilterBottomSheet(),
    );
  }
}

// ── Invoice tile ──────────────────────────────────────────────────────────────
class _InvoiceTile extends ConsumerWidget {
  final Invoice invoice;
  const _InvoiceTile({required this.invoice});

  Future<String?> _getLogoUrl(WidgetRef ref) async {
    final company = await ref.read(companyProvider.future);
    final path = company['logo_storage_path'] as String?;
    String? url;
    if (path != null) url = await StorageService.getFreshLogoUrl(path);
    return url ?? company['logo_url'] as String?;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;

    return Dismissible(
      key: ValueKey(invoice.id),
      direction: DismissDirection.endToStart, // swipe left to delete
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Delete invoice?'),
            content: Text(
              'Invoice ${invoice.invoiceNumber} will be permanently deleted.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) {
        ref.read(invoiceProvider.notifier).deleteInvoice(invoice.id!);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invoice ${invoice.invoiceNumber} deleted')),
        );
      },
      // Red delete background revealed on swipe left
      background: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete_outline, color: Colors.white, size: 24),
            SizedBox(height: 4),
            Text(
              'Delete',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => InvoiceDetailScreen(invoiceId: invoice.id!),
            ),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
            leading: CircleAvatar(
              radius: 20,
              backgroundColor: invoice.isPaid
                  ? Colors.green.withAlpha(30)
                  : cs.primary.withAlpha(30),
              child: Icon(
                invoice.isPaid ? Icons.check : Icons.receipt_long,
                color: invoice.isPaid ? Colors.green : cs.primary,
                size: 18,
              ),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    invoice.invoiceNumber,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
                Text(
                  '\$${invoice.total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 2),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        invoice.customerName,
                        style: TextStyle(
                          fontSize: 13,
                          color: cs.onSurface.withAlpha(180),
                        ),
                      ),
                    ),
                    _StatusBadge(isPaid: invoice.isPaid),
                  ],
                ),
                if (invoice.senderName != null) ...[
                  const SizedBox(height: 1),
                  Text(
                    'Sender: ${invoice.senderName}',
                    style: TextStyle(
                      fontSize: 11,
                      color: cs.onSurface.withAlpha(130),
                    ),
                  ),
                ],
                const SizedBox(height: 1),
                Text(
                  invoice.issueDate.toLocal().toString().split(' ')[0],
                  style: TextStyle(
                    fontSize: 11,
                    color: cs.onSurface.withAlpha(110),
                  ),
                ),
              ],
            ),
            trailing: _QuickMenu(
              invoice: invoice,
              getLogoUrl: () => _getLogoUrl(ref),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Quick action popup menu ───────────────────────────────────────────────────
enum _QuickAction { markPaid, email, download, preview }

class _QuickMenu extends ConsumerWidget {
  final Invoice invoice;
  final Future<String?> Function() getLogoUrl;
  const _QuickMenu({required this.invoice, required this.getLogoUrl});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<_QuickAction>(
      iconSize: 20,
      padding: EdgeInsets.zero,
      tooltip: 'Quick actions',
      icon: Icon(
        Icons.more_vert,
        size: 20,
        color: Theme.of(context).colorScheme.onSurface.withAlpha(140),
      ),
      onSelected: (action) async {
        switch (action) {
          case _QuickAction.markPaid:
            final confirm = await showDialog<bool>(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text('Mark as paid?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text(
                      'Mark Paid',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            );
            if (confirm == true && context.mounted) {
              await ref.read(invoiceProvider.notifier).markPaid(invoice.id!);
            }
            break;

          case _QuickAction.email:
            if (!context.mounted) break;
            _showQuickEmailDialog(context, ref);
            break;

          case _QuickAction.download:
            final logoUrl = await getLogoUrl();
            if (context.mounted) {
              await DownloadService.downloadInvoice(
                context: context,
                invoice: invoice,
                companyLogoUrl: logoUrl,
              );
            }
            break;

          case _QuickAction.preview:
            final logoUrl = await getLogoUrl();
            final inv = logoUrl != null
                ? invoice.copyWith(companyLogoUrl: logoUrl)
                : invoice;
            if (context.mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => _QuickPdfPreview(invoice: inv),
                ),
              );
            }
            break;
        }
      },
      itemBuilder: (_) => [
        if (!invoice.isPaid)
          const PopupMenuItem(
            value: _QuickAction.markPaid,
            child: _MenuItem(
              icon: Icons.check_circle_outline,
              label: 'Mark as Paid',
              color: Colors.green,
            ),
          ),
        const PopupMenuItem(
          value: _QuickAction.email,
          child: _MenuItem(icon: Icons.email_outlined, label: 'Email'),
        ),
        const PopupMenuItem(
          value: _QuickAction.download,
          child: _MenuItem(icon: Icons.download_outlined, label: 'Download'),
        ),
        const PopupMenuItem(
          value: _QuickAction.preview,
          child: _MenuItem(
            icon: Icons.visibility_outlined,
            label: 'Preview PDF',
          ),
        ),
      ],
    );
  }

  void _showQuickEmailDialog(BuildContext context, WidgetRef ref) {
    final emailCtrl = TextEditingController(text: invoice.customerEmail ?? '');
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Email ${invoice.invoiceNumber}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (invoice.customerEmail != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Auto-filled from customer record',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            TextField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Recipient email'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final logoUrl = await getLogoUrl();
              if (context.mounted) {
                await EmailService.emailInvoice(
                  context: context,
                  invoice: invoice,
                  recipientEmail: emailCtrl.text.trim(),
                  companyLogoUrl: logoUrl,
                );
              }
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  const _MenuItem({required this.icon, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.onSurface;
    return Row(
      children: [
        Icon(icon, size: 18, color: c),
        const SizedBox(width: 12),
        Text(label, style: TextStyle(color: c)),
      ],
    );
  }
}

// ── Quick PDF preview (lightweight — from list) ───────────────────────────────
class _QuickPdfPreview extends StatelessWidget {
  final Invoice invoice;
  const _QuickPdfPreview({required this.invoice});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Invoice ${invoice.invoiceNumber}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.print_outlined),
            tooltip: 'Print',
            onPressed: () async {
              final bytes = await PdfService.buildPdfBytes(invoice);
              await Printing.layoutPdf(onLayout: (_) async => bytes);
            },
          ),
        ],
      ),
      body: PdfPreview(
        build: (format) => PdfService.buildPdfBytes(invoice),
        allowPrinting: false,
        allowSharing: false,
        canChangeOrientation: false,
        canChangePageFormat: false,
        canDebug: false,
        pdfFileName: 'invoice_${invoice.invoiceNumber}.pdf',
      ),
    );
  }
}

// ── Status badge ──────────────────────────────────────────────────────────────
class _StatusBadge extends StatelessWidget {
  final bool isPaid;
  const _StatusBadge({required this.isPaid});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isPaid
            ? Colors.green.withAlpha(20)
            : Colors.orange.withAlpha(20),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isPaid ? Colors.green : Colors.orange),
      ),
      child: Text(
        isPaid ? 'Paid' : 'Unpaid',
        style: TextStyle(
          fontSize: 10,
          color: isPaid ? Colors.green : Colors.orange,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ── Active filter chips ───────────────────────────────────────────────────────
class _ActiveFilterChips extends StatelessWidget {
  final InvoiceFilter filter;
  final WidgetRef ref;
  const _ActiveFilterChips({required this.filter, required this.ref});

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[];
    if (filter.customerName != null) {
      chips.add(
        _Chip(
          label: 'Customer: ${filter.customerName}',
          onRemove: () => ref
              .read(invoiceFilterProvider.notifier)
              .update(filter.copyWith(clearCustomer: true)),
        ),
      );
    }
    if (filter.senderName != null) {
      chips.add(
        _Chip(
          label: 'Sender: ${filter.senderName}',
          onRemove: () => ref
              .read(invoiceFilterProvider.notifier)
              .update(filter.copyWith(clearSender: true)),
        ),
      );
    }
    if (filter.serviceName != null) {
      chips.add(
        _Chip(
          label: 'Service: ${filter.serviceName}',
          onRemove: () => ref
              .read(invoiceFilterProvider.notifier)
              .update(filter.copyWith(clearService: true)),
        ),
      );
    }
    if (filter.month != null || filter.year != null) {
      final label = [
        if (filter.month != null) _monthName(filter.month!),
        if (filter.year != null) '${filter.year}',
      ].join(' ');
      chips.add(
        _Chip(
          label: label,
          onRemove: () => ref
              .read(invoiceFilterProvider.notifier)
              .update(filter.copyWith(clearMonth: true, clearYear: true)),
        ),
      );
    }
    if (filter.isPaid != null) {
      chips.add(
        _Chip(
          label: filter.isPaid! ? 'Paid' : 'Unpaid',
          onRemove: () => ref
              .read(invoiceFilterProvider.notifier)
              .update(filter.copyWith(clearStatus: true)),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Row(children: chips),
    );
  }

  static String _monthName(int m) => const [
    '',
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
  ][m];
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

// ── Filter bottom sheet ───────────────────────────────────────────────────────
class _FilterBottomSheet extends ConsumerStatefulWidget {
  const _FilterBottomSheet();

  @override
  ConsumerState<_FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends ConsumerState<_FilterBottomSheet> {
  late InvoiceFilter _local;

  @override
  void initState() {
    super.initState();
    _local = ref.read(invoiceFilterProvider);
  }

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(customerProvider);
    final employeesAsync = ref.watch(employeeProvider);
    final servicesAsync = ref.watch(serviceProvider);
    final services = servicesAsync.asData?.value ?? [];
    final now = DateTime.now();

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Filter Invoices',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () => setState(() => _local = const InvoiceFilter()),
                child: const Text('Clear all'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          customersAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
            data: (customers) => DropdownButtonFormField<String>(
              initialValue: _local.customerId,
              decoration: const InputDecoration(
                labelText: 'Customer',
                isDense: true,
              ),
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('All customers'),
                ),
                ...customers.map(
                  (c) => DropdownMenuItem(value: c.id, child: Text(c.name)),
                ),
              ],
              onChanged: (v) {
                final name =
                    customers
                            .cast<dynamic>()
                            .firstWhere((c) => c.id == v, orElse: () => null)
                            ?.name
                        as String?;
                setState(
                  () => _local = _local.copyWith(
                    customerId: v,
                    customerName: name,
                    clearCustomer: v == null,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          employeesAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
            data: (employees) => DropdownButtonFormField<String>(
              initialValue: _local.senderEmployeeId,
              decoration: const InputDecoration(
                labelText: 'Sender',
                isDense: true,
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('All senders')),
                ...employees.map(
                  (e) => DropdownMenuItem(value: e.id, child: Text(e.name)),
                ),
              ],
              onChanged: (v) {
                final name =
                    employees
                            .cast<dynamic>()
                            .firstWhere((e) => e.id == v, orElse: () => null)
                            ?.name
                        as String?;
                setState(
                  () => _local = _local.copyWith(
                    senderEmployeeId: v,
                    senderName: name,
                    clearSender: v == null,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          if (services.isNotEmpty)
            DropdownButtonFormField<String>(
              initialValue: _local.serviceId,
              decoration: const InputDecoration(
                labelText: 'Service',
                isDense: true,
              ),
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('All services'),
                ),
                ...services.map(
                  (s) => DropdownMenuItem(value: s.id, child: Text(s.name)),
                ),
              ],
              onChanged: (v) {
                final name =
                    services
                            .cast<dynamic>()
                            .firstWhere((s) => s.id == v, orElse: () => null)
                            ?.name
                        as String?;
                setState(
                  () => _local = _local.copyWith(
                    serviceId: v,
                    serviceName: name,
                    clearService: v == null,
                  ),
                );
              },
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  initialValue: _local.month,
                  decoration: const InputDecoration(
                    labelText: 'Month',
                    isDense: true,
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Any')),
                    ...List.generate(
                      12,
                      (i) => DropdownMenuItem(
                        value: i + 1,
                        child: Text(
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
                          ][i],
                        ),
                      ),
                    ),
                  ],
                  onChanged: (v) => setState(
                    () => _local = _local.copyWith(
                      month: v,
                      clearMonth: v == null,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<int>(
                  initialValue: _local.year,
                  decoration: const InputDecoration(
                    labelText: 'Year',
                    isDense: true,
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Any')),
                    ...List.generate(
                      5,
                      (i) => DropdownMenuItem(
                        value: now.year - i,
                        child: Text('${now.year - i}'),
                      ),
                    ),
                  ],
                  onChanged: (v) => setState(
                    () =>
                        _local = _local.copyWith(year: v, clearYear: v == null),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<bool>(
            initialValue: _local.isPaid,
            decoration: const InputDecoration(
              labelText: 'Status',
              isDense: true,
            ),
            items: const [
              DropdownMenuItem(value: null, child: Text('All')),
              DropdownMenuItem(value: true, child: Text('Paid')),
              DropdownMenuItem(value: false, child: Text('Unpaid')),
            ],
            onChanged: (v) => setState(
              () => _local = _local.copyWith(isPaid: v, clearStatus: v == null),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              onPressed: () {
                ref.read(invoiceFilterProvider.notifier).update(_local);
                Navigator.pop(context);
              },
              child: const Text('Apply Filters'),
            ),
          ),
        ],
      ),
    );
  }
}
