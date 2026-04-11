import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:new_invoice_generator/models/invoice.dart';
import 'package:new_invoice_generator/providers/company.dart';
import 'package:new_invoice_generator/providers/invoice.dart';
import 'package:new_invoice_generator/services/email.dart';
import 'package:new_invoice_generator/services/pdf.dart';
import 'package:new_invoice_generator/services/download.dart';
import 'package:new_invoice_generator/services/storage.dart';
import 'package:printing/printing.dart';
import 'package:new_invoice_generator/services/receipt_pdf.dart';

class InvoiceDetailScreen extends ConsumerWidget {
  final String invoiceId;
  const InvoiceDetailScreen({super.key, required this.invoiceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invoicesAsync = ref.watch(invoiceProvider);

    return invoicesAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (invoices) {
        final Invoice? invoice = invoices.cast<Invoice?>().firstWhere(
              (i) => i?.id == invoiceId,
              orElse: () => null,
            );

        if (invoice == null) {
          return const Scaffold(body: Center(child: Text('Invoice not found')));
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(invoice.invoiceNumber),
            actions: [
              IconButton(
                icon: const Icon(Icons.email_outlined),
                tooltip: 'Email invoice',
                onPressed: () async {
                  final company = await ref.read(companyProvider.future);
                  final storagePath = company['logo_storage_path'] as String?;
                  String? logoUrl;
                  if (storagePath != null) {
                    logoUrl = await StorageService.getFreshLogoUrl(storagePath);
                  }
                  logoUrl ??= company['logo_url'] as String?;
                  if (context.mounted) {
                    _showEmailDialog(context, invoice, logoUrl: logoUrl);
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.visibility_outlined),
                tooltip: 'Preview PDF',
                onPressed: () async {
                  final company = await ref.read(companyProvider.future);
                  final storagePath = company['logo_storage_path'] as String?;
                  String? logoUrl;
                  if (storagePath != null) {
                    logoUrl = await StorageService.getFreshLogoUrl(storagePath);
                  }
                  logoUrl ??= company['logo_url'] as String?;
                  final inv = logoUrl != null
                      ? invoice.copyWith(companyLogoUrl: logoUrl)
                      : invoice;
                  if (context.mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => _PdfPreviewScreen(invoice: inv),
                      ),
                    );
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.download_outlined),
                tooltip: 'Save to device',
                onPressed: () async {
                  final company = await ref.read(companyProvider.future);
                  final storagePath = company['logo_storage_path'] as String?;
                  String? logoUrl;
                  if (storagePath != null) {
                    logoUrl = await StorageService.getFreshLogoUrl(storagePath);
                  }
                  logoUrl ??= company['logo_url'] as String?;
                  if (context.mounted) {
                    await DownloadService.downloadInvoice(
                      context: context,
                      invoice: invoice,
                      companyLogoUrl: logoUrl,
                    );
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.print_outlined),
                tooltip: 'Print',
                onPressed: () async {
                  final company = await ref.read(companyProvider.future);
                  final storagePath = company['logo_storage_path'] as String?;
                  String? logoUrl;
                  if (storagePath != null) {
                    logoUrl = await StorageService.getFreshLogoUrl(storagePath);
                  }
                  logoUrl ??= company['logo_url'] as String?;
                  await PdfService.generateInvoicePdf(
                    logoUrl != null
                        ? invoice.copyWith(companyLogoUrl: logoUrl)
                        : invoice,
                  );
                },
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(invoice.customerName,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(fontWeight: FontWeight.bold)),
                          _StatusBadge(isPaid: invoice.isPaid),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('Issued: ${invoice.issueDate.toLocal().toString().split(' ')[0]}'),
                      if (invoice.dueDate != null)
                        Text('Due: ${invoice.dueDate!.toLocal().toString().split(' ')[0]}'),
                    ],
                  ),
                ),
              ),
              // Sender / e-transfer card
              if (invoice.senderName != null) ...[
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Sent by',
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              child: Text(
                                  invoice.senderName![0].toUpperCase()),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(invoice.senderName!,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600)),
                                  if (invoice.senderRole != null)
                                    Text(invoice.senderRole!,
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface
                                                .withAlpha(150))),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (invoice.senderEmail != null &&
                            invoice.senderEmail!.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.green.withAlpha(20),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: Colors.green.withAlpha(60)),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                    Icons.account_balance_wallet_outlined,
                                    size: 16,
                                    color: Colors.green),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text('E-Transfer to',
                                          style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.green,
                                              fontWeight: FontWeight.w500)),
                                      Text(invoice.senderEmail!,
                                          style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.green)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Items',
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      const Divider(),
                      ...invoice.items.map(
                        (item) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            children: [
                              Expanded(child: Text(item.description)),
                              Text('x${item.quantity}  \$${item.unitPrice.toStringAsFixed(2)}'),
                              const SizedBox(width: 16),
                              Text('\$${item.total.toStringAsFixed(2)}',
                                  style: const TextStyle(fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                      const Divider(),
                      _TotalRow(label: 'Pre-discount Subtotal',
                          value: invoice.taxableSubtotal),
                      if (invoice.totalDiscountAmount > 0) ...[
                        _TotalRow(
                          label: 'Total Discounts',
                          value: invoice.totalDiscountAmount,
                          prefix: '−',
                          color: Colors.green,
                        ),
                        _TotalRow(label: 'After discounts',
                            value: invoice.subtotal),
                      ],
                      _TotalRow(
                        label: 'Tax (13% on \\${invoice.taxableSubtotal.toStringAsFixed(2)})',
                        value: invoice.tax,
                      ),
                      const SizedBox(height: 4),
                      _TotalRow(label: 'Total', value: invoice.total, bold: true),
                    ],
                  ),
                ),
              ),
              // ── Notes ─────────────────────────────────────────
              if (invoice.notes != null && invoice.notes!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.notes_outlined, size: 16),
                            SizedBox(width: 8),
                            Text('Notes & Payment Terms',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          invoice.notes!,
                          style: TextStyle(
                              fontSize: 13,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withAlpha(180)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              if (!invoice.isPaid)
                ElevatedButton.icon(
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Mark as Paid'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(48),
                  ),
                  onPressed: () =>
                      ref.read(invoiceProvider.notifier).markPaid(invoice.id!),
                ),
              if (invoice.isPaid) ...[
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  icon: const Icon(Icons.receipt_outlined),
                  label: const Text('Generate Receipt'),
                  style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                  onPressed: () async => ReceiptPdfService.generateReceipt(invoice),
                ),
              ],
              // ── Duplicate invoice ─────────────────────────────
              const SizedBox(height: 8),
              OutlinedButton.icon(
                icon: const Icon(Icons.copy_outlined),
                label: const Text('Duplicate Invoice'),
                style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48)),
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Duplicate invoice?'),
                      content: const Text(
                          'Creates a new unpaid invoice with the same items, '
                          'customer, and sender. Today will be the issue date.'),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel')),
                        ElevatedButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Duplicate')),
                      ],
                    ),
                  );
                  if (confirm == true && context.mounted) {
                    await ref
                        .read(invoiceProvider.notifier)
                        .duplicateInvoice(invoice);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context)
                        ..clearSnackBars()
                        ..showSnackBar(const SnackBar(
                            content: Text('Invoice duplicated successfully!')));
                    }
                  }
                },
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                icon: const Icon(Icons.delete_outline),
                label: const Text('Delete Invoice'),
                style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    minimumSize: const Size.fromHeight(48)),
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Delete invoice?'),
                      content: const Text('This cannot be undone.'),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel')),
                        ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Delete',
                                style: TextStyle(color: Colors.white))),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await ref.read(invoiceProvider.notifier).deleteInvoice(invoice.id!);
                    if (context.mounted) Navigator.pop(context);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showEmailDialog(BuildContext context, Invoice invoice, {String? logoUrl}) {
    final emailCtrl = TextEditingController(text: invoice.customerEmail ?? '');
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Email Invoice'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (invoice.customerEmail != null) ...[
              Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 14),
                  const SizedBox(width: 6),
                  Text('Auto-filled from customer',
                      style: TextStyle(fontSize: 12, color: Colors.green.shade700)),
                ],
              ),
              const SizedBox(height: 8),
            ],
            TextField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Recipient email',
                hintText: 'customer@example.com',
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue.withAlpha(15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withAlpha(40)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Icon(Icons.info_outline, size: 14, color: Colors.blue),
                    SizedBox(width: 6),
                    Text('How it works', style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.bold,
                        color: Colors.blue)),
                  ]),
                  SizedBox(height: 6),
                  Text(
                    '1. Your mail app opens with the recipient pre-filled.\n'
                    '2. A share sheet opens — pick your mail app again to attach the PDF.\n'
                    '3. Hit send.',
                    style: TextStyle(fontSize: 11, color: Colors.blue),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton.icon(
            icon: const Icon(Icons.send_outlined, size: 16),
            label: const Text('Send'),
            onPressed: () async {
              if (emailCtrl.text.trim().isEmpty) return;
              Navigator.pop(context);
              await EmailService.emailInvoice(
                context: context,
                invoice: invoice,
                recipientEmail: emailCtrl.text.trim(),
                companyLogoUrl: logoUrl,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool isPaid;
  const _StatusBadge({required this.isPaid});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isPaid ? Colors.green.withAlpha(25) : Colors.orange.withAlpha(25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isPaid ? Colors.green : Colors.orange),
      ),
      child: Text(
        isPaid ? 'Paid' : 'Unpaid',
        style: TextStyle(
          color: isPaid ? Colors.green : Colors.orange,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  final String label;
  final double value;
  final bool bold;
  final Color? color;
  final String prefix;
  const _TotalRow({
    required this.label,
    required this.value,
    this.bold = false,
    this.color,
    this.prefix = r'$',
  });

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontWeight: bold ? FontWeight.bold : FontWeight.normal,
      fontSize: bold ? 16 : 13,
      color: color,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(label, style: style, overflow: TextOverflow.ellipsis),
          ),
          Text('$prefix${value.toStringAsFixed(2)}', style: style),
        ],
      ),
    );
  }
}


// ── PDF Preview Screen ────────────────────────────────────────────────────────
class _PdfPreviewScreen extends StatelessWidget {
  final Invoice invoice;
  const _PdfPreviewScreen({required this.invoice});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Invoice ${invoice.invoiceNumber}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.print_outlined),
            tooltip: 'Print / Download',
            onPressed: () async {
              final bytes = await PdfService.buildPdfBytes(invoice);
              await Printing.layoutPdf(onLayout: (_) async => bytes);
            },
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Share PDF',
            onPressed: () async {
              final bytes = await PdfService.buildPdfBytes(invoice);
              await Printing.sharePdf(
                bytes: bytes,
                filename: 'invoice_${invoice.invoiceNumber}.pdf',
              );
            },
          ),
        ],
      ),
      body: PdfPreview(
        // Renders the PDF inline — zoomable, scrollable
        build: (format) => PdfService.buildPdfBytes(invoice),
        allowPrinting: false,   // handled by app bar button above
        allowSharing: false,    // handled by app bar button above
        canChangeOrientation: false,
        canChangePageFormat: false,
        canDebug: false,
        pdfFileName: 'invoice_${invoice.invoiceNumber}.pdf',
      ),
    );
  }
}