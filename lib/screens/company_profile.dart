import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:new_invoice_generator/main.dart';
import 'package:new_invoice_generator/models/province.dart';
import 'package:new_invoice_generator/providers/company.dart';
import 'package:new_invoice_generator/widgets/primary_button.dart';

class CompanyProfileScreen extends ConsumerStatefulWidget {
  const CompanyProfileScreen({super.key});

  @override
  ConsumerState<CompanyProfileScreen> createState() =>
      _CompanyProfileScreenState();
}

class _CompanyProfileScreenState extends ConsumerState<CompanyProfileScreen> {
  final _nameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _taxNumCtrl = TextEditingController();
  Province? _province;
  bool _initialized = false;
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _taxNumCtrl.dispose();
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
            _addressCtrl.text = company['address'] as String? ?? '';
            _emailCtrl.text = company['email'] as String? ?? '';
            _phoneCtrl.text = company['phone'] as String? ?? '';
            _taxNumCtrl.text = company['tax_number'] as String? ?? '';
            _province = Province.fromCode(
              company['province'] as String? ?? 'ON',
            );
            _initialized = true;
          }

          return ListView(
            padding: EdgeInsets.fromLTRB(16, 16, 16, bottom + 24),
            children: [
              // ── Company details ──────────────────────────────────
              _section('Company Details', [
                TextField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(labelText: 'Company Name'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _addressCtrl,
                  decoration: const InputDecoration(labelText: 'Address'),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Phone'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _taxNumCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Tax / Business Number',
                    hintText: 'e.g. 123456789 RT 0001',
                  ),
                ),
              ]),
              const SizedBox(height: 20),

              // ── Province & Tax ───────────────────────────────────
              _section('Province & Tax Rate', [
                DropdownButtonFormField<String>(
                  initialValue: _province?.code ?? 'ON',
                  decoration: const InputDecoration(
                    labelText: 'Province / Territory',
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
                const SizedBox(height: 10),
                if (_province != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: cs.primaryContainer.withAlpha(60),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'New invoices will use:',
                          style: TextStyle(
                            fontSize: 12,
                            color: cs.onSurface.withAlpha(150),
                          ),
                        ),
                        Text(
                          _province!.taxDisplay,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 8),
                Text(
                  'Note: changing the province only affects new invoices. '
                  'Existing invoices keep their original tax rate.',
                  style: TextStyle(
                    fontSize: 11,
                    color: cs.onSurface.withAlpha(120),
                  ),
                ),
              ]),
              const SizedBox(height: 24),

              PrimaryButton(
                text: _saving ? 'Saving…' : 'Save Changes',
                onPressed: _saving ? () {} : () => _save(company),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _section(String title, List<Widget> children) {
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
            const SizedBox(height: 14),
            ...children,
          ],
        ),
      ),
    );
  }

  Future<void> _save(Map<String, dynamic> company) async {
    setState(() => _saving = true);
    try {
      final province = _province ?? Province.fromCode('ON');
      await supabase
          .from('companies')
          .update({
            'name': _nameCtrl.text.trim(),
            'address': _addressCtrl.text.trim(),
            'email': _emailCtrl.text.trim(),
            'phone': _phoneCtrl.text.trim(),
            'tax_number': _taxNumCtrl.text.trim(),
            'province': province.code,
            'tax_rate': province.taxRate,
            'tax_label': province.taxLabel,
          })
          .eq('id', company['id']);
      ref.invalidate(companyProvider);
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
