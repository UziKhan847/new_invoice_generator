import 'package:flutter/material.dart';
import 'package:new_invoice_generator/models/invoice_item.dart';

class InvoiceItemRow extends StatelessWidget {
  final InvoiceItem item;
  const InvoiceItemRow({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: .spaceBetween,
      children: [
        Expanded(child: Text(item.description)),
        Text('${item.quantity} x'),
        Text(item.unitPrice.toStringAsFixed(2)),
        Text(item.total.toStringAsFixed(2)),
      ],
    );
  }
}