class ServiceCustomerLink {
  final String? id;
  final String companyId;
  final String serviceId;
  final String customerId;
  final double? customPrice;
  final String? notes;

  // Joined fields (populated by queries)
  final String? serviceName;
  final double? serviceDefaultPrice;
  final String? customerName;

  ServiceCustomerLink({
    this.id,
    required this.companyId,
    required this.serviceId,
    required this.customerId,
    this.customPrice,
    this.notes,
    this.serviceName,
    this.serviceDefaultPrice,
    this.customerName,
  });

  double get effectivePrice => customPrice ?? serviceDefaultPrice ?? 0;

  factory ServiceCustomerLink.fromJson(Map<String, dynamic> json) {
    return ServiceCustomerLink(
      id: json['id'],
      companyId: json['company_id'],
      serviceId: json['service_id'],
      customerId: json['customer_id'],
      customPrice: json['custom_price'] != null
          ? (json['custom_price'] as num).toDouble()
          : null,
      notes: json['notes'],
      serviceName: json['services'] != null ? json['services']['name'] : null,
      serviceDefaultPrice: json['services'] != null
          ? (json['services']['unit_price'] as num).toDouble()
          : null,
      customerName:
          json['customers'] != null ? json['customers']['name'] : null,
    );
  }

  Map<String, dynamic> toInsertMap(String companyId) {
    return {
      'company_id': companyId,
      'service_id': serviceId,
      'customer_id': customerId,
      'custom_price': customPrice,
      'notes': notes,
    };
  }
}