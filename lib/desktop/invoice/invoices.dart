import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:new_invoice_generator/app_theme.dart';
import 'package:new_invoice_generator/desktop/invoice/detail.dart';
import 'package:new_invoice_generator/desktop/invoice/document_view.dart';
import 'package:new_invoice_generator/desktop/widgets.dart';
import 'package:new_invoice_generator/models/customer.dart';
import 'package:new_invoice_generator/models/invoice/invoice.dart';
import 'package:new_invoice_generator/providers/company.dart';
import 'package:new_invoice_generator/providers/customer.dart';
import 'package:new_invoice_generator/providers/invoice/invoice.dart';
import 'package:new_invoice_generator/screens/home/widgets/ui_kit.dart';
import 'package:new_invoice_generator/screens/invoice/create/create.dart';

/// Filter for the invoice list.
enum InvoiceFilter { all, paid, unpaid }

/// Currently selected invoice id in the desktop master-detail view (null = none).
class SelectedInvoiceNotifier extends Notifier<String?> {
  @override
  String? build() => null;
  void select(String? id) => state = id;
}

final selectedInvoiceProvider =
    NotifierProvider<SelectedInvoiceNotifier, String?>(
      SelectedInvoiceNotifier.new,
    );

class DesktopInvoices extends ConsumerStatefulWidget {
  const DesktopInvoices({super.key});

  @override
  ConsumerState<DesktopInvoices> createState() => _DesktopInvoicesState();
}

class _DesktopInvoicesState extends ConsumerState<DesktopInvoices> {
  InvoiceFilter _filter = InvoiceFilter.all;

  @override
  Widget build(BuildContext context) {
    final p = AppColors.of(context);
    final invoicesAsync = ref.watch(invoiceProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        invoicesAsync.when(
          loading: () => const DesktopTopBar(title: 'Invoices'),
          error: (_, _) => const DesktopTopBar(title: 'Invoices'),
          data: (all) {
            // Private invoices ARE shown in the list (with a lock badge) so they
            // can be managed across devices. They're only excluded from official
            // figures (analytics, totals, tax report) — handled in those screens.
            final awaiting = all.where((i) => !i.isPaid).length;
            return DesktopTopBar(
              title: 'Invoices',
              subtitle: '${all.length} total · $awaiting awaiting payment',
              actions: [
                DesktopPrimaryButton(
                  icon: Icons.add,
                  label: 'New Invoice',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CreateInvoiceScreen(),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        Expanded(
          child: invoicesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (all) {
              // Show all invoices including private (lock-badged); private are
              // only excluded from official figures elsewhere.
              final visible = [...all]
                ..sort((a, b) => b.issueDate.compareTo(a.issueDate));
              final filtered = switch (_filter) {
                InvoiceFilter.all => visible,
                InvoiceFilter.paid => visible.where((i) => i.isPaid).toList(),
                InvoiceFilter.unpaid =>
                  visible.where((i) => !i.isPaid).toList(),
              };

              final selectedId = ref.watch(selectedInvoiceProvider);
              // Resolve selection; default to the first if none / invalid.
              Invoice? selected;
              for (final i in filtered) {
                if (i.id == selectedId) {
                  selected = i;
                  break;
                }
              }
              selected ??= filtered.isNotEmpty ? filtered.first : null;

              return Padding(
                padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Left: filter tabs + list ───────────────────────
                    SizedBox(
                      width: 380,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _FilterTabs(
                            value: _filter,
                            onChanged: (f) => setState(() => _filter = f),
                          ),
                          const SizedBox(height: 12),
                          Expanded(
                            child: filtered.isEmpty
                                ? Center(
                                    child: Text(
                                      'No invoices',
                                      style: AppTypography.bodyMuted(
                                        p.textTertiary,
                                      ),
                                    ),
                                  )
                                : ListView.separated(
                                    itemCount: filtered.length,
                                    separatorBuilder: (_, _) =>
                                        const SizedBox(height: 8),
                                    itemBuilder: (context, i) {
                                      final inv = filtered[i];
                                      return _InvoiceListItem(
                                        invoice: inv,
                                        selected: inv.id == selected?.id,
                                        onTap: () => ref
                                            .read(
                                              selectedInvoiceProvider.notifier,
                                            )
                                            .select(inv.id),
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    // ── Right: preview ─────────────────────────────────
                    Expanded(
                      child: selected == null
                          ? Center(
                              child: Text(
                                'Select an invoice to preview',
                                style: AppTypography.bodyMuted(p.textTertiary),
                              ),
                            )
                          : _PreviewPane(invoice: selected),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _FilterTabs extends StatelessWidget {
  final InvoiceFilter value;
  final ValueChanged<InvoiceFilter> onChanged;
  const _FilterTabs({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final p = AppColors.of(context);
    Widget tab(String label, InvoiceFilter f) {
      final active = f == value;
      return Expanded(
        child: GestureDetector(
          onTap: () => onChanged(f),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 9),
            decoration: BoxDecoration(
              color: active ? p.surface : Colors.transparent,
              borderRadius: BorderRadius.circular(9),
              boxShadow: active ? p.cardShadow : null,
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: active
                  ? AppTypography.title(p.ink).copyWith(fontSize: 13)
                  : AppTypography.body(p.textSecondary).copyWith(fontSize: 13),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: p.surfaceAlt,
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(
        children: [
          tab('All', InvoiceFilter.all),
          tab('Paid', InvoiceFilter.paid),
          tab('Unpaid', InvoiceFilter.unpaid),
        ],
      ),
    );
  }
}

class _InvoiceListItem extends StatelessWidget {
  final Invoice invoice;
  final bool selected;
  final VoidCallback onTap;
  const _InvoiceListItem({
    required this.invoice,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = AppColors.of(context);
    final date = invoice.issueDate.toIso8601String().split('T').first;

    // Status icon + colors
    final IconData icon;
    final Color iconColor, iconBg;
    if (invoice.isPaid) {
      icon = Icons.check_circle_outline;
      iconColor = p.successText;
      iconBg = p.successBg;
    } else if (invoice.dueDate != null &&
        invoice.dueDate!.isBefore(DateTime.now())) {
      icon = Icons.access_time;
      iconColor = p.dangerText;
      iconBg = p.dangerBg;
    } else {
      icon = Icons.error_outline;
      iconColor = p.warningText;
      iconBg = p.warningBg;
    }

    return Material(
      color: selected ? p.primaryTint : p.surface,
      borderRadius: BorderRadius.circular(AppRadii.card),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.card),
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.card),
            border: Border.all(
              color: selected ? p.primary.withAlpha(110) : p.cardBorder,
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 18, color: iconColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          invoice.invoiceNumber,
                          style: AppTypography.title(
                            invoice.isPrivate ? p.purple : p.ink,
                          ).copyWith(fontSize: 14),
                        ),
                        if (invoice.isPrivate) ...[
                          const SizedBox(width: 5),
                          Icon(Icons.lock_outline, size: 12, color: p.purple),
                        ],
                      ],
                    ),
                    Text(
                      invoice.customerName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.caption(p.textSecondary),
                    ),
                    Text(date, style: AppTypography.numeric(p.textTertiary)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '\$${invoice.total.toStringAsFixed(2)}',
                    style: AppTypography.title(p.ink).copyWith(fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  invoice.isPaid
                      ? AppPill.paid(context)
                      : AppPill.unpaid(context),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PreviewPane extends ConsumerWidget {
  final Invoice invoice;
  const _PreviewPane({required this.invoice});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = AppColors.of(context);
    final company = ref.watch(companyProvider).asData?.value;
    final customer = _resolveCustomer(ref, invoice.customerId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Action bar
        Row(
          children: [
            Text(
              'Previewing ',
              style: AppTypography.bodyMuted(p.textSecondary),
            ),
            Text(
              invoice.invoiceNumber,
              style: AppTypography.title(p.ink).copyWith(fontSize: 14),
            ),
            const Spacer(),
            _OutlineBtn(
              icon: Icons.edit_outlined,
              label: 'Edit',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CreateInvoiceScreen(editingInvoice: invoice),
                ),
              ),
            ),
            const SizedBox(width: 8),
            _OutlineBtn(
              icon: Icons.copy_outlined,
              label: 'Duplicate',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CreateInvoiceScreen(prefill: invoice),
                ),
              ),
            ),
            const SizedBox(width: 8),
            _OutlineBtn(
              icon: Icons.delete_outline,
              label: 'Delete',
              danger: true,
              onTap: () => _confirmDelete(context, ref, invoice),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      DesktopInvoiceDetail(invoiceId: invoice.id ?? ''),
                ),
              ),
              icon: const Icon(Icons.open_in_full, size: 16),
              label: const Text('Open'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 11,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Expanded(
          child: SingleChildScrollView(
            child: InvoiceDocumentView(
              invoice: invoice,
              company: company,
              customer: customer,
            ),
          ),
        ),
      ],
    );
  }

  Customer? _resolveCustomer(WidgetRef ref, String? customerId) {
    if (customerId == null) return null;
    final list = ref.read(customerProvider).asData?.value;
    if (list == null) return null;
    for (final c in list) {
      if (c.id == customerId) return c;
    }
    return null;
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Invoice inv) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete invoice?'),
        content: Text('${inv.invoiceNumber} will be permanently removed.'),
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
    if (ok == true && inv.id != null) {
      // Clear selection so the preview doesn't point at a deleted invoice.
      ref.read(selectedInvoiceProvider.notifier).select(null);
      await ref.read(invoiceProvider.notifier).deleteInvoice(inv.id!);
    }
  }
}

class _OutlineBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool danger;
  const _OutlineBtn({
    required this.icon,
    required this.label,
    required this.onTap,
    this.danger = false,
  });
  @override
  Widget build(BuildContext context) {
    final p = AppColors.of(context);
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: danger ? p.dangerText : p.ink,
        side: BorderSide(color: danger ? p.dangerBorder : p.border, width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      ),
    );
  }
}
