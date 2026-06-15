/// Structured postal address used by both companies and customers.
class Address {
  final String line; // street address
  final String city;
  final String province; // province/state/region
  final String postalCode;
  final String country;

  const Address({
    this.line = '',
    this.city = '',
    this.province = '',
    this.postalCode = '',
    this.country = 'Canada',
  });

  bool get isEmpty =>
      line.isEmpty && city.isEmpty && province.isEmpty && postalCode.isEmpty;

  bool get isNotEmpty => !isEmpty;

  /// Multi-line formatted address for PDFs/display.
  /// e.g. "123 Main Street\nSpringfield, ON  A1A 1A1\nCanada"
  List<String> get lines {
    final out = <String>[];
    if (line.isNotEmpty) out.add(line);
    final cityProvPostal = [
      if (city.isNotEmpty) city,
      if (province.isNotEmpty) province,
    ].join(', ');
    final secondLine = [
      if (cityProvPostal.isNotEmpty) cityProvPostal,
      if (postalCode.isNotEmpty) postalCode,
    ].join('  ');
    if (secondLine.isNotEmpty) out.add(secondLine);
    if (country.isNotEmpty && country != 'Canada') out.add(country);
    return out;
  }

  String get singleLine => lines.join(', ');

  Address copyWith({
    String? line,
    String? city,
    String? province,
    String? postalCode,
    String? country,
  }) => Address(
    line: line ?? this.line,
    city: city ?? this.city,
    province: province ?? this.province,
    postalCode: postalCode ?? this.postalCode,
    country: country ?? this.country,
  );

  /// Build from a row using a column prefix (e.g. '' or 'customer_').
  factory Address.fromRow(Map<String, dynamic> json, {String prefix = ''}) =>
      Address(
        line: json['${prefix}address_line'] as String? ?? '',
        city: json['${prefix}city'] as String? ?? '',
        province: json['${prefix}province_region'] as String? ?? '',
        postalCode: json['${prefix}postal_code'] as String? ?? '',
        country: json['${prefix}country'] as String? ?? 'Canada',
      );

  Map<String, dynamic> toMap({String prefix = ''}) => {
    '${prefix}address_line': line.isEmpty ? null : line,
    '${prefix}city': city.isEmpty ? null : city,
    '${prefix}province_region': province.isEmpty ? null : province,
    '${prefix}postal_code': postalCode.isEmpty ? null : postalCode,
    '${prefix}country': country,
  };
}
