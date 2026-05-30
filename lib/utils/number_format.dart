/// Shared number/currency formatting helpers.
class NumFmt {
  NumFmt._();

  /// Display a quantity cleanly:
  ///   3.0   → "3"
  ///   3.5   → "3.5"
  ///   3.50  → "3.5"   (trailing zeros stripped)
  ///   3.25  → "3.25"
  static String quantity(double v) {
    if (v == v.truncateToDouble()) return v.toInt().toString();
    return v
        .toStringAsFixed(2)
        .replaceAll(RegExp(r'0+$'), '')
        .replaceAll(RegExp(r'\.$'), '');
  }

  /// Format a CAD amount with two decimals: "$1,234.56"
  static String money(double v) => '\$${v.toStringAsFixed(2)}';

  /// Format a percentage cleanly:
  ///   0.13   → "13%"
  ///   0.05   → "5%"
  ///   0.14975 → "14.975%"
  static String percent(double rate) {
    final pct = rate * 100;
    if (pct == pct.truncateToDouble()) return '${pct.toInt()}%';
    return '${pct.toStringAsFixed(3).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '')}%';
  }
}
