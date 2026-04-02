class Employee {
  final String id;
  final String name;
  final String role;
  final String email;
  final String? phone;

  Employee({
    required this.id,
    required this.name,
    required this.role,
    required this.email,
    this.phone,
  });

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['id'] as String,
      name: json['name'] ?? '',
      role: json['role'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] as String?,
    );
  }

  Map<String, dynamic> toInsertMap(String companyId) {
    return {
      'company_id': companyId,
      'name': name,
      'role': role,
      'email': email,
      'phone': phone,
    };
  }
}