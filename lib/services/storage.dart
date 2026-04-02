import 'dart:io';
import 'package:new_invoice_generator/main.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StorageService {
  Future<String> uploadLogo(File file, String companyId) async {
    final uid = supabase.auth.currentUser!.id;
    final path = '$uid/logos/$companyId.png';

    await supabase.storage
        .from('company-assets')
        .upload(path, file,
            fileOptions: const FileOptions(
              upsert: true,
              contentType: 'image/png',
            ));

    // Use a signed URL (1 year expiry) — works whether bucket is public or private
    final signedUrl = await supabase.storage
        .from('company-assets')
        .createSignedUrl(path, 60 * 60 * 24 * 365);

    // Store the base path in DB (not the signed URL — we regenerate on load)
    await supabase
        .from('companies')
        .update({'logo_storage_path': path}).eq('id', companyId);

    return signedUrl;
  }

  /// Call this to get a fresh signed URL from a stored path
  static Future<String?> getFreshLogoUrl(String? storagePath) async {
    if (storagePath == null || storagePath.isEmpty) return null;
    try {
      return await supabase.storage
          .from('company-assets')
          .createSignedUrl(storagePath, 60 * 60 * 24 * 365);
    } catch (_) {
      return null;
    }
  }
}