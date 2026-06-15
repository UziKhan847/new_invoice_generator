/// A country dialing code with its national-number validation rules.
class PhoneCountry {
  final String code; // ISO code e.g. 'CA'
  final String name; // 'Canada'
  final String dialCode; // '+1'
  final String flag; // 🇨🇦
  final int nationalDigits; // expected # of digits after the dial code
  final String example; // formatting example shown as hint

  const PhoneCountry({
    required this.code,
    required this.name,
    required this.dialCode,
    required this.flag,
    required this.nationalDigits,
    required this.example,
  });

  /// Strip all non-digits and validate the count for this country.
  bool isValidNational(String input) {
    final digits = input.replaceAll(RegExp(r'[^0-9]'), '');
    return digits.length == nationalDigits;
  }

  /// Format the national number nicely for North America: (905) 345-3049
  /// Other countries: grouped in a generic readable way.
  String formatNational(String input) {
    final d = input.replaceAll(RegExp(r'[^0-9]'), '');
    if (dialCode == '+1' && d.length == 10) {
      return '(${d.substring(0, 3)}) ${d.substring(3, 6)}-${d.substring(6)}';
    }
    return d;
  }

  /// Full E.164-ish stored form: "+1 (905) 345-3049"
  String fullDisplay(String input) {
    final national = formatNational(input);
    return '$dialCode $national';
  }

  /// E.164 canonical: "+19053453049"
  String e164(String input) {
    final d = input.replaceAll(RegExp(r'[^0-9]'), '');
    return '$dialCode$d'.replaceAll(' ', '');
  }

  static const List<PhoneCountry> all = [
    PhoneCountry(
      code: 'CA',
      name: 'Canada',
      dialCode: '+1',
      flag: '🇨🇦',
      nationalDigits: 10,
      example: '(905) 345-3049',
    ),
    PhoneCountry(
      code: 'US',
      name: 'United States',
      dialCode: '+1',
      flag: '🇺🇸',
      nationalDigits: 10,
      example: '(212) 555-0199',
    ),
    PhoneCountry(
      code: 'GB',
      name: 'United Kingdom',
      dialCode: '+44',
      flag: '🇬🇧',
      nationalDigits: 10,
      example: '20 7946 0958',
    ),
    PhoneCountry(
      code: 'PK',
      name: 'Pakistan',
      dialCode: '+92',
      flag: '🇵🇰',
      nationalDigits: 10,
      example: '301 2345678',
    ),
    PhoneCountry(
      code: 'IN',
      name: 'India',
      dialCode: '+91',
      flag: '🇮🇳',
      nationalDigits: 10,
      example: '98765 43210',
    ),
    PhoneCountry(
      code: 'AU',
      name: 'Australia',
      dialCode: '+61',
      flag: '🇦🇺',
      nationalDigits: 9,
      example: '412 345 678',
    ),
    PhoneCountry(
      code: 'AE',
      name: 'UAE',
      dialCode: '+971',
      flag: '🇦🇪',
      nationalDigits: 9,
      example: '50 123 4567',
    ),
    PhoneCountry(
      code: 'SA',
      name: 'Saudi Arabia',
      dialCode: '+966',
      flag: '🇸🇦',
      nationalDigits: 9,
      example: '51 234 5678',
    ),
    PhoneCountry(
      code: 'DE',
      name: 'Germany',
      dialCode: '+49',
      flag: '🇩🇪',
      nationalDigits: 11,
      example: '1512 3456789',
    ),
    PhoneCountry(
      code: 'FR',
      name: 'France',
      dialCode: '+33',
      flag: '🇫🇷',
      nationalDigits: 9,
      example: '6 12 34 56 78',
    ),
  ];

  static PhoneCountry byCode(String code) =>
      all.firstWhere((c) => c.code == code, orElse: () => all.first);

  /// Best-effort parse of a stored phone string like "+1 (905) 345-3049"
  /// back into (country, nationalDigits). Defaults to Canada.
  static (PhoneCountry, String) parse(String stored) {
    final s = stored.trim();
    if (s.isEmpty) return (all.first, '');
    // Try to match the longest dial code first
    final sorted = [...all]
      ..sort((a, b) => b.dialCode.length.compareTo(a.dialCode.length));
    for (final c in sorted) {
      if (s.startsWith(c.dialCode)) {
        final rest = s
            .substring(c.dialCode.length)
            .replaceAll(RegExp(r'[^0-9]'), '');
        if (rest.length == c.nationalDigits) return (c, rest);
      }
    }
    // No dial code — assume Canada, keep digits
    final digits = s.replaceAll(RegExp(r'[^0-9]'), '');
    // If 11 digits starting with 1, drop the leading 1
    if (digits.length == 11 && digits.startsWith('1')) {
      return (all.first, digits.substring(1));
    }
    return (all.first, digits);
  }
}
