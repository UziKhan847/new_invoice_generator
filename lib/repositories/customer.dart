import 'package:new_invoice_generator/main.dart';
import 'package:new_invoice_generator/models/customer.dart';

class CustomerRepository {
  Future<List<Map<String, dynamic>>> fetchCustomers(String companyId) async {
    return await supabase
        .from('customers')
        .select()
        .eq('company_id', companyId)
        .order('name', ascending: true);
  }

  Future<Customer> addCustomer(String companyId, Customer c) async {
    final row = await supabase
        .from('customers')
        .insert(c.toInsertMap(companyId))
        .select()
        .single();
    return Customer.fromJson(row);
  }

  Future<void> updateCustomer(Customer c) async {
    await supabase.from('customers').update(c.toUpdateMap()).eq('id', c.id);
  }

  Future<void> deleteCustomer(String id) async {
    await supabase.from('customers').delete().eq('id', id);
  }
}
