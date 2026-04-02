import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:new_invoice_generator/models/customer.dart';
import 'package:new_invoice_generator/providers/company.dart';
import 'package:new_invoice_generator/repositories/customer.dart';

class CustomerNotifier extends AsyncNotifier<List<Customer>> {
  final repo = CustomerRepository();

  @override
  Future<List<Customer>> build() async {
    final company = await ref.read(companyProvider.future);
    final raw = await repo.fetchCustomers(company['id']);
    return raw.map((json) => Customer.fromJson(json)).toList();
  }

  Future<void> addCustomer(Customer c) async {
    final company = await ref.read(companyProvider.future);
    await repo.addCustomer(
      company['id'],
      c.name,
      c.email,
      c.address,
      c.phone,
    );
    // Reload from Supabase
    final raw = await repo.fetchCustomers(company['id']);
    state = AsyncData(raw.map((json) => Customer.fromJson(json)).toList());
  }

  Future<void> deleteCustomer(String id) async {
    await repo.deleteCustomer(id);
    final company = await ref.read(companyProvider.future);
    final raw = await repo.fetchCustomers(company['id']);
    state = AsyncData(raw.map((json) => Customer.fromJson(json)).toList());
  }

  Future<void> updateCustomer(Customer c) async {
    await repo.updateCustomer(c);
    final company = await ref.read(companyProvider.future);
    final raw = await repo.fetchCustomers(company['id']);
    state = AsyncData(raw.map((json) => Customer.fromJson(json)).toList());
  }
}

final customerProvider =
    AsyncNotifierProvider<CustomerNotifier, List<Customer>>(
  CustomerNotifier.new,
);