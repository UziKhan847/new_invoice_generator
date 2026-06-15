/// How tax is applied to an invoice.
enum TaxMode {
  /// Use the company's province tax rate + label (e.g. HST 13%).
  standard,

  /// 0% tax, but still labelled as the standard tax (e.g. "HST (0%)").
  /// Useful for tax-exempt sales that must still show the tax line at zero.
  zeroRated,

  /// International export — 0% tax, labelled as an export.
  export,

  /// A custom percentage with a custom label (e.g. "Service Tax 8%").
  custom,
}

extension TaxModeX on TaxMode {
  String get id => name;

  static TaxMode fromId(String? v) => switch (v) {
    'zeroRated' => TaxMode.zeroRated,
    'export' => TaxMode.export,
    'custom' => TaxMode.custom,
    _ => TaxMode.standard,
  };

  String get title => switch (this) {
    TaxMode.standard => 'Standard',
    TaxMode.zeroRated => 'Zero-rated (0%)',
    TaxMode.export => 'International',
    TaxMode.custom => 'Custom',
  };
}
