class Company {
  final String id;
  final String name;
  final String? logoUrl;
  final String? address;
  final String? email;
  final String? phone;
  final String? taxNumber;

  Company({
    required this.id,
    required this.name,
    this.logoUrl,
    this.address,
    this.email,
    this.phone,
    this.taxNumber,
  });
}
