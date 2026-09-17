import 'package:new_invoice_generator/main.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CompanyRepository {
  // Overlapping calls (e.g. companyProvider rebuilding while a previous
  // getOrCreateCompany() is still in flight) share one round trip instead of
  // each racing their own select-then-insert. Static because CompanyNotifier
  // creates a fresh CompanyRepository() instance per rebuild.
  static Future<Map<String, dynamic>>? _inFlight;

  Future<Map<String, dynamic>> getOrCreateCompany() {
    return _inFlight ??= _getOrCreateCompany().whenComplete(() {
      _inFlight = null;
    });
  }

  Future<Map<String, dynamic>> _getOrCreateCompany() async {
    final user = supabase.auth.currentUser!;

    final existing = await _fetchByOwner(user.id);
    if (existing != null) {
      return existing;
    }

    try {
      return await supabase
          .from('companies')
          .insert({
            'owner_id': user.id,
            'name': 'My Company',
          })
          .select()
          .single();
    } on PostgrestException catch (e) {
      // 23505 = unique_violation on companies.owner_id: another concurrent
      // call already created the row between our select and insert. That
      // row is the source of truth, not an error — go fetch it.
      if (e.code == '23505') {
        final row = await _fetchByOwner(user.id);
        if (row != null) return row;
      }
      rethrow;
    }
  }

  /// `.maybeSingle()` throws if more than one row matches. A `companies`
  /// install that still has a leftover duplicate (from before the
  /// `companies_owner_id_key` unique constraint was added) should still be
  /// able to start instead of hard-failing on every launch, so take the
  /// oldest matching row deterministically instead.
  Future<Map<String, dynamic>?> _fetchByOwner(String ownerId) async {
    final rows = await supabase
        .from('companies')
        .select()
        .eq('owner_id', ownerId)
        .order('created_at', ascending: true)
        .limit(1);
    return rows.isEmpty ? null : rows.first;
  }
}
