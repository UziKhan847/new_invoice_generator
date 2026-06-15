import 'package:new_invoice_generator/models/address.dart';

class Customer {
  final String id;
  final String name;
  final String email;
  final String phone;
  final Address address;

  Customer({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.address = const Address(),
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'] as String,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      address: Address.fromRow(json),
    );
  }

  Map<String, dynamic> toInsertMap(String companyId) {
    return {
      'company_id': companyId,
      'name': name,
      'email': email,
      'phone': phone,
      ...address.toMap(),
    };
  }

  Map<String, dynamic> toUpdateMap() {
    return {'name': name, 'email': email, 'phone': phone, ...address.toMap()};
  }

  Customer copyWith({
    String? name,
    String? email,
    String? phone,
    Address? address,
  }) => Customer(
    id: id,
    name: name ?? this.name,
    email: email ?? this.email,
    phone: phone ?? this.phone,
    address: address ?? this.address,
  );
}
