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

const _layoutModeKey = 'layout_mode_v1';

/// Reads the persisted layout mode override (if any) before [runApp], so the
/// very first frame already renders the right layout. Pass the result to
/// `layoutModeProvider.overrideWith(() => LayoutModeNotifier(initial))` in
/// `main()`. Without this, the notifier has to guess the platform default
/// synchronously and correct itself once prefs load — which flashes the
/// wrong layout for a frame on startup whenever the saved override disagrees
/// with the platform default (e.g. "mobile" saved on a desktop OS).
Future<LayoutMode> loadInitialLayoutMode() async {
  final prefs = await SharedPreferences.getInstance();
  final saved = prefs.getString(_layoutModeKey);
  return switch (saved) {
    'desktop' => LayoutMode.desktop,
    'mobile' => LayoutMode.mobile,
    _ => isDesktopPlatform ? LayoutMode.desktop : LayoutMode.mobile,
  };
}

class LayoutModeNotifier extends Notifier<LayoutMode> {
  LayoutModeNotifier([this._initial]);
  final LayoutMode? _initial;

  @override
  LayoutMode build() {
    if (_initial != null) return _initial;
    // Fallback for when this isn't seeded via main() (e.g. tests): guess the
    // platform default and correct asynchronously once prefs load.
    _load();
    return isDesktopPlatform ? LayoutMode.desktop : LayoutMode.mobile;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_layoutModeKey);
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
    await prefs.setString(_layoutModeKey, mode.prefsValue);
  }

  Future<void> toggle() async {
    await set(state.isDesktop ? LayoutMode.mobile : LayoutMode.desktop);
  }

  /// Clear the override so the app reverts to the platform default.
  Future<void> resetToPlatformDefault() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_layoutModeKey);
    state = isDesktopPlatform ? LayoutMode.desktop : LayoutMode.mobile;
  }
}

final layoutModeProvider =
    NotifierProvider<LayoutModeNotifier, LayoutMode>(LayoutModeNotifier.new);