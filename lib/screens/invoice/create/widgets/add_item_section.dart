import 'package:flutter/material.dart';
import 'package:new_invoice_generator/models/invoice/item.dart';
import 'package:new_invoice_generator/models/service.dart';
import 'package:new_invoice_generator/screens/invoice/create/widgets/invoice_form_helpers.dart';
import 'package:new_invoice_generator/screens/invoice/create/widgets/quick_add_service_dialog.dart';

class AddItemSection extends StatefulWidget {
  final void Function(InvoiceItem item) onAdd;

  const AddItemSection({super.key, required this.onAdd});

  @override
  State<AddItemSection> createState() => _AddItemSectionState();
}

class _AddItemSectionState extends State<AddItemSection> {
  final _descCtrl     = TextEditingController();
  final _qtyCtrl      = TextEditingController();
  final _priceCtrl    = TextEditingController();
  final _discountCtrl = TextEditingController();
  bool _discountIsPercent = true;

  @override
  void dispose() {
    _descCtrl.dispose();
    _qtyCtrl.dispose();
    _priceCtrl.dispose();
    _discountCtrl.dispose();
    super.dispose();
  }

  void _add() {
    final desc  = _descCtrl.text.trim();
    final qty   = double.tryParse(_qtyCtrl.text) ?? 1;
    final price = double.tryParse(_priceCtrl.text) ?? 0;
    final disc  = double.tryParse(_discountCtrl.text) ?? 0;
    if (desc.isEmpty || qty <= 0) return;

    widget.onAdd(InvoiceItem(
      description:     desc,
      quantity:        qty,
      unitPrice:       price,
      discountPercent: _discountIsPercent ? disc : 0,
      discountFlat:    _discountIsPercent ? 0 : disc,
    ));

    _descCtrl.clear();
    _qtyCtrl.clear();
    _priceCtrl.clear();
    _discountCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Add Item',
      child: Column(
        children: [
          TextField(
              controller: _descCtrl,
              decoration:
                  const InputDecoration(labelText: 'Description')),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
              child: TextField(
                  controller: _qtyCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true),
                  decoration: const InputDecoration(
                      labelText: 'Qty',
                      hintText: 'e.g. 3.5')),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                  controller: _priceCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true),
                  decoration: const InputDecoration(
                      labelText: 'Unit price (\$)')),
            ),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
              child: TextField(
                controller: _discountCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                    decimal: true),
                decoration: InputDecoration(
                  labelText:
                      _discountIsPercent ? 'Discount (%)' : 'Discount (\$)',
                  hintText: 'Optional',
                  prefixIcon: const Icon(Icons.local_offer_outlined,
                      size: 18),
                ),
              ),
            ),
            const SizedBox(width: 8),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: true,  label: Text('%')),
                ButtonSegment(value: false, label: Text('\$')),
              ],
              selected: {_discountIsPercent},
              onSelectionChanged: (s) =>
                  setState(() => _discountIsPercent = s.first),
              style: SegmentedButton.styleFrom(
                minimumSize: const Size(56, 40),
                textStyle: const TextStyle(fontSize: 12),
              ),
            ),
          ]),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Add Item'),
              onPressed: _add,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Quick-add service chips ───────────────────────────────────────────────────
class QuickAddSection extends StatelessWidget {
  final List<Service> services;
  final void Function(InvoiceItem item) onAdd;

  const QuickAddSection({
    super.key,
    required this.services,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    if (services.isEmpty) return const SizedBox.shrink();
    return SectionCard(
      title: 'Quick Add Service',
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: services.map((s) => ActionChip(
          label: Text('${s.name} (\$${s.unitPrice.toStringAsFixed(2)})'),
          onPressed: () => showDialog(
            context: context,
            builder: (_) =>
                QuickAddServiceDialog(service: s, onAdd: onAdd),
          ),
        )).toList(),
      ),
    );
  }
}