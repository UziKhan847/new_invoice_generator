import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/service.dart';

class ServiceNotifier extends Notifier<List<Service>> {
  @override
  List<Service> build() => [];

  void addService(Service s) => state = [...state, s];
  void updateService(Service s) =>
      state = state.map((e) => e.id == s.id ? s : e).toList();
  void deleteService(String id) =>
      state = state.where((e) => e.id != id).toList();
}

final serviceProvider = NotifierProvider<ServiceNotifier, List<Service>>(
  ServiceNotifier.new,
);