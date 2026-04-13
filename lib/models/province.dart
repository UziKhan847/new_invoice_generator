/// Canadian provinces/territories with their tax rates and labels.
class Province {
  final String code;
  final String name;
  final double taxRate;
  final String taxLabel;

  const Province({
    required this.code,
    required this.name,
    required this.taxRate,
    required this.taxLabel,
  });

  String get taxDisplay =>
      '${(taxRate * 100).toStringAsFixed(taxRate * 100 == (taxRate * 100).truncate() ? 0 : 3)}% $taxLabel';

  static const List<Province> all = [
    Province(code: 'ON', name: 'Ontario', taxRate: 0.13, taxLabel: 'HST'),
    Province(code: 'NS', name: 'Nova Scotia', taxRate: 0.15, taxLabel: 'HST'),
    Province(code: 'NB', name: 'New Brunswick', taxRate: 0.15, taxLabel: 'HST'),
    Province(
      code: 'NL',
      name: 'Newfoundland & Labrador',
      taxRate: 0.15,
      taxLabel: 'HST',
    ),
    Province(
      code: 'PE',
      name: 'Prince Edward Island',
      taxRate: 0.15,
      taxLabel: 'HST',
    ),
    Province(
      code: 'BC',
      name: 'British Columbia',
      taxRate: 0.12,
      taxLabel: 'GST + PST',
    ),
    Province(
      code: 'MB',
      name: 'Manitoba',
      taxRate: 0.12,
      taxLabel: 'GST + PST',
    ),
    Province(
      code: 'SK',
      name: 'Saskatchewan',
      taxRate: 0.11,
      taxLabel: 'GST + PST',
    ),
    Province(
      code: 'QC',
      name: 'Quebec',
      taxRate: 0.14975,
      taxLabel: 'GST + QST',
    ),
    Province(code: 'AB', name: 'Alberta', taxRate: 0.05, taxLabel: 'GST'),
    Province(code: 'YT', name: 'Yukon', taxRate: 0.05, taxLabel: 'GST'),
    Province(
      code: 'NT',
      name: 'Northwest Territories',
      taxRate: 0.05,
      taxLabel: 'GST',
    ),
    Province(code: 'NU', name: 'Nunavut', taxRate: 0.05, taxLabel: 'GST'),
  ];

  static Province fromCode(String code) => all.firstWhere(
    (p) => p.code == code,
    orElse: () => all.first,
  ); // default Ontario
}
