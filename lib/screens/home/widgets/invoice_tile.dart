import 'package:flutter/material.dart';
import 'package:new_invoice_generator/models/invoice/invoice.dart';
import 'package:new_invoice_generator/screens/invoice/detail.dart';
import 'package:new_invoice_generator/screens/invoice/widgets/status_badge.dart';

class HomeInvoiceTile extends StatelessWidget {
  final Invoice invoice;
  const HomeInvoiceTile({super.key, required this.invoice});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => InvoiceDetailScreen(invoiceId: invoice.id!)),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        padding: const EdgeInsets.fromLTRB(14, 10, 12, 10),
        decoration: BoxDecoration(
          color: cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cs.outlineVariant.withAlpha(60)),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: invoice.isPaid
                    ? Colors.green.withAlpha(25)
                    : cs.primary.withAlpha(25),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                invoice.isPaid
                    ? Icons.check_circle_outline
                    : Icons.receipt_long,
                color: invoice.isPaid ? Colors.green : cs.primary,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(invoice.invoiceNumber,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 13)),
                      Text('\$${invoice.total.toStringAsFixed(2)}',
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 14)),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(invoice.customerName,
                          style: TextStyle(
                              fontSize: 12,
                              color: cs.onSurface.withAlpha(170))),
                      StatusBadge(isPaid: invoice.isPaid),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}