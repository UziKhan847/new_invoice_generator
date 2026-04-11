class Expense {
  final String? id;
  final String description;
  final String category;
  final DateTime date;
  final double amount;
  final double taxAmount; // HST/GST paid on the expense (for input tax credits)
  final String? vendor;
  final String? notes;

  const Expense({
    this.id,
    required this.description,
    required this.category,
    required this.date,
    required this.amount,
    this.taxAmount = 0,
    this.vendor,
    this.notes,
  });

  double get amountBeforeTax => amount - taxAmount;

  static const List<String> categories = [
    'General',
    'Supplies & Materials',
    'Software & Subscriptions',
    'Marketing & Advertising',
    'Travel & Transportation',
    'Meals & Entertainment',
    'Professional Services',
    'Rent & Utilities',
    'Equipment',
    'Other',
  ];

  factory Expense.fromJson(Map<String, dynamic> json) => Expense(
    id: json['id'] as String?,
    description: json['description'] as String,
    category: json['category'] as String? ?? 'General',
    date: DateTime.parse(json['date'] as String),
    amount: (json['amount'] as num).toDouble(),
    taxAmount: (json['tax_amount'] as num?)?.toDouble() ?? 0,
    vendor: json['vendor'] as String?,
    notes: json['notes'] as String?,
  );

  Map<String, dynamic> toInsertMap(String companyId) => {
    'company_id': companyId,
    'description': description,
    'category': category,
    'date': date.toIso8601String().split('T')[0],
    'amount': amount,
    'tax_amount': taxAmount,
    'vendor': vendor,
    'notes': notes,
  };
}
