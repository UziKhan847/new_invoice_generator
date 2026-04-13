import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:new_invoice_generator/main.dart';
import 'package:new_invoice_generator/repositories/company.dart';
import 'package:new_invoice_generator/services/storage.dart';

class CompanyNotifier extends AsyncNotifier<Map<String, dynamic>> {
  final repo = CompanyRepository();

  @override
  Future<Map<String, dynamic>> build() async {
    final company = await repo.getOrCreateCompany();
    final path = company['logo_storage_path'] as String?;
    if (path != null && path.isNotEmpty) {
      final freshUrl = await StorageService.getFreshLogoUrl(path);
      if (freshUrl != null) {
        return {...company, 'logo_url': freshUrl};
      }
    }
    return company;
  }

  Future<void> updateLogo(String signedUrl, String storagePath) async {
    final company = await future;
    await supabase
        .from('companies')
        .update({'logo_storage_path': storagePath, 'logo_url': signedUrl})
        .eq('id', company['id']);
    state = AsyncData({
      ...company,
      'logo_url': signedUrl,
      'logo_storage_path': storagePath,
    });
  }

  Future<void> updateProvince({
    required String province,
    required double taxRate,
    required String taxLabel,
  }) async {
    final company = await future;
    await supabase
        .from('companies')
        .update({
          'province': province,
          'tax_rate': taxRate,
          'tax_label': taxLabel,
        })
        .eq('id', company['id']);
    state = AsyncData({
      ...company,
      'province': province,
      'tax_rate': taxRate,
      'tax_label': taxLabel,
    });
  }

  Future<void> completeOnboarding({
    required String name,
    required String province,
    required double taxRate,
    required String taxLabel,
    String? address,
    String? email,
    String? phone,
  }) async {
    final company = await future;
    await supabase
        .from('companies')
        .update({
          'name': name,
          'province': province,
          'tax_rate': taxRate,
          'tax_label': taxLabel,
          'address': address,
          'email': email,
          'phone': phone,
          'onboarded': true,
        })
        .eq('id', company['id']);
    ref.invalidateSelf();
    await future;
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}

final companyProvider =
    AsyncNotifierProvider<CompanyNotifier, Map<String, dynamic>>(
      CompanyNotifier.new,
    );
