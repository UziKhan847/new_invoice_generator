class RecurringInvoice {
  final String? id;
  final String companyId;
  final String customerId;
  final String? customerName; // joined
  final String? serviceId;
  final String? serviceName;  // joined
  final String? senderEmployeeId;
  final String? senderName;   // joined
  final String label;
  final double price;
  final String frequency;
  final int? dayOfMonth;
  final DateTime? lastGeneratedAt;
  final DateTime? nextDueDate;
  final bool isActive;
  final String rateType; // from linked service: hourly, weekly, etc.

  RecurringInvoice({
    this.id,
    required this.companyId,
    required this.customerId,
    this.customerName,
    this.serviceId,
    this.serviceName,
    this.senderEmployeeId,
    this.senderName,
    required this.label,
    required this.price,
    required this.frequency,
    this.dayOfMonth,
    this.lastGeneratedAt,
    this.nextDueDate,
    this.isActive = true,
    this.rateType = 'fixed',
  });

  factory RecurringInvoice.fromJson(Map<String, dynamic> json) {
    final cust = json['customers'] as Map<String, dynamic>?;
    final svc  = json['services']  as Map<String, dynamic>?;
    final emp  = json['employees'] as Map<String, dynamic>?;
    return RecurringInvoice(
      id: json['id'],
      companyId: json['company_id'],
      customerId: json['customer_id'],
      customerName: cust?['name'] as String?,
      serviceId: json['service_id'],
      serviceName: svc?['name'] as String?,
      senderEmployeeId: json['sender_employee_id'] as String?,
      senderName: emp?['name'] as String?,
      label: json['label'] ?? '',
      price: (json['price'] as num).toDouble(),
      frequency: json['frequency'] ?? 'monthly',
      dayOfMonth: json['day_of_month'] as int?,
      lastGeneratedAt: json['last_generated_at'] != null
          ? DateTime.parse(json['last_generated_at'])
          : null,
      nextDueDate: json['next_due_date'] != null
          ? DateTime.parse(json['next_due_date'])
          : null,
      isActive: json['is_active'] ?? true,
      rateType: (json['services'] as Map<String, dynamic>?)?['rate_type'] as String? ?? 'fixed',
    );
  }

  Map<String, dynamic> toInsertMap(String companyId) {
    return {
      'company_id': companyId,
      'customer_id': customerId,
      'service_id': serviceId,
      'sender_employee_id': senderEmployeeId,
      'label': label,
      'price': price,
      'frequency': frequency,
      'day_of_month': dayOfMonth,
      'next_due_date': nextDueDate?.toIso8601String().split('T')[0],
      'is_active': isActive,
    };
  }

  static DateTime computeNextDue(String frequency, {DateTime? from}) {
    final base = from ?? DateTime.now();
    switch (frequency) {
      case 'weekly':   return base.add(const Duration(days: 7));
      case '4_weekly': return base.add(const Duration(days: 28));
      case 'monthly':  return DateTime(base.year, base.month + 1, base.day);
      case 'yearly':   return DateTime(base.year + 1, base.month, base.day);
      default:         return DateTime(base.year, base.month + 1, base.day);
    }
  }

  String get frequencyLabel {
    switch (frequency) {
      case 'weekly':   return 'Weekly';
      case '4_weekly': return 'Every 4 Weeks';
      case 'monthly':  return 'Monthly';
      case 'yearly':   return 'Yearly';
      default:         return frequency;
    }
  }

  RecurringInvoice copyWith({
    String? rateType,
    String? label,
    double? price,
    String? frequency,
    String? senderEmployeeId,
    String? customerName,
    DateTime? nextDueDate,
  }) {
    return RecurringInvoice(
      id: id,
      companyId: companyId,
      customerId: customerId,
      customerName: customerName ?? this.customerName,
      serviceId: serviceId,
      serviceName: serviceName,
      senderEmployeeId: senderEmployeeId ?? this.senderEmployeeId,
      senderName: senderName,
      label: label ?? this.label,
      price: price ?? this.price,
      frequency: frequency ?? this.frequency,
      dayOfMonth: dayOfMonth,
      lastGeneratedAt: lastGeneratedAt,
      nextDueDate: nextDueDate ?? this.nextDueDate,
      isActive: isActive,
      rateType: rateType ?? this.rateType,
    );
  }

  /// Human label for one unit of this service (used in generate dialog)
  String get frequencyUnitLabel {
    switch (rateType) {
      case 'hourly':   return 'hrs';
      case 'daily':    return 'days';
      case 'weekly':   return 'wks';
      case '4_weekly': return '4-wk periods';
      case 'monthly':  return 'months';
      case 'yearly':   return 'years';
      default:         return 'units';
    }
  }
}