import 'package:flutter/material.dart';
import 'package:new_invoice_generator/models/invoice_item.dart';
import 'package:new_invoice_generator/models/service.dart';

class QuickAddServiceDialog extends StatefulWidget {
  final Service service;
  final void Function(InvoiceItem) onAdd;
  const QuickAddServiceDialog(
      {super.key, required this.service, required this.onAdd});

  @override
  State<QuickAddServiceDialog> createState() =>
      _QuickAddServiceDialogState();
}

class _QuickAddServiceDialogState
    extends State<QuickAddServiceDialog> {
  final _qtyCtrl      = TextEditingController(text: '1');
  final _discountCtrl = TextEditingController();
  bool _isPercent = true;

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _discountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final qty  = double.tryParse(_qtyCtrl.text) ?? 1;
    final disc = double.tryParse(_discountCtrl.text) ?? 0;
    final item = InvoiceItem(
      description:     widget.service.name,
      quantity:        qty,
      unitPrice:       widget.service.unitPrice,
      discountPercent: _isPercent ? disc : 0,
      discountFlat:    _isPercent ? 0 : disc,
    );

    return AlertDialog(
      title: Text(widget.service.name),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '\$${widget.service.unitPrice.toStringAsFixed(2)} ${widget.service.rateLabel}',
            style: TextStyle(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withAlpha(150)),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _qtyCtrl,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
                labelText: 'Quantity', hintText: 'e.g. 3.5'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
              child: TextField(
                controller: _discountCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                    labelText:
                        _isPercent ? 'Discount (%)' : 'Discount (\$)',
                    hintText: 'Optional'),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: 8),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: true,  label: Text('%')),
                ButtonSegment(value: false, label: Text('\$')),
              ],
              selected: {_isPercent},
              onSelectionChanged: (s) =>
                  setState(() => _isPercent = s.first),
              style: SegmentedButton.styleFrom(
                minimumSize: const Size(56, 40),
                textStyle: const TextStyle(fontSize: 12),
              ),
            ),
          ]),
          const SizedBox(height: 16),
          // Live total preview
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .primaryContainer
                  .withAlpha(80),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (item.hasDiscount) ...[
                      Text(
                        'Subtotal: \$${item.subtotal.toStringAsFixed(2)}',
                        style: const TextStyle(
                            fontSize: 11,
                            decoration: TextDecoration.lineThrough),
                      ),
                      Text('− ${item.discountLabel}',
                          style: const TextStyle(
                              fontSize: 11, color: Colors.green)),
                    ],
                  ],
                ),
                Text(
                  '\$${item.total.toStringAsFixed(2)}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
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
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            widget.onAdd(item);
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}