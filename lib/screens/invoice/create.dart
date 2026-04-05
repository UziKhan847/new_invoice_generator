import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:new_invoice_generator/models/employee.dart';
import 'package:new_invoice_generator/models/invoice.dart';
import 'package:new_invoice_generator/models/invoice_item.dart';
import 'package:new_invoice_generator/models/service.dart';
import 'package:new_invoice_generator/providers/customer.dart';
import 'package:new_invoice_generator/providers/employee.dart';
import 'package:new_invoice_generator/providers/invoice.dart';
import 'package:new_invoice_generator/providers/service.dart';

class CreateInvoiceScreen extends ConsumerStatefulWidget {
  const CreateInvoiceScreen({super.key});

  @override
  ConsumerState<CreateInvoiceScreen> createState() =>
      _CreateInvoiceScreenState();
}

class _CreateInvoiceScreenState extends ConsumerState<CreateInvoiceScreen> {
  final _itemDescCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _discountCtrl = TextEditingController();

  String? _selectedCustomerId;
  String? _selectedCustomerName;
  String? _selectedCustomerEmail;
  Employee? _selectedEmployee;

  // Discount type toggle for the add-item form
  bool _discountIsPercent = true;

  DateTime? _dueDate;
  List<InvoiceItem> items = [];

  @override
  void dispose() {
    _itemDescCtrl.dispose();
    _qtyCtrl.dispose();
    _priceCtrl.dispose();
    _discountCtrl.dispose();
    super.dispose();
  }

  void _addItem() {
    final desc = _itemDescCtrl.text.trim();
    final qty = int.tryParse(_qtyCtrl.text) ?? 1;
    final price = double.tryParse(_priceCtrl.text) ?? 0;
    final disc = double.tryParse(_discountCtrl.text) ?? 0;
    if (desc.isEmpty) return;

    setState(() {
      items.add(
        InvoiceItem(
          description: desc,
          quantity: qty,
          unitPrice: price,
          discountPercent: _discountIsPercent ? disc : 0,
          discountFlat: _discountIsPercent ? 0 : disc,
        ),
      );
      _itemDescCtrl.clear();
      _qtyCtrl.clear();
      _priceCtrl.clear();
      _discountCtrl.clear();
    });
  }

  void _addServiceItem(Service s) {
    // Quick-add from chip — opens a small dialog to optionally add a discount
    showDialog(
      context: context,
      builder: (_) => _QuickAddServiceDialog(
        service: s,
        onAdd: (item) => setState(() => items.add(item)),
      ),
    );
  }

  void _saveInvoice() {
    if (_selectedCustomerName == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a customer')));
      return;
    }
    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one item')),
      );
      return;
    }
    ref
        .read(invoiceProvider.notifier)
        .addInvoice(
          Invoice(
            invoiceNumber: '',
            customerName: _selectedCustomerName!,
            customerId: _selectedCustomerId,
            customerEmail: _selectedCustomerEmail,
            issueDate: DateTime.now(),
            dueDate: _dueDate,
            items: items,
            senderEmployeeId: _selectedEmployee?.id,
            senderName: _selectedEmployee?.name,
            senderRole: _selectedEmployee?.role,
            senderEmail: _selectedEmployee?.email,
          ),
        );
    Navigator.pop(context);
  }

  double get _subtotal => items.fold(0, (s, i) => s + i.total);
  double get _tax => _subtotal * 0.13;
  double get _total => _subtotal + _tax;

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(customerProvider);
    final employeesAsync = ref.watch(employeeProvider);
    final services = ref.watch(serviceProvider).asData?.value ?? [];
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Create Invoice')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Customer ──────────────────────────────────────────────
          _SectionCard(
            title: 'Customer',
            child: Column(
              children: [
                customersAsync.when(
                  loading: () => const CircularProgressIndicator(),
                  error: (e, _) => Text('Error: $e'),
                  data: (customers) => DropdownButtonFormField<String>(
                    initialValue: _selectedCustomerId,
                    decoration: const InputDecoration(
                      labelText: 'Select customer',
                    ),
                    items: customers
                        .map(
                          (c) => DropdownMenuItem(
                            value: c.id,
                            child: Text(c.name),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      final c = customers.cast<dynamic>().firstWhere(
                        (c) => c.id == v,
                        orElse: () => null,
                      );
                      setState(() {
                        _selectedCustomerId = v;
                        _selectedCustomerName = c?.name as String?;
                        _selectedCustomerEmail = c?.email as String?;
                      });
                    },
                  ),
                ),
                if (_selectedCustomerEmail != null &&
                    _selectedCustomerEmail!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.email_outlined,
                        size: 13,
                        color: cs.onSurface.withAlpha(130),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _selectedCustomerEmail!,
                        style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurface.withAlpha(140),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── Sender / Employee ─────────────────────────────────────
          employeesAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
            data: (employees) => employees.isEmpty
                ? const SizedBox.shrink()
                : _SectionCard(
                    title: 'Sender / Employee',
                    child: Column(
                      children: [
                        DropdownButtonFormField<String>(
                          initialValue: _selectedEmployee?.id,
                          decoration: const InputDecoration(
                            labelText: 'Select employee (optional)',
                          ),
                          items: [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('No employee'),
                            ),
                            ...employees.map(
                              (e) => DropdownMenuItem(
                                value: e.id,
                                child: Text('${e.name} · ${e.role}'),
                              ),
                            ),
                          ],
                          onChanged: (v) => setState(() {
                            _selectedEmployee = v == null
                                ? null
                                : employees.firstWhere((e) => e.id == v);
                          }),
                        ),
                        if (_selectedEmployee?.email != null &&
                            _selectedEmployee!.email.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
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
                                  size: 14,
                                  color: Colors.green,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'E-transfer to: ${_selectedEmployee!.email}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.green,
                                      fontWeight: FontWeight.w500,
                                    ),
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
          const SizedBox(height: 12),

          // ── Due date ──────────────────────────────────────────────
          Card(
            child: ListTile(
              leading: const Icon(Icons.calendar_today_outlined),
              title: Text(
                _dueDate == null
                    ? 'Set due date (optional)'
                    : 'Due: ${_dueDate!.toLocal().toString().split(' ')[0]}',
              ),
              trailing: _dueDate != null
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => setState(() => _dueDate = null),
                    )
                  : null,
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now().add(const Duration(days: 30)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (picked != null) setState(() => _dueDate = picked);
              },
            ),
          ),
          const SizedBox(height: 12),

          // ── Quick add services ────────────────────────────────────
          if (services.isNotEmpty)
            _SectionCard(
              title: 'Quick Add Service',
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: services
                    .map(
                      (s) => ActionChip(
                        label: Text(
                          '${s.name} (\$${s.unitPrice.toStringAsFixed(2)})',
                        ),
                        onPressed: () => _addServiceItem(s),
                      ),
                    )
                    .toList(),
              ),
            ),
          if (services.isNotEmpty) const SizedBox(height: 12),

          // ── Manual item entry ─────────────────────────────────────
          _SectionCard(
            title: 'Add Item',
            child: Column(
              children: [
                TextField(
                  controller: _itemDescCtrl,
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _qtyCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Qty'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _priceCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Unit price (\$)',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // ── Discount row ──────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _discountCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: _discountIsPercent
                              ? 'Discount (%)'
                              : 'Discount (\$)',
                          hintText: 'Optional',
                          prefixIcon: const Icon(
                            Icons.local_offer_outlined,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Toggle % vs $
                    SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment(value: true, label: Text('%')),
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
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Add Item'),
                    onPressed: _addItem,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── Items list ────────────────────────────────────────────
          if (items.isNotEmpty)
            _SectionCard(
              title: 'Items',
              child: Column(
                children: [
                  ...items.map(
                    (item) => _ItemRow(
                      item: item,
                      onRemove: () => setState(() => items.remove(item)),
                    ),
                  ),
                  const Divider(height: 20),
                  // Totals
                  _TotalLine(
                    label: 'Subtotal',
                    value: '\$${_subtotal.toStringAsFixed(2)}',
                  ),
                  _TotalLine(
                    label: 'Tax (13%)',
                    value: '\$${_tax.toStringAsFixed(2)}',
                  ),
                  const SizedBox(height: 4),
                  _TotalLine(
                    label: 'Total',
                    value: '\$${_total.toStringAsFixed(2)}',
                    bold: true,
                  ),
                ],
              ),
            ),
          const SizedBox(height: 24),

          ElevatedButton(
            onPressed: _saveInvoice,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
            ),
            child: const Text('Save Invoice', style: TextStyle(fontSize: 16)),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

// ── Item row in the items list ────────────────────────────────────────────────
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
                Text(
                  item.description,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  'x${item.quantity}  ×  \$${item.unitPrice.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: cs.onSurface.withAlpha(150),
                  ),
                ),
                if (item.hasDiscount)
                  Text(
                    '− ${item.discountLabel}  (−\$${item.discountAmount.toStringAsFixed(2)})',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.green,
                      fontWeight: FontWeight.w500,
                    ),
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
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
              Text(
                '\$${item.total.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(
              Icons.remove_circle_outline,
              size: 18,
              color: Colors.red,
            ),
            onPressed: onRemove,
            padding: const EdgeInsets.only(left: 4),
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}

// ── Quick add from service chip — allows discount before confirming ────────────
class _QuickAddServiceDialog extends StatefulWidget {
  final Service service;
  final void Function(InvoiceItem) onAdd;
  const _QuickAddServiceDialog({required this.service, required this.onAdd});

  @override
  State<_QuickAddServiceDialog> createState() => _QuickAddServiceDialogState();
}

class _QuickAddServiceDialogState extends State<_QuickAddServiceDialog> {
  final _qtyCtrl = TextEditingController(text: '1');
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
    final qty = int.tryParse(_qtyCtrl.text) ?? 1;
    final disc = double.tryParse(_discountCtrl.text) ?? 0;
    final item = InvoiceItem(
      description: widget.service.name,
      quantity: qty,
      unitPrice: widget.service.unitPrice,
      discountPercent: _isPercent ? disc : 0,
      discountFlat: _isPercent ? 0 : disc,
    );

    return AlertDialog(
      title: Text(widget.service.name),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '\$${widget.service.unitPrice.toStringAsFixed(2)} ${widget.service.rateLabel}',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withAlpha(150),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _qtyCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Quantity'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _discountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: _isPercent ? 'Discount (%)' : 'Discount (\$)',
                    hintText: 'Optional',
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 8),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: true, label: Text('%')),
                  ButtonSegment(value: false, label: Text('\$')),
                ],
                selected: {_isPercent},
                onSelectionChanged: (s) => setState(() => _isPercent = s.first),
                style: SegmentedButton.styleFrom(
                  minimumSize: const Size(56, 40),
                  textStyle: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
          // Live total preview
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.primaryContainer.withAlpha(80),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (item.hasDiscount)
                      Text(
                        'Subtotal: \$${item.subtotal.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 11,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    if (item.hasDiscount)
                      Text(
                        '− ${item.discountLabel}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.green,
                        ),
                      ),
                  ],
                ),
                Text(
                  '\$${item.total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
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

// ── Helpers ───────────────────────────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _TotalLine extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  const _TotalLine({
    required this.label,
    required this.value,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    final style = bold
        ? const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)
        : null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(value, style: style),
        ],
      ),
    );
  }
}
