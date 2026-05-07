import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:new_invoice_generator/models/employee.dart';
import 'package:new_invoice_generator/models/invoice.dart';
import 'package:new_invoice_generator/models/invoice_item.dart';
import 'package:new_invoice_generator/providers/company.dart';
import 'package:new_invoice_generator/providers/invoice.dart';
import 'package:new_invoice_generator/providers/service.dart';
import 'package:new_invoice_generator/screens/invoice/create/widgets/add_item_section.dart';
import 'package:new_invoice_generator/screens/invoice/create/widgets/customer_section.dart';
import 'package:new_invoice_generator/screens/invoice/create/widgets/invoice_form_helpers.dart';
import 'package:new_invoice_generator/screens/invoice/create/widgets/items_summary_section.dart';
import 'package:new_invoice_generator/screens/invoice/create/widgets/payment_method.dart';
import 'package:new_invoice_generator/screens/invoice/create/widgets/sender_section.dart';

class CreateInvoiceScreen extends ConsumerStatefulWidget {
  const CreateInvoiceScreen({super.key});

  @override
  ConsumerState<CreateInvoiceScreen> createState() =>
      _CreateInvoiceScreenState();
}

class _CreateInvoiceScreenState extends ConsumerState<CreateInvoiceScreen> {
  // Customer
  String? _customerId;
  String? _customerName;
  String? _customerEmail;
  String? _customerPhone;

  // Sender
  Employee? _employee;

  // Items
  final List<InvoiceItem> _items = [];

  // Invoice meta
  DateTime? _dueDate;
  bool _isExport = false;
  bool _isPrivate = false;
  PaymentMethod _paymentMethod = PaymentMethod.etransfer;

  // Controllers for simple text fields
  final _stripeLinkCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  @override
  void dispose() {
    _stripeLinkCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  // ── Computed totals ───────────────────────────────────────────────────────
  double get _subtotal => _items.fold(0, (s, i) => s + i.total);
  double get _taxableSubtotal => _items.fold(0, (s, i) => s + i.subtotal);
  double get _totalDiscounts => _items.fold(0, (s, i) => s + i.discountAmount);

  double _taxRate(Map<String, dynamic> c) =>
      _isExport ? 0.0 : (c['tax_rate'] as num?)?.toDouble() ?? 0.13;

  String _taxLabel(Map<String, dynamic> c) =>
      _isExport ? 'Export (0%)' : (c['tax_label'] as String? ?? 'HST');

  double _tax(Map<String, dynamic> c) => _taxableSubtotal * _taxRate(c);
  double _total(Map<String, dynamic> c) => _subtotal + _tax(c);

  // ── Save ──────────────────────────────────────────────────────────────────
  Future<void> _save(Map<String, dynamic> company) async {
    if (_customerName == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a customer')));
      return;
    }
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one item')),
      );
      return;
    }
    await ref
        .read(invoiceProvider.notifier)
        .addInvoice(
          Invoice(
            invoiceNumber: '',
            customerName: _customerName!,
            customerId: _customerId,
            customerEmail: _customerEmail,
            customerPhone: _customerPhone,
            items: _items,
            issueDate: DateTime.now(),
            dueDate: _dueDate,
            senderEmployeeId: _employee?.id,
            senderName: _employee?.name,
            senderRole: _employee?.role,
            senderEmail: _employee?.email,
            notes: _notesCtrl.text.trim().isEmpty
                ? null
                : _notesCtrl.text.trim(),
            taxRate: _taxRate(company),
            taxLabel: _taxLabel(company),
            isExport: _isExport,
            isPrivate: _isPrivate,
            paymentMethod: _paymentMethod.value,
            stripePaymentLink:
                _paymentMethod == PaymentMethod.stripe &&
                    _stripeLinkCtrl.text.trim().isNotEmpty
                ? _stripeLinkCtrl.text.trim()
                : null,
          ),
        );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final company = ref.watch(companyProvider).asData?.value ?? {};
    final services = ref.watch(serviceProvider).asData?.value ?? [];

    return Scaffold(
      appBar: AppBar(title: const Text('Create Invoice')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Customer ─────────────────────────────────────────────
          CustomerSection(
            selectedId: _customerId,
            onChanged: (id, name, email, phone) => setState(() {
              _customerId = id;
              _customerName = name;
              _customerEmail = email;
              _customerPhone = phone;
            }),
          ),
          const SizedBox(height: 12),

          // ── Sender ───────────────────────────────────────────────
          SenderSection(
            selected: _employee,
            onChanged: (e) => setState(() => _employee = e),
          ),
          const SizedBox(height: 12),

          // ── Due date ─────────────────────────────────────────────
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
                if (picked != null && mounted) {
                  setState(() => _dueDate = picked);
                }
              },
            ),
          ),
          const SizedBox(height: 12),

          // ── Quick-add services ────────────────────────────────────
          QuickAddSection(
            services: services,
            onAdd: (item) => setState(() => _items.add(item)),
          ),
          if (services.isNotEmpty) const SizedBox(height: 12),

          // ── Manual item entry ─────────────────────────────────────
          AddItemSection(onAdd: (item) => setState(() => _items.add(item))),
          const SizedBox(height: 12),

          // ── Items list + totals ───────────────────────────────────
          ItemsSummarySection(
            items: _items,
            taxLabel: _taxLabel(company),
            taxableSubtotal: _taxableSubtotal,
            totalDiscounts: _totalDiscounts,
            subtotal: _subtotal,
            tax: _tax(company),
            total: _total(company),
            onRemove: (item) => setState(() => _items.remove(item)),
          ),
          if (_items.isNotEmpty) const SizedBox(height: 12),

          // ── Tax toggle ────────────────────────────────────────────
          _TaxToggleCard(
            isExport: _isExport,
            company: company,
            taxRate: _taxRate(company),
            taxLabel: _taxLabel(company),
            onChanged: (v) => setState(() => _isExport = v),
          ),
          const SizedBox(height: 12),

          // ── Payment method ────────────────────────────────────────
          PaymentMethodSection(
            selected: _paymentMethod,
            senderEmail: _employee?.email,
            stripeLink: _stripeLinkCtrl.text,
            stripeLinkCtrl: _stripeLinkCtrl,
            onMethodChanged: (m) => setState(() => _paymentMethod = m),
          ),
          const SizedBox(height: 12),

          // ── Private invoice toggle ───────────────────────────────
          Card(
            child: SwitchListTile(
              value: _isPrivate,
              onChanged: (v) => setState(() => _isPrivate = v),
              secondary: Icon(
                Icons.lock_outline,
                color: _isPrivate
                    ? Colors.purple
                    : Theme.of(context).colorScheme.onSurface.withAlpha(120),
              ),
              title: const Text('Private Invoice'),
              subtitle: Text(
                _isPrivate
                    ? 'Excluded from tax reports, analytics, and totals.'
                    : 'Standard invoice — included in all reports.',
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).colorScheme.onSurface.withAlpha(150),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ── Notes / payment terms ─────────────────────────────────
          SectionCard(
            title: 'Notes & Payment Terms',
            child: TextField(
              controller: _notesCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText:
                    'e.g. Payment due within 30 days. E-transfer accepted.',
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // ── Save ──────────────────────────────────────────────────
          ElevatedButton(
            onPressed: () => _save(company),
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

// ── Tax toggle card ───────────────────────────────────────────────────────────
class _TaxToggleCard extends StatelessWidget {
  final bool isExport;
  final Map<String, dynamic> company;
  final double taxRate;
  final String taxLabel;
  final ValueChanged<bool> onChanged;

  const _TaxToggleCard({
    required this.isExport,
    required this.company,
    required this.taxRate,
    required this.taxLabel,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final pct = (taxRate * 100).toStringAsFixed(taxRate * 100 % 1 == 0 ? 0 : 3);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tax',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isExport
                          ? 'International — 0% (export)'
                          : '$taxLabel — $pct%',
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurface.withAlpha(150),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Text('International', style: TextStyle(fontSize: 12)),
                    const SizedBox(width: 8),
                    Switch(value: isExport, onChanged: onChanged),
                  ],
                ),
              ],
            ),
            if (isExport) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withAlpha(60)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, size: 14, color: Colors.blue),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'International customers are zero-rated exports — no tax is charged.',
                        style: TextStyle(fontSize: 11, color: Colors.blue),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
