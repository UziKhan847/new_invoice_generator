import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:new_invoice_generator/main.dart';
import 'package:new_invoice_generator/repositories/company.dart';
import 'package:new_invoice_generator/services/storage.dart';

class CompanyNotifier extends AsyncNotifier<Map<String, dynamic>> {
  final repo = CompanyRepository();

  @override
  Future<Map<String, dynamic>> build() async {
    final company = await repo.getOrCreateCompany();
    // Regenerate signed logo URL on every load if a storage path exists
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
    // Update DB with storage path
    await supabase.from('companies').update({
      'logo_storage_path': storagePath,
      'logo_url': signedUrl,
    }).eq('id', company['id']);
    // Update in-memory state immediately so UI reflects new logo
    state = AsyncData({
      ...company,
      'logo_url': signedUrl,
      'logo_storage_path': storagePath,
    });
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