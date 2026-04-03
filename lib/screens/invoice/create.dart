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

  String? _selectedCustomerId;
  String? _selectedCustomerName;
  String? _selectedCustomerEmail;

  // Sender employee — optional
  Employee? _selectedEmployee;

  DateTime? _dueDate;
  List<InvoiceItem> items = [];

  @override
  void dispose() {
    _itemDescCtrl.dispose();
    _qtyCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  void _addItem() {
    final desc = _itemDescCtrl.text.trim();
    final qty = int.tryParse(_qtyCtrl.text) ?? 1;
    final price = double.tryParse(_priceCtrl.text) ?? 0;
    if (desc.isEmpty) return;
    setState(() {
      items.add(
        InvoiceItem(description: desc, quantity: qty, unitPrice: price),
      );
      _itemDescCtrl.clear();
      _qtyCtrl.clear();
      _priceCtrl.clear();
    });
  }

  void _addServiceItem(Service s) {
    setState(() {
      items.add(
        InvoiceItem(description: s.name, quantity: 1, unitPrice: s.unitPrice),
      );
    });
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
    final servicesAsync = ref.watch(serviceProvider);
    final services = servicesAsync.asData?.value ?? [];
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Create Invoice')),
      body: ListView(
        padding: const .all(16),
        children: [
          // ── Customer ──────────────────────────────────────────────────
          Card(
            child: Padding(
              padding: const .all(16),
              child: Column(
                crossAxisAlignment: .start,
                children: [
                  Text(
                    'Customer',
                    style: Theme.of(
                      context,
                    ).textTheme.titleSmall?.copyWith(fontWeight: .bold),
                  ),
                  const SizedBox(height: 10),
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
                  // Show customer email confirmation
                  if (_selectedCustomerEmail != null &&
                      _selectedCustomerEmail!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.email_outlined,
                          size: 14,
                          color: cs.onSurface.withAlpha(140),
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
          ),
          const SizedBox(height: 12),

          // ── Sender / Employee (optional) ──────────────────────────────
          employeesAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
            data: (employees) => employees.isEmpty
                ? const SizedBox.shrink()
                : Card(
                    child: Padding(
                      padding: const .all(16),
                      child: Column(
                        crossAxisAlignment: .start,
                        children: [
                          Text(
                            'Sender / Employee',
                            style: Theme.of(
                              context,
                            ).textTheme.titleSmall?.copyWith(fontWeight: .bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'The employee who provided the service. '
                            'Their email will appear on the invoice '
                            'for e-transfer payment.',
                            style: TextStyle(
                              fontSize: 12,
                              color: cs.onSurface.withAlpha(150),
                            ),
                          ),
                          const SizedBox(height: 10),
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
                            onChanged: (v) {
                              setState(() {
                                _selectedEmployee = v == null
                                    ? null
                                    : employees.firstWhere((e) => e.id == v);
                              });
                            },
                          ),
                          // Show employee email confirmation
                          if (_selectedEmployee?.email != null &&
                              _selectedEmployee!.email.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const .symmetric(
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
                                        fontWeight: .w500,
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
          ),
          const SizedBox(height: 12),

          // ── Due date ──────────────────────────────────────────────────
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

          // ── Quick-add services ────────────────────────────────────────
          if (services.isNotEmpty)
            Card(
              child: Padding(
                padding: const .all(16),
                child: Column(
                  crossAxisAlignment: .start,
                  children: [
                    Text(
                      'Quick Add Service',
                      style: Theme.of(
                        context,
                      ).textTheme.titleSmall?.copyWith(fontWeight: .bold),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
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
                  ],
                ),
              ),
            ),
          if (services.isNotEmpty) const SizedBox(height: 12),

          // ── Manual item entry ─────────────────────────────────────────
          Card(
            child: Padding(
              padding: const .all(16),
              child: Column(
                crossAxisAlignment: .start,
                children: [
                  Text(
                    'Add Custom Item',
                    style: Theme.of(
                      context,
                    ).textTheme.titleSmall?.copyWith(fontWeight: .bold),
                  ),
                  const SizedBox(height: 10),
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
                            labelText: 'Unit Price',
                          ),
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
          ),
          const SizedBox(height: 12),

          // ── Items list + totals ───────────────────────────────────────
          if (items.isNotEmpty)
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
                    ...items.map(
                      (i) => Padding(
                        padding: const .symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Expanded(child: Text(i.description)),
                            Text(
                              'x${i.quantity}  \$${i.unitPrice.toStringAsFixed(2)}',
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '\$${i.total.toStringAsFixed(2)}',
                              style: const TextStyle(fontWeight: .w600),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.remove_circle_outline,
                                size: 18,
                                color: Colors.red,
                              ),
                              onPressed: () => setState(() => items.remove(i)),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Divider(),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Column(
                        crossAxisAlignment: .end,
                        children: [
                          Text('Subtotal: \$${_subtotal.toStringAsFixed(2)}'),
                          Text('Tax (13%): \$${_tax.toStringAsFixed(2)}'),
                          Text(
                            'Total: \$${_total.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontWeight: .bold,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
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
