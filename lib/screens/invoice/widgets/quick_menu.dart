import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:new_invoice_generator/models/invoice/invoice.dart';
import 'package:new_invoice_generator/models/customer.dart';
import 'package:new_invoice_generator/providers/company.dart';
import 'package:new_invoice_generator/providers/customer.dart';
import 'package:new_invoice_generator/screens/invoice/widgets/mark_paid_dialog.dart';
import 'package:new_invoice_generator/screens/invoice/widgets/quick_pdf_preview.dart';
import 'package:new_invoice_generator/services/download.dart';
import 'package:new_invoice_generator/services/email.dart';
import 'package:new_invoice_generator/services/sms.dart';
import 'package:new_invoice_generator/utils/loading_overlay.dart';

enum _Action { markPaid, email, sms, download, preview }

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
    final company = ref.read(companyProvider).asData?.value;
    final customer = () {
      final list = ref.read(customerProvider).asData?.value;
      if (list == null || invoice.customerId == null) return null;
      for (final c in list) {
        if (c.id == invoice.customerId) return c;
      }
      return null;
    }();
    final cs = Theme.of(context).colorScheme;

    return PopupMenuButton<_Action>(
      icon: Icon(Icons.more_vert, size: 20, color: cs.onSurface.withAlpha(140)),
      padding: EdgeInsets.zero,
      tooltip: 'Quick actions',
      onSelected: (action) async {
        switch (action) {
          case _Action.markPaid:
            if (context.mounted) {
              await showMarkPaidDialog(
                context: context,
                ref: ref,
                invoice: invoice,
              );
            }

          case _Action.email:
            if (context.mounted) _showEmailDialog(context, company, customer);

          case _Action.download:
            await withLoadingOverlay(
              context,
              message: 'Saving PDF…',
              task: () async {
                final logoUrl = await getLogoUrl();
                if (!context.mounted) return;
                await DownloadService.downloadInvoice(
                  context: context,
                  invoice: invoice,
                  companyLogoUrl: logoUrl,
                  company: company,
                  customer: customer,
                );
              },
            );

          case _Action.sms:
            if (!context.mounted) return;
            await SmsService.sendInvoiceSms(
              context: context,
              invoice: invoice,
              recipientPhone: invoice.customerPhone!,
            );

          case _Action.preview:
            if (!context.mounted) return;
            final logoUrl = await withLoadingOverlay(
              context,
              message: 'Generating preview…',
              task: () => getLogoUrl(),
            );
            final inv = logoUrl != null
                ? invoice.copyWith(companyLogoUrl: logoUrl)
                : invoice;
            if (context.mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => QuickPdfPreview(
                    invoice: inv,
                    company: company,
                    customer: customer,
                  ),
                ),
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
              color: Colors.green,
            ),
          ),
        const PopupMenuItem(
          value: _Action.email,
          child: _MenuItem(icon: Icons.email_outlined, label: 'Email'),
        ),
        if ((Platform.isAndroid || Platform.isIOS) &&
            invoice.customerPhone != null &&
            invoice.customerPhone!.isNotEmpty)
          const PopupMenuItem(
            value: _Action.sms,
            child: _MenuItem(icon: Icons.sms_outlined, label: 'Send SMS'),
          ),
        const PopupMenuItem(
          value: _Action.download,
          child: _MenuItem(icon: Icons.download_outlined, label: 'Download'),
        ),
        const PopupMenuItem(
          value: _Action.preview,
          child: _MenuItem(
            icon: Icons.visibility_outlined,
            label: 'Preview PDF',
          ),
        ),
      ],
    );
  }

  void _showEmailDialog(
    BuildContext context,
    Map<String, dynamic>? company,
    Customer? customer,
  ) {
    final emailCtrl = TextEditingController(text: invoice.customerEmail ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
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
                      'Auto-filled from customer',
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
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final email = emailCtrl.text.trim();
              await withLoadingOverlay(
                context,
                message: 'Preparing email…',
                task: () async {
                  final logoUrl = await getLogoUrl();
                  if (!context.mounted) return;
                  await EmailService.emailInvoice(
                    context: context,
                    invoice: invoice,
                    recipientEmail: email,
                    companyLogoUrl: logoUrl,
                    company: company,
                    customer: customer,
                  );
                },
              );
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
