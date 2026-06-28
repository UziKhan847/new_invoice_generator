import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Which layout skin the app renders.
/// - mobile  : bottom-nav, single-column, cards, FAB
/// - desktop : persistent sidebar, master-detail, data tables
enum LayoutMode { mobile, desktop }

extension LayoutModeX on LayoutMode {
  bool get isDesktop => this == LayoutMode.desktop;
  bool get isMobile => this == LayoutMode.mobile;
  String get prefsValue => name; // 'mobile' | 'desktop'
}

/// True when running on a desktop OS (used for the first-launch default).
bool get isDesktopPlatform {
  if (kIsWeb) return false;
  return Platform.isWindows || Platform.isLinux || Platform.isMacOS;
}

/// Whether this device is large enough to use the desktop layout.
/// Desktop OSes always qualify. On mobile (Android/iOS) only tablets do —
/// a tablet is detected by its shortest side being >= 600dp, the standard
/// Material breakpoint. Phones are excluded because the desktop sidebar layout
/// is unusable in portrait and can trap the user with no way back.
bool deviceAllowsDesktop(BuildContext context) {
  if (isDesktopPlatform) return true;
  final size = MediaQuery.sizeOf(context);
  final shortestSide = size.shortestSide;
  return shortestSide >= 600;
}

class LayoutModeNotifier extends Notifier<LayoutMode> {
  static const _key = 'layout_mode_v1';

  @override
  LayoutMode build() {
    // Start from the platform default; an stored override (if any) is applied
    // asynchronously and wins.
    _load();
    return isDesktopPlatform ? LayoutMode.desktop : LayoutMode.mobile;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_key);
    if (saved == null) return; // no override → keep the platform default
    state = switch (saved) {
      'desktop' => LayoutMode.desktop,
      'mobile' => LayoutMode.mobile,
      _ => state,
    };
  }

  Future<void> set(LayoutMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, mode.prefsValue);
  }

  Future<void> toggle() async {
    await set(state.isDesktop ? LayoutMode.mobile : LayoutMode.desktop);
  }

  /// Clear the override so the app reverts to the platform default.
  Future<void> resetToPlatformDefault() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
    state = isDesktopPlatform ? LayoutMode.desktop : LayoutMode.mobile;
  }
}

final layoutModeProvider =
    NotifierProvider<LayoutModeNotifier, LayoutMode>(LayoutModeNotifier.new);