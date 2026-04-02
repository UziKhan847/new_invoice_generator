class Service {
  final String id;
  final String name;
  final String? description;
  final double unitPrice;
  // fixed | hourly | daily | weekly | 4_weekly | monthly | yearly
  final String rateType;

  Service({
    required this.id,
    required this.name,
    this.description,
    required this.unitPrice,
    this.rateType = 'fixed',
  });

  String get rateLabel {
    switch (rateType) {
      case 'hourly':   return '/hr';
      case 'daily':    return '/day';
      case 'weekly':   return '/wk';
      case '4_weekly': return '/4wk';
      case 'monthly':  return '/mo';
      case 'yearly':   return '/yr';
      default:         return '';
    }
  }

  factory Service.fromJson(Map<String, dynamic> json) {
    return Service(
      id: json['id'] as String,
      name: json['name'] ?? '',
      description: json['description'] as String?,
      unitPrice: (json['unit_price'] as num).toDouble(),
      rateType: json['rate_type'] as String? ?? 'fixed',
    );
  }

  Map<String, dynamic> toInsertMap(String companyId) {
    return {
      'company_id': companyId,
      'name': name,
      'description': description,
      'unit_price': unitPrice,
      'rate_type': rateType,
    };
  }
}