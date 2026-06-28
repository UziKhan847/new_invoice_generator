import 'package:new_invoice_generator/models/address.dart';

class Customer {
  final String id;
  final String name;
  final String email;
  final String phone;
  final Address address;
  final List<String> tags;

  Customer({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.address = const Address(),
    this.tags = const [],
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'] as String,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      address: Address.fromRow(json),
      tags:
          (json['tags'] as List?)?.map((e) => e.toString()).toList() ??
          const [],
    );
  }

  Map<String, dynamic> toInsertMap(String companyId) {
    return {
      'company_id': companyId,
      'name': name,
      'email': email,
      'phone': phone,
      'tags': tags,
      ...address.toMap(),
    };
  }

  Map<String, dynamic> toUpdateMap() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'tags': tags,
      ...address.toMap(),
    };
  }

  Customer copyWith({
    String? name,
    String? email,
    String? phone,
    Address? address,
    List<String>? tags,
  }) => Customer(
    id: id,
    name: name ?? this.name,
    email: email ?? this.email,
    phone: phone ?? this.phone,
    address: address ?? this.address,
    tags: tags ?? this.tags,
  );
}
