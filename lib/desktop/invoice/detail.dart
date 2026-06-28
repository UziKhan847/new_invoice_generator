import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:new_invoice_generator/app_theme.dart';
import 'package:new_invoice_generator/desktop/invoice/document_view.dart';
import 'package:new_invoice_generator/desktop/widgets.dart';
import 'package:new_invoice_generator/models/customer.dart';
import 'package:new_invoice_generator/models/invoice/invoice.dart';
import 'package:new_invoice_generator/providers/company.dart';
import 'package:new_invoice_generator/providers/customer.dart';
import 'package:new_invoice_generator/providers/invoice/event.dart';
import 'package:new_invoice_generator/providers/invoice/invoice.dart';
import 'package:new_invoice_generator/screens/invoice/create/create.dart';
import 'package:new_invoice_generator/screens/invoice/widgets/email_dialog.dart';
import 'package:new_invoice_generator/screens/invoice/widgets/mark_paid_dialog.dart';
import 'package:new_invoice_generator/services/download.dart';
import 'package:new_invoice_generator/services/receipt_pdf.dart';

/// Full desktop invoice viewer: the document on the left, a status + activity
/// rail on the right. Pushed as its own route.
class DesktopInvoiceDetail extends ConsumerWidget {
  final String invoiceId;
  const DesktopInvoiceDetail({super.key, required this.invoiceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = AppColors.of(context);
    final invoicesAsync = ref.watch(invoiceProvider);

    return Scaffold(
      backgroundColor: p.background,
      body: SafeArea(
        child: invoicesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (all) {
            Invoice? invoice;
            for (final i in all) {
              if (i.id == invoiceId) {
                invoice = i;
                break;
              }
            }
            if (invoice == null) {
              return const Center(child: Text('Invoice not found'));
            }
            final inv = invoice;
            final company = ref.watch(companyProvider).asData?.value;
            final customer = _resolveCustomer(ref, inv.customerId);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DesktopTopBar(
                  leading: _IconBtn(
                    icon: Icons.arrow_back,
                    onTap: () => Navigator.maybePop(context),
                  ),
                  title: 'Invoice ${inv.invoiceNumber}',
                  subtitle:
                      '${inv.customerName} · \$${inv.total.toStringAsFixed(2)}',
                  actions: [
                    _OutlineBtn(
                      icon: Icons.edit_outlined,
                      label: 'Edit',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              CreateInvoiceScreen(editingInvoice: inv),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _OutlineBtn(
                      icon: Icons.delete_outline,
                      label: 'Delete',
                      danger: true,
                      onTap: () => _confirmDelete(context, ref, inv),
                    ),
                  ],
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Document
                        Expanded(
                          flex: 3,
                          child: InvoiceDocumentView(
                            invoice: inv,
                            company: company,
                            customer: customer,
                          ),
                        ),
                        const SizedBox(width: 20),
                        // Right rail
                        SizedBox(
                          width: 300,
                          child: Column(
                            children: [
                              _StatusCard(invoice: inv),
                              const SizedBox(height: 16),
                              _ActivityCard(invoice: inv),
                              const SizedBox(height: 16),
                              if (!inv.isPaid)
                                _RailButton(
                                  icon: Icons.check_circle_outline,
                                  label: 'Mark as paid',
                                  filled: true,
                                  onTap: () async {
                                    await showMarkPaidDialog(
                                      context: context,
                                      ref: ref,
                                      invoice: inv,
                                    );
                                    ref.invalidate(
                                      invoiceEventsProvider(inv.id ?? ''),
                                    );
                                  },
                                ),
                              if (inv.isPaid)
                                _RailButton(
                                  icon: Icons.receipt_long,
                                  label: 'Generate receipt',
                                  filled: true,
                                  onTap: () =>
                                      ReceiptPdfService.generateReceipt(inv),
                                ),
                              const SizedBox(height: 8),
                              _RailButton(
                                icon: Icons.email_outlined,
                                label: 'Email invoice',
                                onTap: () => showEmailInvoiceDialog(
                                  context: context,
                                  invoice: inv,
                                  company: company,
                                  customer: customer,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _RailButton(
                                icon: Icons.download_outlined,
                                label: 'Download PDF',
                                onTap: () => DownloadService.downloadInvoice(
                                  context: context,
                                  invoice: inv,
                                  company: company,
                                  customer: customer,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _RailButton(
                                icon: Icons.copy_outlined,
                                label: 'Duplicate',
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        CreateInvoiceScreen(prefill: inv),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
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
      await ref.read(invoiceProvider.notifier).deleteInvoice(inv.id!);
      if (context.mounted) Navigator.maybePop(context);
    }
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
}

class _StatusCard extends StatelessWidget {
  final Invoice invoice;
  const _StatusCard({required this.invoice});

  @override
  Widget build(BuildContext context) {
    final p = AppColors.of(context);
    final paid = invoice.isPaid;
    final method = switch (invoice.paymentMethod) {
      'stripe' => 'Card',
      'other' => 'Other',
      _ => 'E-Transfer',
    };
    final settled = invoice.issueDate.toIso8601String().split('T').first;

    return DesktopPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('STATUS', style: AppTypography.label(p.textTertiary)),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                Icons.circle,
                size: 9,
                color: paid ? p.successText : p.warningText,
              ),
              const SizedBox(width: 8),
              Text(
                paid ? 'Paid' : 'Unpaid',
                style: AppTypography.title(
                  paid ? p.successText : p.warningText,
                ).copyWith(fontSize: 17),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            paid
                ? 'Settled $settled · $method'
                : 'Awaiting payment via $method',
            style: AppTypography.bodyMuted(p.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _ActivityCard extends ConsumerWidget {
  final Invoice invoice;
  const _ActivityCard({required this.invoice});

  Color _colorFor(String type, AppPalette p) => switch (type) {
    'paid' => p.successText,
    'sent' => p.purple,
    'viewed' => p.primary,
    'downloaded' => p.warningText,
    _ => p.textTertiary,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = AppColors.of(context);
    final id = invoice.id ?? '';
    final eventsAsync = ref.watch(invoiceEventsProvider(id));

    // Build the event list: prefer the real log; fall back to synthesizing
    // from dates when the log is empty (older invoices) or still loading.
    List<_Event> events = eventsAsync.maybeWhen(
      data: (log) => log
          .map((e) => _Event(e.label, e.createdAt, _colorFor(e.type, p)))
          .toList(),
      orElse: () => [],
    );

    if (events.isEmpty) {
      final created = invoice.issueDate;
      events = <_Event>[
        _Event('Invoice created', created, p.textTertiary),
        _Event('Invoice sent', created, p.purple),
        if (invoice.dueDate != null)
          _Event('Payment due', invoice.dueDate!, p.warningText),
        if (invoice.isPaid)
          _Event('Payment received', invoice.dueDate ?? created, p.successText),
      ]..sort((a, b) => b.date.compareTo(a.date));
    }

    return DesktopPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ACTIVITY', style: AppTypography.label(p.textTertiary)),
          const SizedBox(height: 14),
          ...List.generate(events.length, (i) {
            final e = events[i];
            final last = i == events.length - 1;
            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      Container(
                        width: 9,
                        height: 9,
                        margin: const EdgeInsets.only(top: 4),
                        decoration: BoxDecoration(
                          color: e.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      if (!last)
                        Expanded(child: Container(width: 1.5, color: p.border)),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Padding(
                    padding: EdgeInsets.only(bottom: last ? 0 : 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          e.label,
                          style: AppTypography.body(
                            p.ink,
                          ).copyWith(fontSize: 13),
                        ),
                        Text(
                          _fmt(e.date),
                          style: AppTypography.numeric(p.textTertiary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  static String _fmt(DateTime d) {
    final date = d.toIso8601String().split('T').first;
    final hh = d.hour.toString().padLeft(2, '0');
    final mm = d.minute.toString().padLeft(2, '0');
    return '$date · $hh:$mm';
  }
}

class _Event {
  final String label;
  final DateTime date;
  final Color color;
  _Event(this.label, this.date, this.color);
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _IconBtn({required this.icon, required this.onTap});
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

class _RailButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool filled;
  const _RailButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    if (filled) {
      return SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: onTap,
          icon: Icon(icon, size: 18),
          label: Text(label),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      );
    }
    final p = AppColors.of(context);
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Align(alignment: Alignment.centerLeft, child: Text(label)),
        style: OutlinedButton.styleFrom(
          foregroundColor: p.ink,
          side: BorderSide(color: p.border, width: 1.5),
          padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 14),
          alignment: Alignment.centerLeft,
        ),
      ),
    );
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
