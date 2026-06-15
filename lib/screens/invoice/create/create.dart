import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:new_invoice_generator/models/address.dart';
import 'package:new_invoice_generator/models/customer.dart';
import 'package:new_invoice_generator/models/employee.dart';
import 'package:new_invoice_generator/models/invoice.dart';
import 'package:new_invoice_generator/models/invoice_item.dart';
import 'package:new_invoice_generator/models/tax_mode.dart';
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
  /// Optional invoice to prefill — used for editing duplicates.
  /// Fields are copied into form state on init; user can change them before saving.
  final Invoice? prefill;
  const CreateInvoiceScreen({super.key, this.prefill});

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
  Address _customerAddress = const Address();

  // Sender
  Employee? _employee;

  // Items
  final List<InvoiceItem> _items = [];

  // Invoice meta
  DateTime _issueDate = DateTime.now();
  DateTime? _dueDate;
  TaxMode _taxMode = TaxMode.standard;
  final _customTaxRateCtrl = TextEditingController(); // percentage as text
  final _customTaxLabelCtrl = TextEditingController();
  bool _isPrivate = false;
  PaymentMethod _paymentMethod = PaymentMethod.etransfer;

  // Controllers for simple text fields
  final _stripeLinkCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final p = widget.prefill;
    if (p != null) {
      _customerId = p.customerId;
      _customerName = p.customerName;
      _customerEmail = p.customerEmail;
      _customerPhone = p.customerPhone;
      // Employee — minimally reconstruct from invoice fields
      if (p.senderEmployeeId != null) {
        _employee = Employee(
          id: p.senderEmployeeId!,
          name: p.senderName ?? '',
          role: p.senderRole ?? '',
          email: p.senderEmail ?? '',
          phone: '',
        );
      }
      _items.addAll(p.items);
      _dueDate = p.dueDate;
      // Derive tax mode from the prefilled invoice
      if (p.isExport) {
        _taxMode = TaxMode.export;
      } else if (p.taxRate == 0) {
        _taxMode = TaxMode.zeroRated;
      } else {
        _taxMode = TaxMode.standard;
      }
      _isPrivate = p.isPrivate;
      _paymentMethod = PaymentMethod.fromValue(p.paymentMethod);
      _stripeLinkCtrl.text = p.stripePaymentLink ?? '';
      _notesCtrl.text = p.notes ?? '';
    }
  }

  @override
  void dispose() {
    _stripeLinkCtrl.dispose();
    _notesCtrl.dispose();
    _customTaxRateCtrl.dispose();
    _customTaxLabelCtrl.dispose();
    super.dispose();
  }

  // ── Computed totals ───────────────────────────────────────────────────────
  double get _subtotal => _items.fold(0, (s, i) => s + i.total);
  double get _taxableSubtotal => _items.fold(0, (s, i) => s + i.subtotal);
  double get _totalDiscounts => _items.fold(0, (s, i) => s + i.discountAmount);

  double _taxRate(Map<String, dynamic> c) {
    switch (_taxMode) {
      case TaxMode.standard:
        return (c['tax_rate'] as num?)?.toDouble() ?? 0.13;
      case TaxMode.zeroRated:
      case TaxMode.export:
        return 0.0;
      case TaxMode.custom:
        final pct = double.tryParse(_customTaxRateCtrl.text.trim()) ?? 0;
        return pct / 100.0;
    }
  }

  String _taxLabel(Map<String, dynamic> c) {
    switch (_taxMode) {
      case TaxMode.standard:
      case TaxMode.zeroRated:
        // Both use the standard label; zero-rated just has a 0% rate
        return c['tax_label'] as String? ?? 'HST';
      case TaxMode.export:
        return 'Export';
      case TaxMode.custom:
        final label = _customTaxLabelCtrl.text.trim();
        return label.isEmpty ? 'Tax' : label;
    }
  }

  bool get _isExport => _taxMode == TaxMode.export;

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
            issueDate: _issueDate,
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
            // Customer address snapshot
            customerAddress: _customerAddress,
            // Company snapshot — frozen at creation
            companyName: company['name'] as String?,
            companyEmail: company['email'] as String?,
            companyPhone: company['phone'] as String?,
            businessNumber: company['business_number'] as String?,
            rtNumber: company['rt_number'] as String?,
            companyAddress: Address(
              line: company['address_line'] as String? ?? '',
              city: company['city'] as String? ?? '',
              province: company['province_region'] as String? ?? '',
              postalCode: company['postal_code'] as String? ?? '',
              country: company['country'] as String? ?? 'Canada',
            ),
          ),
        );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final company = ref.watch(companyProvider).asData?.value ?? {};
    final services = ref.watch(serviceProvider).asData?.value ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.prefill != null ? 'Duplicate Invoice' : 'Create Invoice',
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Customer ─────────────────────────────────────────────
          CustomerSection(
            selectedId: _customerId,
            onChanged: (Customer? c) => setState(() {
              _customerId = c?.id;
              _customerName = c?.name;
              _customerEmail = c?.email;
              _customerPhone = c?.phone;
              _customerAddress = c?.address ?? const Address();
            }),
          ),
          const SizedBox(height: 12),

          // ── Sender ───────────────────────────────────────────────
          SenderSection(
            selected: _employee,
            onChanged: (e) => setState(() => _employee = e),
          ),
          const SizedBox(height: 12),

          // ── Issue date (can be back-dated) ───────────────────────
          Card(
            child: ListTile(
              leading: const Icon(Icons.event_outlined),
              title: const Text('Issue date'),
              subtitle: Text(_issueDate.toLocal().toString().split(' ')[0]),
              trailing: const Icon(Icons.edit_calendar_outlined, size: 18),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _issueDate,
                  // Allow back-dating up to 5 years, and future-dating 1 year
                  firstDate: DateTime(DateTime.now().year - 5),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (picked != null && mounted) {
                  setState(() {
                    _issueDate = picked;
                    // If due date is now before issue date, clear it
                    if (_dueDate != null && _dueDate!.isBefore(picked)) {
                      _dueDate = null;
                    }
                  });
                }
              },
            ),
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
                  initialDate:
                      _dueDate ?? _issueDate.add(const Duration(days: 30)),
                  // Due date can't be before the issue date
                  firstDate: _issueDate,
                  lastDate: _issueDate.add(const Duration(days: 730)),
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

          // ── Tax mode ──────────────────────────────────────────────
          _TaxModeCard(
            mode: _taxMode,
            company: company,
            effectiveRate: _taxRate(company),
            effectiveLabel: _taxLabel(company),
            customRateCtrl: _customTaxRateCtrl,
            customLabelCtrl: _customTaxLabelCtrl,
            onModeChanged: (m) => setState(() => _taxMode = m),
            onCustomChanged: () => setState(() {}),
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
            title: 'Notes & Custom Comments',
            child: TextField(
              controller: _notesCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText:
                    'Add any custom comments, payment terms, or messages to show on the invoice.',
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
class _TaxModeCard extends StatelessWidget {
  final TaxMode mode;
  final Map<String, dynamic> company;
  final double effectiveRate;
  final String effectiveLabel;
  final TextEditingController customRateCtrl;
  final TextEditingController customLabelCtrl;
  final ValueChanged<TaxMode> onModeChanged;
  final VoidCallback onCustomChanged;

  const _TaxModeCard({
    required this.mode,
    required this.company,
    required this.effectiveRate,
    required this.effectiveLabel,
    required this.customRateCtrl,
    required this.customLabelCtrl,
    required this.onModeChanged,
    required this.onCustomChanged,
  });

  String _pct(double rate) {
    final p = rate * 100;
    if (p == p.truncateToDouble()) return '${p.toInt()}%';
    return '${p.toStringAsFixed(3).replaceAll(RegExp(r'0+\$'), '').replaceAll(RegExp(r'\.\$'), '')}%';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final stdLabel = company['tax_label'] as String? ?? 'HST';
    final stdRate = (company['tax_rate'] as num?)?.toDouble() ?? 0.13;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tax',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // Mode selector
            ...[
              _option(
                context,
                value: TaxMode.standard,
                title: 'Standard ($stdLabel ${_pct(stdRate)})',
                subtitle: 'Your province\'s tax rate',
              ),
              _option(
                context,
                value: TaxMode.zeroRated,
                title: 'Zero-rated ($stdLabel 0%)',
                subtitle: 'Shows $stdLabel at 0% on the invoice',
              ),
              _option(
                context,
                value: TaxMode.export,
                title: 'International (Export 0%)',
                subtitle: 'Zero-rated export — labelled as Export',
              ),
              _option(
                context,
                value: TaxMode.custom,
                title: 'Custom rate',
                subtitle: 'Your own label and percentage',
              ),
            ],

            // Custom inputs
            if (mode == TaxMode.custom) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: customLabelCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Tax label',
                        hintText: 'e.g. Service Tax',
                        isDense: true,
                      ),
                      onChanged: (_) => onCustomChanged(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: customRateCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Rate',
                        suffixText: '%',
                        isDense: true,
                      ),
                      onChanged: (_) => onCustomChanged(),
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withAlpha(80),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'On the invoice: $effectiveLabel ${_pct(effectiveRate)}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: cs.onSurface.withAlpha(180),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _option(
    BuildContext context, {
    required TaxMode value,
    required String title,
    required String subtitle,
  }) {
    final selected = mode == value;
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => onModeChanged(value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              size: 20,
              color: selected ? cs.primary : cs.onSurface.withAlpha(110),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: selected
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: cs.onSurface.withAlpha(130),
                    ),
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
