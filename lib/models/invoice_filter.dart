class InvoiceFilter {
  final String? customerId;
  final String? customerName;
  final String? senderEmployeeId;
  final String? senderName;
  final String? serviceId; // filter by item description matching service name
  final String? serviceName;
  final int? month; // 1-12
  final int? year;
  final bool? isPaid;

  const InvoiceFilter({
    this.customerId,
    this.customerName,
    this.senderEmployeeId,
    this.senderName,
    this.serviceId,
    this.serviceName,
    this.month,
    this.year,
    this.isPaid,
  });

  bool get isActive =>
      customerId != null ||
      senderEmployeeId != null ||
      serviceId != null ||
      month != null ||
      year != null ||
      isPaid != null;

  InvoiceFilter copyWith({
    String? customerId,
    String? customerName,
    String? senderEmployeeId,
    String? senderName,
    String? serviceId,
    String? serviceName,
    int? month,
    int? year,
    bool? isPaid,
    bool clearCustomer = false,
    bool clearSender = false,
    bool clearService = false,
    bool clearMonth = false,
    bool clearYear = false,
    bool clearStatus = false,
  }) {
    return InvoiceFilter(
      customerId: clearCustomer ? null : (customerId ?? this.customerId),
      customerName: clearCustomer ? null : (customerName ?? this.customerName),
      senderEmployeeId: clearSender
          ? null
          : (senderEmployeeId ?? this.senderEmployeeId),
      senderName: clearSender ? null : (senderName ?? this.senderName),
      serviceId: clearService ? null : (serviceId ?? this.serviceId),
      serviceName: clearService ? null : (serviceName ?? this.serviceName),
      month: clearMonth ? null : (month ?? this.month),
      year: clearYear ? null : (year ?? this.year),
      isPaid: clearStatus ? null : (isPaid ?? this.isPaid),
    );
  }

  InvoiceFilter clear() => const InvoiceFilter();
}
