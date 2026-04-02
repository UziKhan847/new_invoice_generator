import 'package:new_invoice_generator/main.dart';
import 'package:new_invoice_generator/models/service_customer_link.dart';

class ServiceCustomerLinkRepository {
  Future<List<ServiceCustomerLink>> fetchForCompany(String companyId) async {
    final response = await supabase
        .from('service_customer_links')
        .select('*, services(name, unit_price), customers(name)')
        .eq('company_id', companyId)
        .order('created_at', ascending: false);
    return response
        .map<ServiceCustomerLink>((j) => ServiceCustomerLink.fromJson(j))
        .toList();
  }

  Future<List<ServiceCustomerLink>> fetchForCustomer(
      String companyId, String customerId) async {
    final response = await supabase
        .from('service_customer_links')
        .select('*, services(name, unit_price), customers(name)')
        .eq('company_id', companyId)
        .eq('customer_id', customerId);
    return response
        .map<ServiceCustomerLink>((j) => ServiceCustomerLink.fromJson(j))
        .toList();
  }

  Future<void> create(ServiceCustomerLink link, String companyId) async {
    await supabase
        .from('service_customer_links')
        .insert(link.toInsertMap(companyId));
  }

  Future<void> delete(String id) async {
    await supabase.from('service_customer_links').delete().eq('id', id);
  }
}