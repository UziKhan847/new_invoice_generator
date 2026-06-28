import 'package:flutter/material.dart';
import 'package:new_invoice_generator/models/invoice/item.dart';
import 'package:new_invoice_generator/screens/invoice/create/widgets/invoice_form_helpers.dart';

class ItemsSummarySection extends StatelessWidget {
  final List<InvoiceItem> items;
  final String taxLabel;
  final double taxableSubtotal;
  final double totalDiscounts;
  final double subtotal;
  final double tax;
  final double total;
  final void Function(InvoiceItem) onRemove;

  const ItemsSummarySection({
    super.key,
    required this.items,
    required this.taxLabel,
    required this.taxableSubtotal,
    required this.totalDiscounts,
    required this.subtotal,
    required this.tax,
    required this.total,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return SectionCard(
      title: 'Items',
      child: Column(
        children: [
          ...items.map((item) => _ItemRow(
                item: item,
                onRemove: () => onRemove(item),
              )),
          const Divider(height: 20),
          TotalLine(
              label: 'Pre-discount Subtotal',
              value: '\$${taxableSubtotal.toStringAsFixed(2)}'),
          if (totalDiscounts > 0) ...[
            TotalLine(
                label: 'Total Discounts',
                value: '−\$${totalDiscounts.toStringAsFixed(2)}',
                color: Colors.green),
            TotalLine(
                label: 'After discounts',
                value: '\$${subtotal.toStringAsFixed(2)}'),
          ],
          TotalLine(
              label: '$taxLabel on \$${taxableSubtotal.toStringAsFixed(2)}',
              value: '\$${tax.toStringAsFixed(2)}'),
          const SizedBox(height: 4),
          TotalLine(
              label: 'Total',
              value: '\$${total.toStringAsFixed(2)}',
              bold: true),
        ],
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  final InvoiceItem item;
  final VoidCallback onRemove;
  const _ItemRow({required this.item, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.description,
                    style:
                        const TextStyle(fontWeight: FontWeight.w500)),
                Text(
                  'x${item.quantityDisplay}  ×  \$${item.unitPrice.toStringAsFixed(2)}',
                  style: TextStyle(
                      fontSize: 12,
                      color: cs.onSurface.withAlpha(150)),
                ),
                if (item.hasDiscount)
                  Text(
                    '− ${item.discountLabel}  (−\$${item.discountAmount.toStringAsFixed(2)})',
                    style: const TextStyle(
                        fontSize: 11,
                        color: Colors.green,
                        fontWeight: FontWeight.w500),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (item.hasDiscount)
                Text(
                  '\$${item.subtotal.toStringAsFixed(2)}',
                  style: TextStyle(
                      fontSize: 11,
                      color: cs.onSurface.withAlpha(120),
                      decoration: TextDecoration.lineThrough),
                ),
              Text('\$${item.total.toStringAsFixed(2)}',
                  style:
                      const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline,
                size: 18, color: Colors.red),
            onPressed: onRemove,
            padding: const EdgeInsets.only(left: 4),
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}