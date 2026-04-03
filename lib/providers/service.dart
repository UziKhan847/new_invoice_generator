import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:new_invoice_generator/models/service.dart';
import 'package:new_invoice_generator/providers/company.dart';
import 'package:new_invoice_generator/repositories/service.dart';

class ServiceNotifier extends AsyncNotifier<List<Service>> {
  final _repo = ServiceRepository();

  @override
  Future<List<Service>> build() async {
    final company = await ref.read(companyProvider.future);
    return _repo.fetchAll(company['id'] as String);
  }

  Future<void> addService(Service s) async {
    final company = await ref.read(companyProvider.future);
    await _repo.insert(s, company['id'] as String);
    ref.invalidateSelf();
    await future;
  }

  Future<void> updateService(Service s) async {
    await _repo.update(s);
    ref.invalidateSelf();
    await future;
  }

  Future<void> deleteService(String id) async {
    await _repo.delete(id);
    ref.invalidateSelf();
    await future;
  }
}

final serviceProvider = AsyncNotifierProvider<ServiceNotifier, List<Service>>(
  ServiceNotifier.new,
);
