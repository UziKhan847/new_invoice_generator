import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:new_invoice_generator/models/invoice.dart';
import 'package:new_invoice_generator/providers/invoice.dart';
import 'package:new_invoice_generator/screens/invoice/widgets/quick_pdf_preview.dart';
import 'package:new_invoice_generator/services/download.dart';
import 'package:new_invoice_generator/services/email.dart';

enum _Action { markPaid, email, download, preview }

class InvoiceQuickMenu extends ConsumerWidget {
  final Invoice invoice;
  final Future<String?> Function() getLogoUrl;

  const InvoiceQuickMenu({
    super.key,
    required this.invoice,
    required this.getLogoUrl,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;

    return PopupMenuButton<_Action>(
      icon: Icon(Icons.more_vert, size: 20, color: cs.onSurface.withAlpha(140)),
      padding: EdgeInsets.zero,
      tooltip: 'Quick actions',
      onSelected: (action) async {
        switch (action) {
          case _Action.markPaid:
            final confirm = await showDialog<bool>(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text('Mark as paid?'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel')),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green),
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Mark Paid',
                        style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            );
            if (confirm == true && context.mounted) {
              await ref
                  .read(invoiceProvider.notifier)
                  .markPaid(invoice.id!);
            }

          case _Action.email:
            if (context.mounted) _showEmailDialog(context);

          case _Action.download:
            final logoUrl = await getLogoUrl();
            if (context.mounted) {
              await DownloadService.downloadInvoice(
                context: context,
                invoice: invoice,
                companyLogoUrl: logoUrl,
              );
            }

          case _Action.preview:
            final logoUrl = await getLogoUrl();
            final inv = logoUrl != null
                ? invoice.copyWith(companyLogoUrl: logoUrl)
                : invoice;
            if (context.mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => QuickPdfPreview(invoice: inv)),
              );
            }
        }
      },
      itemBuilder: (_) => [
        if (!invoice.isPaid)
          const PopupMenuItem(
            value: _Action.markPaid,
            child: _MenuItem(
                icon: Icons.check_circle_outline,
                label: 'Mark as Paid',
                color: Colors.green),
          ),
        const PopupMenuItem(
          value: _Action.email,
          child: _MenuItem(icon: Icons.email_outlined, label: 'Email'),
        ),
        const PopupMenuItem(
          value: _Action.download,
          child: _MenuItem(icon: Icons.download_outlined, label: 'Download'),
        ),
        const PopupMenuItem(
          value: _Action.preview,
          child: _MenuItem(
              icon: Icons.visibility_outlined, label: 'Preview PDF'),
        ),
      ],
    );
  }

  void _showEmailDialog(BuildContext context) {
    final emailCtrl =
        TextEditingController(text: invoice.customerEmail ?? '');
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
                    const Icon(Icons.check_circle,
                        color: Colors.green, size: 14),
                    const SizedBox(width: 6),
                    Text('Auto-filled from customer record',
                        style: TextStyle(
                            fontSize: 12,
                            color: Colors.green.shade700)),
                  ],
                ),
              ),
            TextField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration:
                  const InputDecoration(labelText: 'Recipient email'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
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
  const _MenuItem(
      {required this.icon, required this.label, this.color});

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