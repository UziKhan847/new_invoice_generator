class InvoiceItem {
  final String? id;
  final String description;
  final int quantity; 
  final double unitPrice;
  final double total;

  InvoiceItem({
    this.id,
    required this.description,
    required this.quantity,
    required this.unitPrice,
  }) : total = quantity * unitPrice;

  factory InvoiceItem.fromJson(Map<String, dynamic> json) {
    return InvoiceItem(
      id: json['id'] as String?,
      description: json['description'] ?? '',
      quantity: (json['quantity'] as num).toInt(),
      unitPrice: (json['unit_price'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toInsertMap(String invoiceId) {
    return {
      'invoice_id': invoiceId,
      'description': description,
      'quantity': quantity,
      'unit_price': unitPrice,
      'total': total,
    };
  }
}