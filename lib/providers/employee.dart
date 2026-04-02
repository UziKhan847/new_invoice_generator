import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:new_invoice_generator/models/employee.dart';
import 'package:new_invoice_generator/providers/company.dart';
import 'package:new_invoice_generator/repositories/employee.dart';

class EmployeeNotifier extends AsyncNotifier<List<Employee>> {
  final _repo = EmployeeRepository();

  @override
  Future<List<Employee>> build() async {
    final company = await ref.read(companyProvider.future);
    return _repo.fetchAll(company['id'] as String);
  }

  Future<void> add(Employee e) async {
    final company = await ref.read(companyProvider.future);
    await _repo.add(e, company['id'] as String);
    ref.invalidateSelf();
    await future;
  }

  // No state = AsyncData(...) — use invalidateSelf instead
  Future<void> save(Employee e) async {
    await _repo.update(e);
    ref.invalidateSelf();
    await future;
  }

  Future<void> delete(String id) async {
    await _repo.delete(id);
    ref.invalidateSelf();
    await future;
  }
}

final employeeProvider =
    AsyncNotifierProvider<EmployeeNotifier, List<Employee>>(
  EmployeeNotifier.new,
);