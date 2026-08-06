import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:new_invoice_generator/app_theme.dart';
import 'package:new_invoice_generator/auth_gate.dart';
import 'package:new_invoice_generator/keys.dart';
import 'package:new_invoice_generator/providers/immersive_mode.dart';
import 'package:new_invoice_generator/providers/layout_mode.dart';
import 'package:new_invoice_generator/providers/theme.dart';
import 'package:new_invoice_generator/services/notification.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:workmanager/workmanager.dart';

// Supabase client accessible app-wide
final supabase = Supabase.instance.client;

// Background task name
const _kRecurringTask = 'recurringInvoiceCheck';

/// Workmanager callback — runs in a separate Dart isolate (no Flutter widgets)
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    if (taskName == _kRecurringTask) {
      // Re-init Supabase in the background isolate
      await Supabase.initialize(
        url: 'YOUR_SUPABASE_URL',
        publishableKey: 'YOUR_SUPABASE_ANON_KEY',
      );
      await NotificationService.init();

      // Recurring check runs via RecurringInvoiceRunner on app resume
    }
    return Future.value(true);
  });
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(url: url, publishableKey: anonKey);

  // Init notifications
  await NotificationService.init();

  // Resolve the persisted layout mode before the first frame so the app
  // never flashes the platform-default layout before switching to the
  // user's saved override (e.g. "mobile" saved on a desktop OS).
  final initialLayoutMode = await loadInitialLayoutMode();

  // Same idea for immersive mode (hiding the Android system nav bar) — apply
  // it before the first frame so it doesn't flash visible then hide.
  final initialImmersiveMode = await loadInitialImmersiveMode();

  // Workmanager is Android/iOS only — not available on Linux/desktop
  if (Platform.isAndroid || Platform.isIOS) {
    await Workmanager().initialize(callbackDispatcher);
    await Workmanager().registerPeriodicTask(
      _kRecurringTask,
      _kRecurringTask,
      frequency: const Duration(hours: 12),
      constraints: Constraints(networkType: NetworkType.connected),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
    );
  }

  runApp(
    ProviderScope(
      overrides: [
        layoutModeProvider.overrideWith(
          () => LayoutModeNotifier(initialLayoutMode),
        ),
        immersiveModeProvider.overrideWith(
          () => ImmersiveModeNotifier(initialImmersiveMode),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appMode = ref.watch(themeProvider);
    // Watched (not just read) so the notifier initializes at startup and
    // applies the persisted immersive-mode preference even before the
    // Settings screen — where it's toggled — is ever opened.
    ref.watch(immersiveModeProvider);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Invoice Generator',
      theme: AppTheme.light(),
      darkTheme: appMode == AppThemeMode.oled
          ? AppTheme.oled()
          : AppTheme.dark(),
      themeMode: appMode.flutterMode,
      // Wrap every screen's content in a SafeArea so bottom-pinned buttons
      // (save/submit buttons at the end of a form, dialog actions, etc.)
      // never end up laid out underneath the Android system nav bar —
      // Scaffold only auto-avoids it for the dedicated floatingActionButton/
      // bottomNavigationBar slots, not arbitrary widgets in the body.
      builder: (context, child) => SafeArea(child: child!),
      home: const AuthGate(),
    );
  }
}
