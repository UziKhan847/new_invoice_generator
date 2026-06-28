/// A single entry in an invoice's activity log.
class InvoiceEvent {
  final String id;
  final String invoiceId;
  final String type; // created | sent | viewed | paid | downloaded | note
  final String? detail;
  final DateTime createdAt;

  InvoiceEvent({
    required this.id,
    required this.invoiceId,
    required this.type,
    required this.createdAt,
    this.detail,
  });

  factory InvoiceEvent.fromJson(Map<String, dynamic> json) {
    return InvoiceEvent(
      id: json['id'] as String,
      invoiceId: json['invoice_id'] as String,
      type: json['type'] as String? ?? 'note',
      detail: json['detail'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  /// Human label for the event type.
  String get label => switch (type) {
    'created' => 'Invoice created',
    'sent' => 'Invoice sent',
    'viewed' => 'Invoice viewed by client',
    'paid' => 'Payment received',
    'downloaded' => 'PDF downloaded',
    _ => detail ?? 'Note',
  };
}
