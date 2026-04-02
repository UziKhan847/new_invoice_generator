import 'invoice_item.dart';

class Invoice {
  final String? id;
  final String invoiceNumber;
  final String customerName;
  final String? customerId;
  final String? customerEmail; // auto-filled for email dialog
  final DateTime issueDate;
  final DateTime? dueDate;
  final bool isPaid;
  final String status;
  final List<InvoiceItem> items;
  // Sender (employee) — optional
  final String? senderEmployeeId;
  final String? senderName;
  final String? senderRole;
  final String? senderEmail;
  // Company logo — injected at PDF generation time
  final String? companyLogoUrl;

  Invoice({
    this.id,
    required this.invoiceNumber,
    required this.customerName,
    this.customerId,
    this.customerEmail,
    required this.items,
    DateTime? issueDate,
    this.dueDate,
    this.isPaid = false,
    this.status = 'unpaid',
    this.senderEmployeeId,
    this.senderName,
    this.senderRole,
    this.senderEmail,
    this.companyLogoUrl,
  }) : issueDate = issueDate ?? DateTime.now();

  double get subtotal => items.fold(0, (sum, item) => sum + item.total);
  double get tax => subtotal * 0.13;
  double get total => subtotal + tax;

  factory Invoice.fromJson(Map<String, dynamic> json) {
    final itemsJson = json['invoice_items'] as List? ?? [];
    final emp  = json['employees']  as Map<String, dynamic>?;
    final cust = json['customers']  as Map<String, dynamic>?;
    return Invoice(
      id: json['id'],
      invoiceNumber: json['invoice_number'] ?? '',
      customerName: json['customer_name'] ?? '',
      customerId: json['customer_id'] as String?,
      customerEmail: cust?['email'] as String? ?? json['customer_email'] as String?,
      issueDate: DateTime.parse(json['issue_date'] ?? json['created_at']),
      dueDate: json['due_date'] != null ? DateTime.parse(json['due_date']) : null,
      isPaid: json['is_paid'] ?? false,
      status: json['status'] ?? 'unpaid',
      items: itemsJson.map((item) => InvoiceItem.fromJson(item)).toList(),
      senderEmployeeId: json['sender_employee_id'] as String?,
      senderName: emp?['name'] as String?,
      senderRole: emp?['role'] as String?,
      senderEmail: emp?['email'] as String?,
    );
  }

  Map<String, dynamic> toInsertMap(String companyId) {
    return {
      'company_id': companyId,
      'invoice_number': invoiceNumber,
      'customer_name': customerName,
      'customer_id': customerId,
      'issue_date': issueDate.toIso8601String().split('T')[0],
      'due_date': dueDate?.toIso8601String().split('T')[0],
      'subtotal': subtotal,
      'tax': tax,
      'total': total,
      'is_paid': isPaid,
      'status': status,
      'sender_employee_id': senderEmployeeId,
    };
  }

  Invoice copyWith({String? companyLogoUrl}) {
    return Invoice(
      id: id,
      invoiceNumber: invoiceNumber,
      customerName: customerName,
      customerId: customerId,
      customerEmail: customerEmail,
      items: items,
      issueDate: issueDate,
      dueDate: dueDate,
      isPaid: isPaid,
      status: status,
      senderEmployeeId: senderEmployeeId,
      senderName: senderName,
      senderRole: senderRole,
      senderEmail: senderEmail,
      companyLogoUrl: companyLogoUrl ?? this.companyLogoUrl,
    );
  }
}