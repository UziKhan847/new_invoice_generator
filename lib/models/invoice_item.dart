import 'package:new_invoice_generator/utils/number_format.dart';

class InvoiceItem {
  final String? id;
  final String description;
  final double quantity;
  final double unitPrice;
  // Discount: either a % (0-100) or a flat $ amount — only one is used
  final double discountPercent; // e.g. 10.0 = 10%
  final double discountFlat; // e.g. 5.0 = $5 off

  InvoiceItem({
    this.id,
    required this.description,
    required this.quantity,
    required this.unitPrice,
    this.discountPercent = 0,
    this.discountFlat = 0,
  });

  double get subtotal => quantity * unitPrice;

  /// Display-friendly quantity (e.g. 3 → "3", 3.5 → "3.5", 3.50 → "3.5").
  String get quantityDisplay => NumFmt.quantity(quantity);

  /// Discount amount in dollars
  double get discountAmount {
    if (discountPercent > 0) {
      return subtotal * (discountPercent / 100);
    }
    if (discountFlat > 0) {
      return discountFlat.clamp(0, subtotal);
    }
    return 0;
  }

  double get total => (subtotal - discountAmount).clamp(0, double.infinity);

  bool get hasDiscount => discountAmount > 0;

  String get discountLabel {
    if (discountPercent > 0) {
      return '${discountPercent.toStringAsFixed(0)}% off';
    }
    if (discountFlat > 0) return '\$${discountFlat.toStringAsFixed(2)} off';
    return '';
  }

  factory InvoiceItem.fromJson(Map<String, dynamic> json) {
    return InvoiceItem(
      id: json['id'] as String?,
      description: json['description'] ?? '',
      quantity: (json['quantity'] as num).toDouble(),
      unitPrice: (json['unit_price'] as num).toDouble(),
      discountPercent: (json['discount_percent'] as num?)?.toDouble() ?? 0,
      discountFlat: (json['discount_flat'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toInsertMap(String invoiceId) {
    return {
      'invoice_id': invoiceId,
      'description': description,
      'quantity': quantity,
      'unit_price': unitPrice,
      'discount_percent': discountPercent,
      'discount_flat': discountFlat,
      'total': total,
    };
  }
}
