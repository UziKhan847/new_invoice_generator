import 'package:flutter/material.dart';
import 'package:new_invoice_generator/models/address.dart';
import 'package:new_invoice_generator/models/province.dart';
import 'package:new_invoice_generator/utils/validators.dart';

/// A reusable structured-address input. Reports changes via [onChanged].
/// Country defaults to Canada with a province dropdown; switching country
/// to anything else turns province into a free-text field.
class AddressForm extends StatefulWidget {
  final Address initial;
  final ValueChanged<Address> onChanged;
  const AddressForm({
    super.key,
    required this.initial,
    required this.onChanged,
  });

  @override
  State<AddressForm> createState() => _AddressFormState();
}

class _AddressFormState extends State<AddressForm> {
  late TextEditingController _lineCtrl;
  late TextEditingController _cityCtrl;
  late TextEditingController _postalCtrl;
  late TextEditingController _provinceFreeCtrl;
  late String _country;
  String? _provinceCode;

  static const _countries = ['Canada', 'United States', 'Other'];

  @override
  void initState() {
    super.initState();
    final a = widget.initial;
    _lineCtrl = TextEditingController(text: a.line);
    _cityCtrl = TextEditingController(text: a.city);
    _postalCtrl = TextEditingController(text: a.postalCode);
    _provinceFreeCtrl = TextEditingController(text: a.province);
    _country = _countries.contains(a.country) ? a.country : 'Other';
    if (_country == 'Canada' && a.province.isNotEmpty) {
      final match = Province.all.where(
        (p) => p.code == a.province || p.name == a.province,
      );
      _provinceCode = match.isNotEmpty ? match.first.code : null;
    }
  }

  @override
  void dispose() {
    _lineCtrl.dispose();
    _cityCtrl.dispose();
    _postalCtrl.dispose();
    _provinceFreeCtrl.dispose();
    super.dispose();
  }

  void _emit() {
    final province = _country == 'Canada'
        ? (_provinceCode ?? '')
        : _provinceFreeCtrl.text.trim();
    widget.onChanged(
      Address(
        line: _lineCtrl.text.trim(),
        city: _cityCtrl.text.trim(),
        province: province,
        postalCode: _postalCtrl.text.trim(),
        country: _country,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextFormField(
          controller: _lineCtrl,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Street address',
            hintText: '123 Main Street',
            prefixIcon: Icon(Icons.location_on_outlined),
          ),
          onChanged: (_) => _emit(),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              flex: 3,
              child: TextFormField(
                controller: _cityCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'City'),
                onChanged: (_) => _emit(),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: _country == 'Canada'
                  ? DropdownButtonFormField<String>(
                      initialValue: _provinceCode,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Prov.'),
                      items: Province.all
                          .map(
                            (p) => DropdownMenuItem(
                              value: p.code,
                              child: Text(p.code),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        setState(() => _provinceCode = v);
                        _emit();
                      },
                    )
                  : TextFormField(
                      controller: _provinceFreeCtrl,
                      decoration: const InputDecoration(
                        labelText: 'State/Region',
                      ),
                      onChanged: (_) => _emit(),
                    ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _postalCtrl,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'Postal code',
                  hintText: 'A1A 1A1',
                ),
                validator: _country == 'Canada'
                    ? Validators.postalCodeCa
                    : null,
                onChanged: (_) => _emit(),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: _country,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Country'),
                items: _countries
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) {
                  setState(() {
                    _country = v ?? 'Canada';
                    if (_country != 'Canada') _provinceCode = null;
                  });
                  _emit();
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}
