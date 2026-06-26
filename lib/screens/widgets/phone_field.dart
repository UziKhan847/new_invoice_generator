import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:new_invoice_generator/models/phone_country.dart';

/// A phone input with a country-code selector and live formatting/validation.
/// Reports the stored display string ("+1 (905) 345-3049") via [onChanged].
/// Pass [required] to make an empty value invalid.
class PhoneField extends StatefulWidget {
  final String initial; // stored phone, e.g. "+1 (905) 345-3049"
  final ValueChanged<String>
  onChanged; // emits formatted display string ('' if empty)
  final bool required;
  final String? label;

  const PhoneField({
    super.key,
    this.initial = '',
    required this.onChanged,
    this.required = false,
    this.label = 'Phone',
  });

  @override
  State<PhoneField> createState() => _PhoneFieldState();
}

class _PhoneFieldState extends State<PhoneField> {
  late PhoneCountry _country;
  late TextEditingController _ctrl;
  String? _error;

  @override
  void initState() {
    super.initState();
    final (country, national) = PhoneCountry.parse(widget.initial);
    _country = country;
    _ctrl = TextEditingController(
      text: national.isEmpty ? '' : _country.formatNational(national),
    );
    _validateAndEmit(silent: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _validateAndEmit({bool silent = false}) {
    final raw = _ctrl.text;
    final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');

    if (digits.isEmpty) {
      setState(() => _error = widget.required ? 'Phone is required' : null);
      widget.onChanged('');
      return;
    }
    if (!_country.isValidNational(digits)) {
      setState(
        () => _error = silent
            ? null
            : 'Expected ${_country.nationalDigits} digits for ${_country.name}',
      );
      widget.onChanged(''); // invalid → emit empty so save logic can catch it
      return;
    }
    setState(() => _error = null);
    widget.onChanged(_country.fullDisplay(digits));
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Country code selector ──────────────────────────────
            Container(
              margin: const EdgeInsets.only(top: 0),
              decoration: BoxDecoration(
                color: cs.surfaceContainerLow,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _error != null ? cs.error : cs.outlineVariant,
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _country.code,
                  borderRadius: BorderRadius.circular(12),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  items: PhoneCountry.all
                      .map(
                        (c) => DropdownMenuItem(
                          value: c.code,
                          child: Text(
                            '${c.flag} ${c.dialCode}',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      )
                      .toList(),
                  selectedItemBuilder: (_) => PhoneCountry.all
                      .map(
                        (c) => Container(
                          alignment: Alignment.center,
                          child: Text(
                            '${c.flag} ${c.dialCode}',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (code) {
                    if (code != null) {
                      setState(() => _country = PhoneCountry.byCode(code));
                      _validateAndEmit();
                    }
                  },
                ),
              ),
            ),
            const SizedBox(width: 8),
            // ── National number field ──────────────────────────────
            Expanded(
              child: TextFormField(
                controller: _ctrl,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  // Allow only digits, spaces, dashes, parens
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9 ()\-]')),
                  LengthLimitingTextInputFormatter(20),
                ],
                decoration: InputDecoration(
                  labelText: widget.label == null
                      ? null
                      : widget.label! + (widget.required ? ' *' : ''),
                  hintText: _country.example,
                  errorText: _error,
                  prefixIcon: const Icon(Icons.phone_outlined),
                ),
                onChanged: (_) => _validateAndEmit(),
                onEditingComplete: () {
                  // Auto-format on done if valid
                  final digits = _ctrl.text.replaceAll(RegExp(r'[^0-9]'), '');
                  if (_country.isValidNational(digits)) {
                    _ctrl.text = _country.formatNational(digits);
                    _ctrl.selection = TextSelection.collapsed(
                      offset: _ctrl.text.length,
                    );
                  }
                  FocusScope.of(context).unfocus();
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}
