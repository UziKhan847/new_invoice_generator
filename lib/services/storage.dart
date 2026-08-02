import 'dart:io';
import 'package:new_invoice_generator/main.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _signedUrlLifetime = 60 * 60 * 24 * 365;

class _CachedUrl {
  final String url;
  final DateTime expiresAt;
  _CachedUrl(this.url, this.expiresAt);
}

class StorageService {
  // In-memory cache of signed logo URLs, keyed by storage path. Avoids
  // minting a new (differently-tokened) URL on every unrelated company
  // provider rebuild, which would otherwise bust Image.network's URL-keyed
  // cache and force the logo to redownload.
  static final Map<String, _CachedUrl> _cache = {};

  Future<String> uploadLogo(File file, String companyId) async {
    final uid = supabase.auth.currentUser!.id;
    final path = '$uid/logos/$companyId.png';

    await supabase.storage
        .from('company-assets')
        .upload(
          path,
          file,
          fileOptions: const FileOptions(
            upsert: true,
            contentType: 'image/png',
          ),
        );

    final signedUrl = await supabase.storage
        .from('company-assets')
        .createSignedUrl(path, _signedUrlLifetime);
    _cache[path] = _CachedUrl(
      signedUrl,
      DateTime.now().add(const Duration(days: 364)),
    );

    await supabase
        .from('companies')
        .update({'logo_storage_path': path})
        .eq('id', companyId);

    return signedUrl;
  }

  static Future<String?> getFreshLogoUrl(String? storagePath) async {
    if (storagePath == null || storagePath.isEmpty) return null;
    final cached = _cache[storagePath];
    if (cached != null && cached.expiresAt.isAfter(DateTime.now())) {
      return cached.url;
    }
    try {
      final url = await supabase.storage
          .from('company-assets')
          .createSignedUrl(storagePath, _signedUrlLifetime);
      _cache[storagePath] = _CachedUrl(
        url,
        DateTime.now().add(const Duration(days: 364)),
      );
      return url;
    } catch (_) {
      return null;
    }
  }
}
