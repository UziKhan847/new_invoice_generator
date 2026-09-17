import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:new_invoice_generator/app_theme.dart';
import 'package:new_invoice_generator/main.dart';
import 'package:new_invoice_generator/models/home_analytics.dart';
import 'package:new_invoice_generator/providers/company.dart';
import 'package:new_invoice_generator/providers/customer.dart';
import 'package:new_invoice_generator/providers/employee.dart';
import 'package:new_invoice_generator/providers/expense.dart';
import 'package:new_invoice_generator/providers/invoice/filter.dart';
import 'package:new_invoice_generator/providers/invoice/invoice.dart';
import 'package:new_invoice_generator/providers/recurring_invoice.dart';
import 'package:new_invoice_generator/providers/service.dart';
import 'package:new_invoice_generator/screens/app_shell.dart';
import 'package:new_invoice_generator/screens/auth/login.dart';
import 'package:new_invoice_generator/screens/onboarding.dart';
import 'package:new_invoice_generator/services/recurring_invoice_runner.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthGate extends ConsumerStatefulWidget {
  const AuthGate({super.key});

  @override
  ConsumerState<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends ConsumerState<AuthGate>
    with WidgetsBindingObserver {
  late final Stream<AuthState> _authStream;
  String? _lastUserId;
  DateTime? _lastBackgroundCheckAt;

  @override
  void initState() {
    super.initState();
    _authStream = supabase.auth.onAuthStateChange;
    _lastUserId = supabase.auth.currentSession?.user.id;
    WidgetsBinding.instance.addObserver(this);
    // Run checks once on first launch
    _runBackgroundChecks();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Re-run checks when app comes back to foreground
    if (state == AppLifecycleState.resumed) {
      _runBackgroundChecks();
    }
  }

  Future<void> _runBackgroundChecks() async {
    if (supabase.auth.currentSession == null) return;
    // Desktop fires `resumed` on every window focus change (far more often
    // than a mobile app foregrounding), and each check is 2 `companies`
    // queries plus a full three-join invoice fetch — throttle so refocusing
    // the window doesn't hammer Supabase.
    final now = DateTime.now();
    final last = _lastBackgroundCheckAt;
    if (last != null && now.difference(last) < const Duration(minutes: 15)) {
      return;
    }
    _lastBackgroundCheckAt = now;

    // Run in parallel — both are fire-and-forget, failures are silent
    await Future.wait([
      RecurringInvoiceRunner.checkAndGenerate(),
      RecurringInvoiceRunner.checkOverdue(),
    ]);
    // Invalidate invoice provider so new auto-generated invoices show up
    if (mounted) {
      ref.invalidate(invoiceProvider);
    }
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
        final session =
            snapshot.data?.session ?? supabase.auth.currentSession;
        final userId = session?.user.id;

        // Only invalidate when switching AWAY FROM an already-authenticated
        // user (account switch, or logout) — not on cold start or a fresh
        // sign-in, where `_lastUserId` is null and there is no stale
        // per-user provider state to clear. Invalidating unconditionally
        // here used to race companyProvider's own first build: watching it
        // below starts CompanyRepository.getOrCreateCompany() (select, then
        // insert if missing) in this same build, and the invalidation below
        // fired in a post-frame callback would restart that build before the
        // first insert had committed — both inserts would land, producing
        // two `companies` rows for one owner_id and bricking every future
        // `.maybeSingle()` lookup with a "multiple rows returned" error.
        final previousUserId = _lastUserId;
        if (userId != _lastUserId) {
          _lastUserId = userId;
          if (previousUserId != null && previousUserId != userId) {
            // Invalidating providers triggers rebuilds, so it must not run
            // during this build. Defer it to after the current frame.
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _invalidateAll();
            });
          }
        }

        if (snapshot.connectionState == ConnectionState.waiting &&
            session == null) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }

        if (session == null) return const LoginScreen();

        // Check onboarding status from company record
        final companyAsync = ref.watch(companyProvider);
        return companyAsync.when(
          loading: () => const Scaffold(
              body: Center(child: CircularProgressIndicator())),
          // Previously fell through to AppShell here, so a failure to load
          // the company (e.g. the duplicate-row PostgrestException) surfaced
          // as a shell full of unrelated crashes wherever a screen read
          // companyProvider, instead of one clear message with a retry.
          error: (error, _) => _CompanyLoadError(error: error),
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

/// Shown when `companyProvider` fails to load (e.g. the account's company
/// row is missing, or a `PostgrestException` surfaced from a broken query)
/// instead of silently falling through to a shell full of downstream errors.
class _CompanyLoadError extends ConsumerWidget {
  final Object error;
  const _CompanyLoadError({required this.error});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = AppColors.of(context);
    return Scaffold(
      backgroundColor: p.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: p.dangerText),
              const SizedBox(height: 16),
              Text(
                'Couldn\'t load your workspace',
                style: AppTypography.title(p.ink),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                '$error',
                style: AppTypography.body(p.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => ref.invalidate(companyProvider),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => supabase.auth.signOut(),
                child: const Text('Log out'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}