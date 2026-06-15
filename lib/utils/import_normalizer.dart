import 'package:new_invoice_generator/models/phone_country.dart';
import 'package:new_invoice_generator/models/province.dart';

/// Normalises messy imported data (province spellings, country codes, phone
/// formats) into the app's canonical forms.
class ImportNormalizer {
  ImportNormalizer._();

  /// Map of common province spellings/abbreviations → canonical 2-letter code.
  static const Map<String, String> _provinceAliases = {
    // Ontario
    'on': 'ON', 'ont': 'ON', 'ontario': 'ON',
    // Quebec
    'qc': 'QC', 'que': 'QC', 'quebec': 'QC', 'québec': 'QC', 'pq': 'QC',
    // British Columbia
    'bc': 'BC', 'b.c.': 'BC', 'british columbia': 'BC',
    // Alberta
    'ab': 'AB', 'alta': 'AB', 'alberta': 'AB',
    // Manitoba
    'mb': 'MB', 'man': 'MB', 'manitoba': 'MB',
    // Saskatchewan
    'sk': 'SK', 'sask': 'SK', 'saskatchewan': 'SK',
    // Nova Scotia
    'ns': 'NS', 'nova scotia': 'NS',
    // New Brunswick
    'nb': 'NB', 'new brunswick': 'NB',
    // Newfoundland
    'nl': 'NL', 'nf': 'NL', 'nfld': 'NL', 'newfoundland': 'NL',
    'newfoundland and labrador': 'NL', 'newfoundland & labrador': 'NL',
    // PEI
    'pe': 'PE', 'pei': 'PE', 'prince edward island': 'PE', 'p.e.i.': 'PE',
    // Territories
    'yt': 'YT', 'yukon': 'YT',
    'nt': 'NT', 'nwt': 'NT', 'northwest territories': 'NT',
    'nu': 'NU', 'nunavut': 'NU',
  };

  /// Returns the canonical province code (e.g. 'ON') or the original trimmed
  /// string if no Canadian match is found (for non-Canadian regions).
  static String province(String? raw) {
    final s = (raw ?? '').trim();
    if (s.isEmpty) return '';
    final key = s.toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
    final code = _provinceAliases[key];
    if (code != null) return code;
    // Maybe it's already a valid code in different case
    final upper = s.toUpperCase();
    for (final p in Province.all) {
      if (p.code == upper) return p.code;
    }
    // Unknown (e.g. a US state) — keep as-is
    return s;
  }

  /// Normalises country names/codes to a full country name.
  static String country(String? raw, {String? countryCode}) {
    final s = (raw ?? '').trim();
    final cc = (countryCode ?? '').trim().toUpperCase();
    // Prefer explicit 2-letter code
    if (cc == 'CA') return 'Canada';
    if (cc == 'US' || cc == 'USA') return 'United States';
    final lower = s.toLowerCase();
    if (lower.isEmpty && cc.isEmpty) return 'Canada';
    if (['ca', 'can', 'canada'].contains(lower)) return 'Canada';
    if ([
      'us',
      'usa',
      'u.s.',
      'u.s.a.',
      'united states',
      'united states of america',
      'america',
    ].contains(lower)) {
      return 'United States';
    }
    return s.isEmpty ? 'Canada' : s;
  }

  /// Normalises a phone number to the app's stored display format.
  /// Tries to infer the country from the given country code or the digits.
  /// Returns '' if it can't form a valid number.
  static String phone(String? raw, {String? countryCode}) {
    final s = (raw ?? '').trim();
    if (s.isEmpty) return '';

    final digits = s.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return '';

    // Determine the country to use for formatting
    PhoneCountry? country;
    final cc = (countryCode ?? '').trim().toUpperCase();
    if (cc.isNotEmpty) {
      for (final c in PhoneCountry.all) {
        if (c.code == cc) {
          country = c;
          break;
        }
      }
    }

    // Handle leading international prefixes in the digits themselves
    String national = digits;
    if (country == null) {
      // Try to detect by dial code prefix
      final sorted = [...PhoneCountry.all]
        ..sort((a, b) => b.dialCode.length.compareTo(a.dialCode.length));
      for (final c in sorted) {
        final dc = c.dialCode.replaceAll('+', '');
        if (digits.length > c.nationalDigits && digits.startsWith(dc)) {
          final rest = digits.substring(dc.length);
          if (rest.length == c.nationalDigits) {
            country = c;
            national = rest;
            break;
          }
        }
      }
      // Default to Canada (NANP)
      country ??= PhoneCountry.all.first;
    }

    // For +1 (NANP): an 11-digit number starting with 1 → drop the 1
    if (country.dialCode == '+1' &&
        national.length == 11 &&
        national.startsWith('1')) {
      national = national.substring(1);
    }

    if (!country.isValidNational(national)) return '';
    return country.fullDisplay(national);
  }

  /// Combine first + last name parts into a single full name.
  static String fullName(String? first, String? last) {
    final f = (first ?? '').trim();
    final l = (last ?? '').trim();
    return [f, l].where((p) => p.isNotEmpty).join(' ');
  }

  /// Combine two address lines into one street line.
  static String streetLine(String? line1, String? line2) {
    final a = (line1 ?? '').trim();
    final b = (line2 ?? '').trim();
    return [a, b].where((p) => p.isNotEmpty).join(', ');
  }

  /// Normalise a postal code: uppercase, single space for Canadian format.
  static String postalCode(String? raw) {
    final s = (raw ?? '').trim().toUpperCase();
    if (s.isEmpty) return '';
    // Canadian A1A1A1 → A1A 1A1
    final compact = s.replaceAll(RegExp(r'\s+'), '');
    final caRe = RegExp(r'^[A-Z]\d[A-Z]\d[A-Z]\d$');
    if (caRe.hasMatch(compact)) {
      return '${compact.substring(0, 3)} ${compact.substring(3)}';
    }
    return s;
  }
}
