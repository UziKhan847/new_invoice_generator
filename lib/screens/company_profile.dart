import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:new_invoice_generator/models/address.dart';
import 'package:new_invoice_generator/models/province.dart';
import 'package:new_invoice_generator/providers/company.dart';
import 'package:new_invoice_generator/screens/widgets/address_form.dart';
import 'package:new_invoice_generator/screens/widgets/phone_field.dart';
import 'package:new_invoice_generator/utils/validators.dart';

class CompanyProfileScreen extends ConsumerStatefulWidget {
  const CompanyProfileScreen({super.key});

  @override
  ConsumerState<CompanyProfileScreen> createState() =>
      _CompanyProfileScreenState();
}

class _CompanyProfileScreenState extends ConsumerState<CompanyProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  String _phone = '';
  final _bnCtrl = TextEditingController();
  final _rtCtrl = TextEditingController();

  Province? _province;
  Address _address = const Address();
  bool _initialized = false;
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _bnCtrl.dispose();
    _rtCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final companyAsync = ref.watch(companyProvider);
    final cs = Theme.of(context).colorScheme;
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      appBar: AppBar(title: const Text('Company Profile')),
      body: companyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (company) {
          if (!_initialized) {
            _nameCtrl.text = company['name'] as String? ?? '';
            _emailCtrl.text = company['email'] as String? ?? '';
            _phone = company['phone'] as String? ?? '';
            _bnCtrl.text = company['business_number'] as String? ?? '';
            _rtCtrl.text = company['rt_number'] as String? ?? '';
            _province = Province.fromCode(
              company['province'] as String? ?? 'ON',
            );
            _address = Address(
              line: company['address_line'] as String? ?? '',
              city: company['city'] as String? ?? '',
              province: company['province_region'] as String? ?? '',
              postalCode: company['postal_code'] as String? ?? '',
              country: company['country'] as String? ?? 'Canada',
            );
            _initialized = true;
          }

          return Form(
            key: _formKey,
            child: ListView(
              padding: EdgeInsets.fromLTRB(16, 16, 16, bottom + 24),
              children: [
                _section('Business Identity', [
                  TextFormField(
                    controller: _nameCtrl,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Business Name *',
                      prefixIcon: Icon(Icons.business_outlined),
                    ),
                    validator: (v) =>
                        Validators.required(v, field: 'Business name'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Business Email',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    validator: (v) => Validators.email(v, required: false),
                  ),
                  const SizedBox(height: 12),
                  PhoneField(
                    initial: _phone,
                    label: 'Phone',
                    onChanged: (v) => _phone = v,
                  ),
                ]),
                const SizedBox(height: 20),

                _section('Tax Registration (Canadian)', [
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextFormField(
                          controller: _bnCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Business Number (BN)',
                            hintText: '123456789',
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: _rtCtrl,
                          decoration: const InputDecoration(
                            labelText: 'RT',
                            hintText: '0001',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Your GST/HST number appears on invoices as '
                    '"BN: ${_bnCtrl.text.isEmpty ? "123456789" : _bnCtrl.text} '
                    'RT ${_rtCtrl.text.isEmpty ? "0001" : _rtCtrl.text}".',
                    style: TextStyle(
                      fontSize: 11,
                      color: cs.onSurface.withAlpha(140),
                    ),
                  ),
                ]),
                const SizedBox(height: 20),

                _section('Business Address', [
                  AddressForm(
                    initial: _address,
                    onChanged: (a) => _address = a,
                  ),
                ]),
                const SizedBox(height: 20),

                _section('Tax Rate', [
                  DropdownButtonFormField<String>(
                    initialValue: _province?.code ?? 'ON',
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Tax Province / Territory',
                    ),
                    items: Province.all
                        .map(
                          (p) => DropdownMenuItem(
                            value: p.code,
                            child: Text('${p.name}  —  ${p.taxDisplay}'),
                          ),
                        )
                        .toList(),
                    onChanged: (code) {
                      if (code != null) {
                        setState(() => _province = Province.fromCode(code));
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sets the tax rate on NEW invoices. Existing invoices '
                    'keep their original rate.',
                    style: TextStyle(
                      fontSize: 11,
                      color: cs.onSurface.withAlpha(140),
                    ),
                  ),
                ]),
                const SizedBox(height: 24),

                FilledButton(
                  onPressed: _saving ? null : () => _save(company),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save Changes'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _section(String title, List<Widget> children) => Card(
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
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    ),
  );

  Future<void> _save(Map<String, dynamic> company) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final province = _province ?? Province.fromCode('ON');
      await ref.read(companyProvider.notifier).updateProfile({
        'name': _nameCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'phone': _phone,
        'business_number': _bnCtrl.text.trim(),
        'rt_number': _rtCtrl.text.trim(),
        'province': province.code,
        'tax_rate': province.taxRate,
        'tax_label': province.taxLabel,
        ..._address.toMap(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(
            const SnackBar(content: Text('Company profile saved')),
          );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
