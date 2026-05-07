import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Stable notification ID ranges per category
class NotifId {
  static const int overdueBase = 1000; // + invoice index
  static const int recurringBase = 2000; // + recurring index
}

/// Android channel IDs
class NotifChannel {
  static const String overdue = 'overdue_invoices';
  static const String recurring = 'recurring_generated';
}

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    // Linux has no local notification support — skip silently
    if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) return;

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: false,
    );

    await _plugin.initialize(
      settings: const InitializationSettings(android: android, iOS: ios),
    );

    // Create Android notification channels
    if (Platform.isAndroid) {
      final androidPlugin = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      await androidPlugin?.createNotificationChannel(
        const AndroidNotificationChannel(
          NotifChannel.overdue,
          'Overdue Invoices',
          description: 'Alerts for invoices past their due date',
          importance: Importance.high,
        ),
      );
      await androidPlugin?.createNotificationChannel(
        const AndroidNotificationChannel(
          NotifChannel.recurring,
          'Auto-Generated Invoices',
          description:
              'Notifications when recurring invoices are auto-generated',
          importance: Importance.defaultImportance,
        ),
      );
    }
  }

  /// Request permissions (Android 13+, iOS). No-op on other platforms.
  static Future<void> requestPermissions() async {
    if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) return;

    await _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: false);

    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
  }

  // ── Overdue invoice notification ───────────────────────────────────────────
  static Future<void> showOverdueAlert({
    required int index,
    required String invoiceNumber,
    required String customerName,
    required int daysOverdue,
  }) async {
    await _show(
      id: NotifId.overdueBase + index,
      title: '⚠️ Overdue: $invoiceNumber',
      body:
          '$customerName · $daysOverdue day${daysOverdue == 1 ? '' : 's'} overdue',
      channel: NotifChannel.overdue,
      high: true,
    );
  }

  // ── Recurring invoice generated notification ───────────────────────────────
  static Future<void> showRecurringGenerated({
    required int index,
    required String customerName,
    required String amount,
  }) async {
    await _show(
      id: NotifId.recurringBase + index,
      title: '🔄 Invoice auto-generated',
      body: '$customerName — $amount',
      channel: NotifChannel.recurring,
      high: false,
    );
  }

  // ── Internal show ──────────────────────────────────────────────────────────
  static Future<void> _show({
    required int id,
    required String title,
    required String body,
    required String channel,
    required bool high,
  }) async {
    if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) return;

    final importance = high ? Importance.high : Importance.defaultImportance;
    final priority = high ? Priority.high : Priority.defaultPriority;

    await _plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          channel,
          channel,
          importance: importance,
          priority: priority,
          playSound: false,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: false,
        ),
      ),
    );
  }
}
