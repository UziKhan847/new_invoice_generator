import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:new_invoice_generator/app_theme.dart';
import 'package:new_invoice_generator/auth_gate.dart';
import 'package:new_invoice_generator/keys.dart';
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
      await Supabase.initialize(url: url, anonKey: anonKey);
      await NotificationService.init();

      // Recurring check runs via RecurringInvoiceRunner on app resume
    }
    return Future.value(true);
  });
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: url, // e.g. https://abcdefgh.supabase.co
    anonKey: anonKey,
  );

  // Init notifications
  await NotificationService.init();

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

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appMode = ref.watch(themeProvider);
    return MaterialApp(
      title: 'Invoice Generator',
      theme: AppThemes.light(),
      darkTheme: appMode == AppThemeMode.oled
          ? AppThemes.oled()
          : AppThemes.dark(),
      themeMode: appMode.flutterMode,
      home: const AuthGate(),
    );
  }
}
