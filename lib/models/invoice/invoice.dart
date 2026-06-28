import 'package:new_invoice_generator/models/address.dart';
import 'item.dart';

class Invoice {
  final String? id;
  final String invoiceNumber;
  final String customerName;
  final String? customerId;
  final String? customerEmail; // auto-filled for email dialog
  final String? customerPhone; // auto-filled for SMS
  // Customer address snapshot (frozen at invoice creation)
  final Address customerAddress;
  // Company/business snapshot (frozen at invoice creation, shown in PDF header)
  final String? companyName;
  final String? companyEmail;
  final String? companyPhone;
  final String? businessNumber; // BN
  final String? rtNumber; // RT
  final Address companyAddress;
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
  // Notes / payment terms shown at bottom of invoice
  final String? notes;
  // Tax settings — stored at invoice creation time so changes don't affect old invoices
  final double taxRate; // e.g. 0.13
  final String taxLabel; // e.g. 'HST'
  final bool isExport; // true = 0% tax (international customer)
  final bool isPrivate; // true = excluded from tax reports and analytics
  // Stripe payment link URL
  final String? stripePaymentLink;
  // Payment method: 'etransfer' | 'stripe' | 'other'
  final String paymentMethod;
  // Company logo — injected at PDF generation time
  final String? companyLogoUrl;

  Invoice({
    this.id,
    required this.invoiceNumber,
    required this.customerName,
    this.customerId,
    this.customerEmail,
    this.customerPhone,
    this.customerAddress = const Address(),
    this.companyName,
    this.companyEmail,
    this.companyPhone,
    this.businessNumber,
    this.rtNumber,
    this.companyAddress = const Address(),
    required this.items,
    DateTime? issueDate,
    this.dueDate,
    this.isPaid = false,
    this.status = 'unpaid',
    this.senderEmployeeId,
    this.senderName,
    this.senderRole,
    this.senderEmail,
    this.notes,
    this.taxRate = 0.13,
    this.taxLabel = 'HST',
    this.isExport = false,
    this.isPrivate = false,
    this.stripePaymentLink,
    this.paymentMethod = 'etransfer',
    this.companyLogoUrl,
  }) : issueDate = issueDate ?? DateTime.now();

  /// Sum of item totals AFTER discounts (what the customer pays before tax)
  double get subtotal => items.fold(0, (sum, item) => sum + item.total);

  /// Tax is calculated on the PRE-discount price (full item subtotals)
  double get taxableSubtotal =>
      items.fold(0, (sum, item) => sum + item.subtotal);
  double get totalDiscountAmount =>
      items.fold(0, (sum, item) => sum + item.discountAmount);
  double get effectiveTaxRate => isExport ? 0.0 : taxRate;
  double get tax => taxableSubtotal * effectiveTaxRate;
  double get total => subtotal + tax;

  /// Canonical file name (no extension) used for downloads / sharing / email.
  /// Format: "[invoice_num]. [customer_name]_[YYYY-MM-DD]".
  /// Sanitised so it is safe as a filename on all platforms.
  String get fileBaseName {
    final dateStr =
        '${issueDate.year.toString().padLeft(4, '0')}-'
        '${issueDate.month.toString().padLeft(2, '0')}-'
        '${issueDate.day.toString().padLeft(2, '0')}';
    final raw = '$invoiceNumber. ${customerName}_$dateStr';
    // Replace characters that are illegal in filenames; collapse repeats.
    return raw
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .trim();
  }

  factory Invoice.fromJson(Map<String, dynamic> json) {
    final itemsJson = json['invoice_items'] as List? ?? [];
    final emp = json['employees'] as Map<String, dynamic>?;
    final cust = json['customers'] as Map<String, dynamic>?;
    return Invoice(
      id: json['id'],
      invoiceNumber: json['invoice_number'] ?? '',
      customerName: json['customer_name'] ?? '',
      customerId: json['customer_id'] as String?,
      customerEmail:
          cust?['email'] as String? ?? json['customer_email'] as String?,
      customerPhone: cust?['phone'] as String?,
      customerAddress: Address.fromRow(json, prefix: 'customer_'),
      companyName: json['company_name_snapshot'] as String?,
      companyEmail: json['company_email_snapshot'] as String?,
      companyPhone: json['company_phone_snapshot'] as String?,
      businessNumber: json['business_number_snapshot'] as String?,
      rtNumber: json['rt_number_snapshot'] as String?,
      companyAddress: Address.fromRow(json, prefix: 'company_'),
      issueDate: DateTime.parse(json['issue_date'] ?? json['created_at']),
      dueDate: json['due_date'] != null
          ? DateTime.parse(json['due_date'])
          : null,
      isPaid: json['is_paid'] ?? false,
      status: json['status'] ?? 'unpaid',
      items: itemsJson.map((item) => InvoiceItem.fromJson(item)).toList(),
      senderEmployeeId: json['sender_employee_id'] as String?,
      senderName: emp?['name'] as String?,
      senderRole: emp?['role'] as String?,
      senderEmail: emp?['email'] as String?,
      notes: json['notes'] as String?,
      taxRate: (json['tax_rate'] as num?)?.toDouble() ?? 0.13,
      taxLabel: json['tax_label'] as String? ?? 'HST',
      isExport: json['is_export'] as bool? ?? false,
      isPrivate: json['is_private'] as bool? ?? false,
      stripePaymentLink: json['stripe_payment_link'] as String?,
      paymentMethod: json['payment_method'] as String? ?? 'etransfer',
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
      'notes': notes,
      'tax_rate': taxRate,
      'tax_label': taxLabel,
      'is_export': isExport,
      'is_private': isPrivate,
      'stripe_payment_link': stripePaymentLink,
      'payment_method': paymentMethod,
      ...customerAddress.toMap(prefix: 'customer_'),
      // Company snapshot
      'company_name_snapshot': companyName,
      'company_email_snapshot': companyEmail,
      'company_phone_snapshot': companyPhone,
      'business_number_snapshot': businessNumber,
      'rt_number_snapshot': rtNumber,
      ...companyAddress.toMap(prefix: 'company_'),
    };
  }

  /// Fields to update on an existing invoice. Keeps the same invoice_number
  /// (the permanent identifier) but allows everything else to change.
  /// Omits company_id and created_at (immutable after creation).
  Map<String, dynamic> toUpdateMap() {
    return {
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
      'notes': notes,
      'tax_rate': taxRate,
      'tax_label': taxLabel,
      'is_export': isExport,
      'is_private': isPrivate,
      'stripe_payment_link': stripePaymentLink,
      'payment_method': paymentMethod,
      ...customerAddress.toMap(prefix: 'customer_'),
      'company_name_snapshot': companyName,
      'company_email_snapshot': companyEmail,
      'company_phone_snapshot': companyPhone,
      'business_number_snapshot': businessNumber,
      'rt_number_snapshot': rtNumber,
      ...companyAddress.toMap(prefix: 'company_'),
    };
  }

  Invoice copyWith({
    String? companyLogoUrl,
    String? invoiceNumber,
    String? customerName,
    String? customerId,
    String? customerEmail,
    String? customerPhone,
    Address? customerAddress,
    String? companyName,
    String? companyEmail,
    String? companyPhone,
    String? businessNumber,
    String? rtNumber,
    Address? companyAddress,
    List<InvoiceItem>? items,
    DateTime? issueDate,
    DateTime? dueDate,
    bool? isPaid,
    String? status,
    String? senderEmployeeId,
    String? senderName,
    String? senderRole,
    String? senderEmail,
    String? notes,
    double? taxRate,
    String? taxLabel,
    bool? isExport,
    bool? isPrivate,
    String? stripePaymentLink,
    String? paymentMethod,
  }) {
    return Invoice(
      id: id,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      customerName: customerName ?? this.customerName,
      customerId: customerId ?? this.customerId,
      customerEmail: customerEmail ?? this.customerEmail,
      customerPhone: customerPhone ?? this.customerPhone,
      customerAddress: customerAddress ?? this.customerAddress,
      companyName: companyName ?? this.companyName,
      companyEmail: companyEmail ?? this.companyEmail,
      companyPhone: companyPhone ?? this.companyPhone,
      businessNumber: businessNumber ?? this.businessNumber,
      rtNumber: rtNumber ?? this.rtNumber,
      companyAddress: companyAddress ?? this.companyAddress,
      items: items ?? this.items,
      issueDate: issueDate ?? this.issueDate,
      dueDate: dueDate ?? this.dueDate,
      isPaid: isPaid ?? this.isPaid,
      status: status ?? this.status,
      senderEmployeeId: senderEmployeeId ?? this.senderEmployeeId,
      senderName: senderName ?? this.senderName,
      senderRole: senderRole ?? this.senderRole,
      senderEmail: senderEmail ?? this.senderEmail,
      notes: notes ?? this.notes,
      taxRate: taxRate ?? this.taxRate,
      taxLabel: taxLabel ?? this.taxLabel,
      isExport: isExport ?? this.isExport,
      isPrivate: isPrivate ?? this.isPrivate,
      stripePaymentLink: stripePaymentLink ?? this.stripePaymentLink,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      companyLogoUrl: companyLogoUrl ?? this.companyLogoUrl,
    );
  }
}
