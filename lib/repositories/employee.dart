import 'package:new_invoice_generator/main.dart';
import 'package:new_invoice_generator/models/employee.dart';

class EmployeeRepository {
  Future<List<Employee>> fetchAll(String companyId) async {
    final response = await supabase
        .from('employees')
        .select()
        .eq('company_id', companyId)
        .order('name', ascending: true);
    return response.map<Employee>((j) => Employee.fromJson(j)).toList();
  }

  Future<void> add(Employee e, String companyId) async {
    await supabase.from('employees').insert(e.toInsertMap(companyId));
  }

  Future<void> update(Employee e) async {
    await supabase
        .from('employees')
        .update({
          'name': e.name,
          'role': e.role,
          'email': e.email,
          'phone': e.phone,
        })
        .eq('id', e.id);
  }

  Future<void> delete(String id) async {
    await supabase.from('employees').delete().eq('id', id);
  }
}
