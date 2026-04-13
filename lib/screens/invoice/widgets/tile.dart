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
  final bool isSelecting;
  final bool isSelected;
  final VoidCallback? onLongPress;
  final VoidCallback? onToggleSelect;

  const InvoiceTile({
    super.key,
    required this.invoice,
    this.isSelecting = false,
    this.isSelected = false,
    this.onLongPress,
    this.onToggleSelect,
  });

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

    // In selection mode: no swipe-to-delete, tap toggles selection
    if (isSelecting) {
      return _buildTileContent(
        context: context,
        ref: ref,
        cs: cs,
        isPaid: isPaid,
        onTap: onToggleSelect,
        onLongPress: null,
      );
    }

    return Dismissible(
      key: ValueKey(invoice.id),
      direction: DismissDirection.endToStart,
      // confirmDismiss handles BOTH the confirmation dialog AND the actual delete.
      // This avoids "Paused on Exception" caused by calling async deleteInvoice
      // inside the sync onDismissed callback on an already-dismissed widget.
      confirmDismiss: (_) async {
        final confirmed = await showDialog<bool>(
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
        if (confirmed == true) {
          await ref.read(invoiceProvider.notifier).deleteInvoice(invoice.id!);
          if (context.mounted) {
            ScaffoldMessenger.of(context)
              ..clearSnackBars()
              ..showSnackBar(
                SnackBar(
                  content: Text('Invoice ${invoice.invoiceNumber} deleted'),
                  duration: const Duration(seconds: 4),
                ),
              );
          }
          return true; // allow dismissal
        }
        return false; // cancel dismissal
      },
      onDismissed: (_) {}, // actual work done in confirmDismiss
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
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      child: _buildTileContent(
        context: context,
        ref: ref,
        cs: cs,
        isPaid: isPaid,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => InvoiceDetailScreen(invoiceId: invoice.id!),
          ),
        ),
        onLongPress: onLongPress,
      ),
    );
  }

  Widget _buildTileContent({
    required BuildContext context,
    required WidgetRef ref,
    required ColorScheme cs,
    required bool isPaid,
    VoidCallback? onTap,
    VoidCallback? onLongPress,
  }) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const .only(bottom: 10),
        decoration: BoxDecoration(
          color: isSelected ? cs.primary.withAlpha(30) : cs.surfaceContainerLow,
          borderRadius: .circular(14),
          border: .all(
            color: isSelected ? cs.primary : cs.outlineVariant.withAlpha(60),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Padding(
          padding: const .fromLTRB(14, 12, 8, 12),
          child: Row(
            crossAxisAlignment: .center,
            children: [
              // Selection checkbox or status icon
              if (isSelecting)
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 150),
                  child: isSelected
                      ? CircleAvatar(
                          key: const ValueKey('checked'),
                          radius: 20,
                          backgroundColor: cs.primary,
                          child: const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 18,
                          ),
                        )
                      : CircleAvatar(
                          key: const ValueKey('unchecked'),
                          radius: 20,
                          backgroundColor: cs.outline.withAlpha(40),
                          child: const SizedBox.shrink(),
                        ),
                )
              else
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

              // Main content
              Expanded(
                child: Column(
                  crossAxisAlignment: .start,
                  children: [
                    Row(
                      mainAxisAlignment: .spaceBetween,
                      children: [
                        Text(
                          invoice.invoiceNumber,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: cs.onSurface,
                          ),
                        ),
                        Text(
                          '\$${invoice.total.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: cs.onSurface,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
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
                            overflow: .ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        StatusBadge(isPaid: isPaid),
                      ],
                    ),
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
                          invoice.issueDate.toLocal().toString().split(' ')[0],
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

              // Quick menu — hidden in selection mode
              if (!isSelecting)
                InvoiceQuickMenu(
                  invoice: invoice,
                  getLogoUrl: () => _getLogoUrl(ref),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// // ── Payment method pill (shown on tile) ──────────────────────────────────────
// class _PaymentPill extends StatelessWidget {
//   final String method;
//   const _PaymentPill({required this.method});

//   @override
//   Widget build(BuildContext context) {
//     final (label, color, icon) = switch (method) {
//       'stripe' => (
//         'Stripe',
//         const Color(0xFF635BFF),
//         Icons.credit_card_outlined,
//       ),
//       'other' => ('Other', Colors.blueGrey, Icons.payments_outlined),
//       _ => ('E-Transfer', Colors.green, Icons.account_balance_wallet_outlined),
//     };
//     return Container(
//       padding: const .symmetric(horizontal: 5, vertical: 2),
//       decoration: BoxDecoration(
//         color: color.withAlpha(20),
//         borderRadius: .circular(20),
//         border: .all(color: color.withAlpha(80)),
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Icon(icon, size: 9, color: color),
//           const SizedBox(width: 3),
//           Text(
//             label,
//             style: TextStyle(
//               fontSize: 9,
//               fontWeight: FontWeight.w600,
//               color: color,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
