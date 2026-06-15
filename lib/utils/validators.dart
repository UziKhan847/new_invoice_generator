/// Form field validators returning null when valid, or an error message.
class Validators {
  Validators._();

  static final _emailRe = RegExp(
    r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)+$",
  );

  static final _postalCaRe = RegExp(
    r'^[ABCEGHJ-NPRSTVXY]\d[ABCEGHJ-NPRSTV-Z][ ]?\d[ABCEGHJ-NPRSTV-Z]\d$',
    caseSensitive: false,
  );

  /// Required + valid email.
  static String? email(String? v, {bool required = true}) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return required ? 'Email is required' : null;
    if (!_emailRe.hasMatch(s)) return 'Enter a valid email address';
    return null;
  }

  /// Required non-empty text.
  static String? required(String? v, {String field = 'This field'}) {
    if ((v ?? '').trim().isEmpty) return '$field is required';
    return null;
  }

  /// Optional Canadian postal code (e.g. A1A 1A1). Empty is allowed.
  static String? postalCodeCa(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return null;
    if (!_postalCaRe.hasMatch(s)) {
      return 'Enter a valid postal code (e.g. A1A 1A1)';
    }
    return null;
  }

  /// Optional phone — allows digits, spaces, +, -, (), min 7 digits.
  static String? phone(String? v, {bool required = false}) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return required ? 'Phone is required' : null;
    final digits = s.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length < 7) return 'Enter a valid phone number';
    return null;
  }

  /// Optional positive number.
  static String? positiveNumber(
    String? v, {
    bool required = true,
    String field = 'Amount',
  }) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return required ? '$field is required' : null;
    final n = double.tryParse(s);
    if (n == null) return 'Enter a valid number';
    if (n < 0) return '$field cannot be negative';
    return null;
  }
}
