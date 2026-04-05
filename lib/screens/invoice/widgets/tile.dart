import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:new_invoice_generator/models/invoice.dart';
import 'package:new_invoice_generator/providers/company.dart';
import 'package:new_invoice_generator/providers/invoice.dart';
import 'package:new_invoice_generator/screens/invoice/detail.dart';
import 'package:new_invoice_generator/screens/invoice/widgets/quick_menu.dart';
import 'package:new_invoice_generator/screens/invoice/widgets/status_badge.dart';
import 'package:new_invoice_generator/services/storage.dart';

class InvoiceTile extends ConsumerWidget {
  final Invoice invoice;
  const InvoiceTile({super.key, required this.invoice});

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
    final isPaid = invoice.isPaid;

    return Dismissible(
      key: ValueKey(invoice.id),
      direction: .endToStart,
      confirmDismiss: (_) => showDialog<bool>(
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
      ),
      onDismissed: (_) {
        ref.read(invoiceProvider.notifier).deleteInvoice(invoice.id!);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invoice ${invoice.invoiceNumber} deleted')),
        );
      },
      background: Container(
        margin: const .only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: .circular(14),
        ),
        alignment: .centerRight,
        padding: const .only(right: 20),
        child: const Column(
          mainAxisAlignment: .center,
          children: [
            Icon(Icons.delete_outline, color: Colors.white, size: 22),
            SizedBox(height: 4),
            Text(
              'Delete',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: .w600,
              ),
            ),
          ],
        ),
      ),
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => InvoiceDetailScreen(invoiceId: invoice.id!),
          ),
        ),
        child: Container(
          margin: const .only(bottom: 10),
          decoration: BoxDecoration(
            color: cs.surfaceContainerLow,
            borderRadius: .circular(14),
            border: .all(color: cs.outlineVariant.withAlpha(60)),
          ),
          child: Padding(
            padding: const .fromLTRB(14, 12, 8, 12),
            child: Row(
              crossAxisAlignment: .center,
              children: [
                // ── Leading icon ────────────────────────────────────
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isPaid
                        ? Colors.green.withAlpha(25)
                        : cs.primary.withAlpha(25),
                    borderRadius: .circular(10),
                  ),
                  child: Icon(
                    isPaid ? Icons.check_circle_outline : Icons.receipt_long,
                    color: isPaid ? Colors.green : cs.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),

                // ── Main content ─────────────────────────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: .start,
                    children: [
                      // Row 1: invoice number + amount
                      Row(
                        mainAxisAlignment: .spaceBetween,
                        children: [
                          Text(
                            invoice.invoiceNumber,
                            style: TextStyle(
                              fontWeight: .w700,
                              fontSize: 14,
                              color: cs.onSurface,
                            ),
                          ),
                          Text(
                            '\$${invoice.total.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontWeight: .w700,
                              fontSize: 15,
                              color: cs.onSurface,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),

                      // Row 2: customer + status badge
                      Row(
                        mainAxisAlignment: .spaceBetween,
                        crossAxisAlignment: .center,
                        children: [
                          Expanded(
                            child: Text(
                              invoice.customerName,
                              style: TextStyle(
                                fontSize: 13,
                                color: cs.onSurface.withAlpha(170),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          StatusBadge(isPaid: isPaid),
                        ],
                      ),

                      // Row 3: sender (optional) + date
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          if (invoice.senderName != null) ...[
                            Icon(
                              Icons.person_outline,
                              size: 11,
                              color: cs.onSurface.withAlpha(110),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              invoice.senderName!,
                              style: TextStyle(
                                fontSize: 11,
                                color: cs.onSurface.withAlpha(130),
                              ),
                            ),
                            const SizedBox(width: 10),
                          ],
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 11,
                            color: cs.onSurface.withAlpha(110),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            invoice.issueDate.toLocal().toString().split(
                              ' ',
                            )[0],
                            style: TextStyle(
                              fontSize: 11,
                              color: cs.onSurface.withAlpha(130),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),

                // ── Quick menu ────────────────────────────────────────
                InvoiceQuickMenu(
                  invoice: invoice,
                  getLogoUrl: () => _getLogoUrl(ref),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
