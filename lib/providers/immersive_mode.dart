import 'dart:io' show Platform;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Whether the Android system navigation bar is hidden (swipe from the edge
/// to reveal it temporarily). No-op on iOS/desktop, which don't have an
/// equivalent overlay nav bar to hide the same way.
const _immersiveModeKey = 'immersive_mode_v1';

/// Reads the persisted immersive-mode preference before [runApp], so the
/// system nav bar is hidden (or shown) from the very first frame instead of
/// flashing visible-then-hidden on every launch.
Future<bool> loadInitialImmersiveMode() async {
  if (!Platform.isAndroid) return false;
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(_immersiveModeKey) ?? false;
}

class ImmersiveModeNotifier extends Notifier<bool> {
  ImmersiveModeNotifier([this._initial]);
  final bool? _initial;

  @override
  bool build() {
    final value = _initial ?? false;
    _apply(value);
    return value;
  }

  void _apply(bool enabled) {
    if (!Platform.isAndroid) return;
    if (enabled) {
      // Hide only the nav bar; keep the status bar visible. A swipe from the
      // bottom edge reveals the nav bar temporarily, matching standard
      // Android immersive behavior (e.g. video/game apps).
      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.manual,
        overlays: [SystemUiOverlay.top],
      );
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }

  Future<void> set(bool enabled) async {
    state = enabled;
    _apply(enabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_immersiveModeKey, enabled);
  }
}

final immersiveModeProvider =
    NotifierProvider<ImmersiveModeNotifier, bool>(ImmersiveModeNotifier.new);
