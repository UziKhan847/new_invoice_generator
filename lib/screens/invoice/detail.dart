import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:new_invoice_generator/models/invoice.dart';
import 'package:new_invoice_generator/providers/company.dart';
import 'package:new_invoice_generator/providers/invoice.dart';
import 'package:new_invoice_generator/services/email.dart';
import 'package:new_invoice_generator/services/pdf.dart';
import 'package:new_invoice_generator/services/storage.dart';
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
                onPressed: () => _showEmailDialog(context, invoice),
              ),
              IconButton(
                icon: const Icon(Icons.picture_as_pdf_outlined),
                tooltip: 'Generate PDF',
                onPressed: () async {
                  final company = await ref.read(companyProvider.future);
                  // Try signed URL first, fall back to logo_url in state
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
            padding: const .all(16),
            children: [
              Card(
                child: Padding(
                  padding: const .all(16),
                  child: Column(
                    crossAxisAlignment: .start,
                    children: [
                      Row(
                        mainAxisAlignment: .spaceBetween,
                        children: [
                          Text(
                            invoice.customerName,
                            style: Theme.of(
                              context,
                            ).textTheme.titleLarge?.copyWith(fontWeight: .bold),
                          ),
                          _StatusBadge(isPaid: invoice.isPaid),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Issued: ${invoice.issueDate.toLocal().toString().split(' ')[0]}',
                      ),
                      if (invoice.dueDate != null)
                        Text(
                          'Due: ${invoice.dueDate!.toLocal().toString().split(' ')[0]}',
                        ),
                    ],
                  ),
                ),
              ),
              // Sender / e-transfer card
              if (invoice.senderName != null) ...[
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const .all(16),
                    child: Column(
                      crossAxisAlignment: .start,
                      children: [
                        Text(
                          'Sent by',
                          style: Theme.of(
                            context,
                          ).textTheme.titleSmall?.copyWith(fontWeight: .bold),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              child: Text(invoice.senderName![0].toUpperCase()),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: .start,
                                children: [
                                  Text(
                                    invoice.senderName!,
                                    style: const TextStyle(fontWeight: .w600),
                                  ),
                                  if (invoice.senderRole != null)
                                    Text(
                                      invoice.senderRole!,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurface.withAlpha(150),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (invoice.senderEmail != null &&
                            invoice.senderEmail!.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const .symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withAlpha(20),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.green.withAlpha(60),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.account_balance_wallet_outlined,
                                  size: 16,
                                  color: Colors.green,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: .start,
                                    children: [
                                      const Text(
                                        'E-Transfer to',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.green,
                                          fontWeight: .w500,
                                        ),
                                      ),
                                      Text(
                                        invoice.senderEmail!,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: .bold,
                                          color: Colors.green,
                                        ),
                                      ),
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
                  padding: const .all(16),
                  child: Column(
                    crossAxisAlignment: .start,
                    children: [
                      Text(
                        'Items',
                        style: Theme.of(
                          context,
                        ).textTheme.titleSmall?.copyWith(fontWeight: .bold),
                      ),
                      const Divider(),
                      ...invoice.items.map(
                        (item) => Padding(
                          padding: const .symmetric(vertical: 6),
                          child: Row(
                            children: [
                              Expanded(child: Text(item.description)),
                              Text(
                                'x${item.quantity}  \$${item.unitPrice.toStringAsFixed(2)}',
                              ),
                              const SizedBox(width: 16),
                              Text(
                                '\$${item.total.toStringAsFixed(2)}',
                                style: const TextStyle(fontWeight: .w600),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Divider(),
                      _TotalRow(label: 'Subtotal', value: invoice.subtotal),
                      _TotalRow(label: 'Tax (13%)', value: invoice.tax),
                      const SizedBox(height: 4),
                      _TotalRow(
                        label: 'Total',
                        value: invoice.total,
                        bold: true,
                      ),
                    ],
                  ),
                ),
              ),
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
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                  onPressed: () async =>
                      ReceiptPdfService.generateReceipt(invoice),
                ),
              ],
              const SizedBox(height: 8),
              OutlinedButton.icon(
                icon: const Icon(Icons.delete_outline),
                label: const Text('Delete Invoice'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  minimumSize: const Size.fromHeight(48),
                ),
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Delete invoice?'),
                      content: const Text('This cannot be undone.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text(
                            'Delete',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await ref
                        .read(invoiceProvider.notifier)
                        .deleteInvoice(invoice.id!);
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

  void _showEmailDialog(BuildContext context, Invoice invoice) {
    // Pre-fill with customer email if available
    final emailCtrl = TextEditingController(text: invoice.customerEmail ?? '');
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Email Invoice'),
        content: Column(
          mainAxisSize: .min,
          crossAxisAlignment: .start,
          children: [
            if (invoice.customerEmail != null)
              Padding(
                padding: const .only(bottom: 8),
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
              decoration: const InputDecoration(
                labelText: 'Recipient email',
                hintText: 'customer@example.com',
              ),
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
              await EmailService.emailInvoice(
                context: context,
                invoice: invoice,
                recipientEmail: emailCtrl.text.trim(),
              );
            },
            child: const Text('Send'),
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
      padding: const .symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isPaid
            ? Colors.green.withAlpha(25)
            : Colors.orange.withAlpha(25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isPaid ? Colors.green : Colors.orange),
      ),
      child: Text(
        isPaid ? 'Paid' : 'Unpaid',
        style: TextStyle(
          color: isPaid ? Colors.green : Colors.orange,
          fontWeight: .w600,
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
  const _TotalRow({
    required this.label,
    required this.value,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const .symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: .spaceBetween,
        children: [
          Text(label, style: bold ? const TextStyle(fontWeight: .bold) : null),
          Text(
            '\$${value.toStringAsFixed(2)}',
            style: bold
                ? const TextStyle(fontWeight: .bold, fontSize: 16)
                : null,
          ),
        ],
      ),
    );
  }
}
