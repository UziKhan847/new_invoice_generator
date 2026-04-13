import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:new_invoice_generator/main.dart';
import 'package:new_invoice_generator/providers/company.dart';
import 'package:new_invoice_generator/providers/customer.dart';
import 'package:new_invoice_generator/providers/employee.dart';
import 'package:new_invoice_generator/providers/expense.dart';
import 'package:new_invoice_generator/providers/home_analytics.dart';
import 'package:new_invoice_generator/providers/invoice.dart';
import 'package:new_invoice_generator/providers/invoice_filter.dart';
import 'package:new_invoice_generator/providers/recurring_invoice.dart';
import 'package:new_invoice_generator/providers/service.dart';
import 'package:new_invoice_generator/screens/app_shell.dart';
import 'package:new_invoice_generator/screens/auth/login.dart';
import 'package:new_invoice_generator/screens/onboarding.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthGate extends ConsumerStatefulWidget {
  const AuthGate({super.key});

  @override
  ConsumerState<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends ConsumerState<AuthGate> {
  late final Stream<AuthState> _authStream;
  String? _lastUserId;

  @override
  void initState() {
    super.initState();
    _authStream = supabase.auth.onAuthStateChange;
    _lastUserId = supabase.auth.currentSession?.user.id;
  }

  void _invalidateAll() {
    ref.invalidate(companyProvider);
    ref.invalidate(invoiceProvider);
    ref.invalidate(invoiceFilterProvider);
    ref.invalidate(customerProvider);
    ref.invalidate(employeeProvider);
    ref.invalidate(serviceProvider);
    ref.invalidate(recurringInvoiceProvider);
    ref.invalidate(homeAnalyticsProvider);
    ref.invalidate(expenseProvider);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: _authStream,
      builder: (context, snapshot) {
        final session = snapshot.data?.session ?? supabase.auth.currentSession;
        final userId = session?.user.id;

        if (userId != _lastUserId) {
          _lastUserId = userId;
          _invalidateAll();
        }

        if (snapshot.connectionState == ConnectionState.waiting &&
            session == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (session == null) return const LoginScreen();

        // Check onboarding status from company record
        final companyAsync = ref.watch(companyProvider);
        return companyAsync.when(
          loading: () =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (_, _) => AppShell(key: ValueKey(userId)),
          data: (company) {
            final onboarded = company['onboarded'] as bool? ?? false;
            if (!onboarded) return const OnboardingScreen();
            return AppShell(key: ValueKey(userId));
          },
        );
      },
    );
  }
}
