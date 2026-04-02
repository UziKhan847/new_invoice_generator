class Customer {
  final String id;
  final String name;
  final String email;
  final String address;
  final String phone;

  Customer({
    required this.id,
    required this.name,
    required this.email,
    required this.address,
    required this.phone,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'] as String,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      address: json['address'] ?? '',
      phone: json['phone'] ?? '',
    );
  }

  Map<String, dynamic> toInsertMap(String companyId) {
    return {
      'company_id': companyId,
      'name': name,
      'email': email,
      'address': address,
      'phone': phone,
    };
  }
}