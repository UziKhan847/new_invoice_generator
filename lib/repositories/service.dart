import 'package:new_invoice_generator/main.dart';
import 'package:new_invoice_generator/models/service.dart';

class ServiceRepository {
  Future<List<Service>> fetchAll(String companyId) async {
    final response = await supabase
        .from('services')
        .select()
        .eq('company_id', companyId)
        .order('name', ascending: true);
    return response.map<Service>((j) => Service.fromJson(j)).toList();
  }

  Future<void> insert(Service s, String companyId) async {
    await supabase.from('services').insert(s.toInsertMap(companyId));
  }

  Future<void> update(Service s) async {
    await supabase
        .from('services')
        .update({
          'name': s.name,
          'description': s.description,
          'unit_price': s.unitPrice,
          'rate_type': s.rateType,
        })
        .eq('id', s.id);
  }

  Future<void> delete(String id) async {
    await supabase.from('services').delete().eq('id', id);
  }
}
