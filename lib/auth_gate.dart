import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:new_invoice_generator/main.dart';
import 'package:new_invoice_generator/screens/app_shell.dart';
import 'package:new_invoice_generator/screens/auth/login.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final Stream<AuthState> _authStream;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _authStream = supabase.auth.onAuthStateChange;
    _currentUserId = supabase.auth.currentSession?.user.id;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: _authStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final session = snapshot.data?.session ?? supabase.auth.currentSession;
        final userId = session?.user.id;

        // Update tracked user id when it changes
        if (userId != _currentUserId) {
          _currentUserId = userId;
        }

        if (session == null) {
          return const LoginScreen();
        }

        // Key on userId forces Flutter to DESTROY and RECREATE the entire
        // ProviderScope subtree when the user changes. This guarantees all
        // providers start completely fresh — no stale data from previous user.
        return ProviderScope(key: ValueKey(userId), child: const AppShell());
      },
    );
  }
}
