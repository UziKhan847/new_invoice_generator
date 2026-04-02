
import 'package:new_invoice_generator/main.dart';

class CompanyRepository {
  Future<Map<String, dynamic>> getOrCreateCompany() async {
    final user = supabase.auth.currentUser!;
    
    final existing = await supabase
        .from('companies')
        .select()
        .eq('owner_id', user.id)
        .maybeSingle();

    if (existing != null) {
      return existing;
    }

    final created = await supabase
        .from('companies')
        .insert({
          'owner_id': user.id,
          'name': 'My Company',
        })
        .select()
        .single();

    return created;
  }
}