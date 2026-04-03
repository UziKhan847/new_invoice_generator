import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:new_invoice_generator/models/employee.dart';
import 'package:new_invoice_generator/models/recurring_invoice.dart';
import 'package:new_invoice_generator/providers/company.dart';
import 'package:new_invoice_generator/providers/customer.dart';
import 'package:new_invoice_generator/providers/employee.dart';
import 'package:new_invoice_generator/providers/recurring_invoice.dart';
import 'package:new_invoice_generator/providers/service.dart';

class RecurringInvoicesScreen extends ConsumerWidget {
  const RecurringInvoicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recurringAsync = ref.watch(recurringInvoiceProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Recurring Invoices')),
      body: recurringAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: .center,
                children: [
                  const Icon(Icons.repeat, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'No recurring invoices',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tap + to set one up',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const .all(12),
            itemCount: items.length,
            itemBuilder: (context, i) => _RecurringTile(r: items[i]),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showDialog(
          context: context,
          builder: (_) => const _AddRecurringDialog(),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}

// ── Tile ──────────────────────────────────────────────────────────────────────
class _RecurringTile extends ConsumerWidget {
  final RecurringInvoice r;
  const _RecurringTile({required this.r});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const .only(bottom: 10),
      child: Padding(
        padding: const .all(14),
        child: Column(
          crossAxisAlignment: .start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: .start,
                    children: [
                      Text(
                        r.label,
                        style: const TextStyle(fontWeight: .bold, fontSize: 16),
                      ),
                      if (r.customerName != null)
                        Text(
                          r.customerName!,
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withAlpha(160),
                            fontSize: 13,
                          ),
                        ),
                      if (r.senderName != null)
                        Text(
                          'Sender: ${r.senderName}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const .symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.blue.withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    r.frequencyLabel,
                    style: const TextStyle(fontSize: 11, color: Colors.blue),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '\$${r.price.toStringAsFixed(2)} per period',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withAlpha(160),
              ),
            ),
            if (r.nextDueDate != null) ...[
              const SizedBox(height: 4),
              Text(
                'Next due: ${r.nextDueDate!.toLocal().toString().split(' ')[0]}',
                style: const TextStyle(fontSize: 12, color: Colors.orange),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.flash_on, size: 16),
                    label: const Text('Generate Now'),
                    onPressed: () => showDialog(
                      context: context,
                      builder: (_) => _GenerateDialog(r: r),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: 'Edit template',
                  onPressed: () => showDialog(
                    context: context,
                    builder: (_) => _EditRecurringDialog(r: r),
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.stop_circle_outlined,
                    color: Colors.red,
                  ),
                  tooltip: 'Deactivate',
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Deactivate?'),
                        content: const Text(
                          'This recurring invoice will stop generating.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Deactivate'),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await ref
                          .read(recurringInvoiceProvider.notifier)
                          .deactivate(r.id!);
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Generate dialog — editable before generating ──────────────────────────────
class _GenerateDialog extends ConsumerStatefulWidget {
  final RecurringInvoice r;
  const _GenerateDialog({required this.r});

  @override
  ConsumerState<_GenerateDialog> createState() => _GenerateDialogState();
}

class _GenerateDialogState extends ConsumerState<_GenerateDialog> {
  late final TextEditingController _labelCtrl;
  late final TextEditingController _rateCtrl; // rate per unit (e.g. 10/hr)
  late final TextEditingController _unitsCtrl; // how many units this period
  String? _senderEmployeeId;
  bool _loading = false;

  // Whether the service has a per-unit rate type (not fixed)

  double get _computedTotal {
    final rate = double.tryParse(_rateCtrl.text) ?? widget.r.price;
    final units = double.tryParse(_unitsCtrl.text) ?? 1.0;
    return rate * units;
  }

  @override
  void initState() {
    super.initState();
    _labelCtrl = TextEditingController(text: widget.r.label);
    _rateCtrl = TextEditingController(text: widget.r.price.toStringAsFixed(2));
    // Default units = 1; if monthly service at hourly rate the user edits this
    _unitsCtrl = TextEditingController(text: '1');
    _senderEmployeeId = widget.r.senderEmployeeId;
  }

  @override
  void dispose() {
    _labelCtrl.dispose();
    _rateCtrl.dispose();
    _unitsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final employeesAsync = ref.watch(employeeProvider);
    final total = _computedTotal;

    return AlertDialog(
      title: const Text('Generate Invoice'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: .min,
          crossAxisAlignment: .start,
          children: [
            Text(
              'Adjust before generating:',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _labelCtrl,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            const SizedBox(height: 10),
            // Rate + units row
            Row(
              crossAxisAlignment: .end,
              children: [
                Expanded(
                  child: TextField(
                    controller: _rateCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Rate (\$)',
                      helperText: 'per ${widget.r.frequencyUnitLabel}',
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const Padding(
                  padding: .only(bottom: 18, left: 8, right: 8),
                  child: Text('×', style: TextStyle(fontSize: 18)),
                ),
                Expanded(
                  child: TextField(
                    controller: _unitsCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: widget.r.frequencyUnitLabel,
                      helperText: 'this period',
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Live total
            Container(
              padding: const .symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.primaryContainer.withAlpha(80),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: .spaceBetween,
                children: [
                  const Text('Total', style: TextStyle(fontWeight: .w600)),
                  Text(
                    '\$${total.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: .bold, fontSize: 16),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            // Sender picker
            employeesAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
              data: (employees) => DropdownButtonFormField<String>(
                initialValue: _senderEmployeeId,
                decoration: const InputDecoration(
                  labelText: 'Sender (optional)',
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('No sender')),
                  ...employees.map(
                    (e) => DropdownMenuItem(
                      value: e.id,
                      child: Text('\${e.name} · \${e.role}'),
                    ),
                  ),
                ],
                onChanged: (v) => setState(() => _senderEmployeeId = v),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _loading
              ? null
              : () async {
                  setState(() => _loading = true);
                  try {
                    final employeesAsync = ref.read(employeeProvider);
                    Employee? sender;
                    employeesAsync.whenData((emps) {
                      sender = emps.cast<Employee?>().firstWhere(
                        (e) => e?.id == _senderEmployeeId,
                        orElse: () => null,
                      );
                    });

                    final units = double.tryParse(_unitsCtrl.text) ?? 1.0;
                    final rate =
                        double.tryParse(_rateCtrl.text) ?? widget.r.price;
                    // Build a descriptive label e.g. "Quran Lessons (8 hrs)"
                    final label = units == 1.0
                        ? _labelCtrl.text.trim()
                        : '\${_labelCtrl.text.trim()} (\${_formatUnits(units)} \$unitLabel)';

                    await ref
                        .read(recurringInvoiceProvider.notifier)
                        .generateNow(
                          widget.r,
                          customerName: widget.r.customerName ?? 'Customer',
                          adjustedPrice: rate * units,
                          adjustedLabel: label,
                          senderEmployeeId: _senderEmployeeId,
                          senderName: sender?.name,
                          senderRole: sender?.role,
                          senderEmail: sender?.email,
                        );
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Invoice generated!')),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text('Error: \$e')));
                    }
                  } finally {
                    if (mounted) setState(() => _loading = false);
                  }
                },
          child: _loading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Generate'),
        ),
      ],
    );
  }
}

// ── Edit recurring template ───────────────────────────────────────────────────

class _EditRecurringDialog extends ConsumerStatefulWidget {
  final RecurringInvoice r;
  const _EditRecurringDialog({required this.r});

  @override
  ConsumerState<_EditRecurringDialog> createState() =>
      _EditRecurringDialogState();
}

class _EditRecurringDialogState extends ConsumerState<_EditRecurringDialog> {
  late final TextEditingController _labelCtrl;
  late final TextEditingController _priceCtrl;
  late String _frequency;
  String? _senderEmployeeId;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _labelCtrl = TextEditingController(text: widget.r.label);
    _priceCtrl = TextEditingController(text: widget.r.price.toStringAsFixed(2));
    _frequency = widget.r.frequency;
    _senderEmployeeId = widget.r.senderEmployeeId;
  }

  @override
  void dispose() {
    _labelCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final employeesAsync = ref.watch(employeeProvider);

    return AlertDialog(
      title: const Text('Edit Recurring Invoice'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: .min,
          children: [
            TextField(
              controller: _labelCtrl,
              decoration: const InputDecoration(labelText: 'Label'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _priceCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(labelText: 'Price (\$)'),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: _frequency,
              decoration: const InputDecoration(labelText: 'Frequency'),
              items: const [
                DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                DropdownMenuItem(
                  value: '4_weekly',
                  child: Text('Every 4 Weeks'),
                ),
                DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                DropdownMenuItem(value: 'yearly', child: Text('Yearly')),
              ],
              onChanged: (v) => setState(() => _frequency = v!),
            ),
            const SizedBox(height: 10),
            employeesAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
              data: (employees) => DropdownButtonFormField<String>(
                initialValue: _senderEmployeeId,
                decoration: const InputDecoration(
                  labelText: 'Sender (optional)',
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('No sender')),
                  ...employees.map(
                    (e) => DropdownMenuItem(
                      value: e.id,
                      child: Text('${e.name} · ${e.role}'),
                    ),
                  ),
                ],
                onChanged: (v) => setState(() => _senderEmployeeId = v),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _loading
              ? null
              : () async {
                  setState(() => _loading = true);
                  try {
                    await ref
                        .read(recurringInvoiceProvider.notifier)
                        .updateTemplate(
                          widget.r.id!,
                          label: _labelCtrl.text.trim(),
                          price:
                              double.tryParse(_priceCtrl.text) ??
                              widget.r.price,
                          frequency: _frequency,
                          senderEmployeeId: _senderEmployeeId,
                        );
                    if (context.mounted) Navigator.pop(context);
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text('Error: $e')));
                    }
                  } finally {
                    if (mounted) setState(() => _loading = false);
                  }
                },
          child: _loading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}

// ── Add recurring dialog ──────────────────────────────────────────────────────
class _AddRecurringDialog extends ConsumerStatefulWidget {
  const _AddRecurringDialog();

  @override
  ConsumerState<_AddRecurringDialog> createState() =>
      _AddRecurringDialogState();
}

class _AddRecurringDialogState extends ConsumerState<_AddRecurringDialog> {
  final _labelCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  String _frequency = 'monthly';
  String? _selectedCustomerId;
  String? _selectedServiceId;
  String? _selectedSenderId;
  bool _loading = false;

  @override
  void dispose() {
    _labelCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(customerProvider);
    final employeesAsync = ref.watch(employeeProvider);
    final servicesAsync = ref.watch(serviceProvider);
    final services = servicesAsync.asData?.value ?? [];

    return AlertDialog(
      title: const Text('New Recurring Invoice'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: .min,
          children: [
            TextField(
              controller: _labelCtrl,
              decoration: const InputDecoration(
                labelText: 'Label (e.g. Quran Lessons)',
              ),
            ),
            const SizedBox(height: 12),
            customersAsync.when(
              loading: () => const CircularProgressIndicator(),
              error: (e, _) => Text('Error: $e'),
              data: (customers) => DropdownButtonFormField<String>(
                initialValue: _selectedCustomerId,
                decoration: const InputDecoration(labelText: 'Customer'),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('Select customer'),
                  ),
                  ...customers.map(
                    (c) => DropdownMenuItem(value: c.id, child: Text(c.name)),
                  ),
                ],
                onChanged: (v) => setState(() => _selectedCustomerId = v),
              ),
            ),
            const SizedBox(height: 12),
            if (services.isNotEmpty)
              DropdownButtonFormField<String>(
                initialValue: _selectedServiceId,
                decoration: const InputDecoration(
                  labelText: 'Service (optional)',
                ),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('No service'),
                  ),
                  ...services.map(
                    (s) => DropdownMenuItem(
                      value: s.id,
                      child: Text(
                        '${s.name} — \$${s.unitPrice.toStringAsFixed(2)}',
                      ),
                    ),
                  ),
                ],
                onChanged: (v) {
                  setState(() => _selectedServiceId = v);
                  if (v != null && _priceCtrl.text.isEmpty) {
                    final svc = services.cast<dynamic>().firstWhere(
                      (s) => s.id == v,
                      orElse: () => null,
                    );
                    if (svc != null) {
                      _priceCtrl.text = (svc.unitPrice as double)
                          .toStringAsFixed(2);
                    }
                  }
                },
              ),
            const SizedBox(height: 12),
            TextField(
              controller: _priceCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(labelText: 'Price (\$)'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _frequency,
              decoration: const InputDecoration(labelText: 'Frequency'),
              items: const [
                DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                DropdownMenuItem(
                  value: '4_weekly',
                  child: Text('Every 4 Weeks'),
                ),
                DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                DropdownMenuItem(value: 'yearly', child: Text('Yearly')),
              ],
              onChanged: (v) => setState(() => _frequency = v!),
            ),
            const SizedBox(height: 12),
            employeesAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
              data: (employees) => employees.isEmpty
                  ? const SizedBox.shrink()
                  : DropdownButtonFormField<String>(
                      initialValue: _selectedSenderId,
                      decoration: const InputDecoration(
                        labelText: 'Sender (optional)',
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('No sender'),
                        ),
                        ...employees.map(
                          (e) => DropdownMenuItem(
                            value: e.id,
                            child: Text('${e.name} · ${e.role}'),
                          ),
                        ),
                      ],
                      onChanged: (v) => setState(() => _selectedSenderId = v),
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _loading
              ? null
              : () async {
                  if (_selectedCustomerId == null ||
                      _labelCtrl.text.trim().isEmpty ||
                      _priceCtrl.text.isEmpty) {
                    return;
                  }
                  setState(() => _loading = true);
                  try {
                    final company = await ref.read(companyProvider.future);
                    final now = DateTime.now();
                    await ref
                        .read(recurringInvoiceProvider.notifier)
                        .create(
                          RecurringInvoice(
                            companyId: company['id'] as String,
                            customerId: _selectedCustomerId!,
                            serviceId: _selectedServiceId,
                            senderEmployeeId: _selectedSenderId,
                            label: _labelCtrl.text.trim(),
                            price: double.tryParse(_priceCtrl.text) ?? 0,
                            frequency: _frequency,
                            nextDueDate: RecurringInvoice.computeNextDue(
                              _frequency,
                              from: now,
                            ),
                          ),
                        );
                    if (context.mounted) Navigator.pop(context);
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text('Error: $e')));
                    }
                  } finally {
                    if (mounted) setState(() => _loading = false);
                  }
                },
          child: _loading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}
