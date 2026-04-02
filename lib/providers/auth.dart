import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:new_invoice_generator/main.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthNotifier extends Notifier<User?> {
  @override
  User? build() {
    return supabase.auth.currentUser;
  }

  Future<void> login(String email, String password) async {
    final res = await supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
    state = res.user;
  }

  Future<void> register(String email, String password) async {
    final res = await supabase.auth.signUp(email: email, password: password);
    state = res.user;
  }

  Future<void> logout() async {
    await supabase.auth.signOut();
    state = null;
  }
}

final authProvider = NotifierProvider<AuthNotifier, User?>(AuthNotifier.new);