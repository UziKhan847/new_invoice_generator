import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// App-wide keyboard shortcuts for the desktop shell (Windows/Linux/macOS).
/// Intent classes below are bound to [SingleActivator]s in [DesktopShell] and
/// handled by [Actions] there; individual sections plug into the narrower
/// per-section registries at the bottom of this file.

/// True on macOS, where shortcuts conventionally use ⌘ instead of Ctrl.
bool get isMacPlatform => Platform.isMacOS;

/// A `Ctrl+<key>` activator on Windows/Linux, `Cmd+<key>` on macOS — so the
/// same shortcut table reads naturally on every desktop platform.
SingleActivator cmdOrCtrl(LogicalKeyboardKey key, {bool shift = false}) =>
    SingleActivator(
      key,
      control: !isMacPlatform,
      meta: isMacPlatform,
      shift: shift,
    );

// ── Intents ──────────────────────────────────────────────────────────────
class NewInvoiceIntent extends Intent {
  const NewInvoiceIntent();
}

class FocusSearchIntent extends Intent {
  const FocusSearchIntent();
}

class GoToSectionIntent extends Intent {
  final int index;
  const GoToSectionIntent(this.index);
}

class OpenSettingsIntent extends Intent {
  const OpenSettingsIntent();
}

class RefreshSectionIntent extends Intent {
  const RefreshSectionIntent();
}

class ExportIntent extends Intent {
  const ExportIntent();
}

// ── Per-section registries ──────────────────────────────────────────────
// Ctrl+F and Ctrl+P only make sense on the section currently showing a
// search field or an exportable document — which one differs per DesktopShell
// section. Rather than plumb per-page state through Riverpod for two
// infrequently-used shortcuts, each relevant page registers a callback here
// under its own fixed sidebar index (stable regardless of which section is
// selected), and DesktopShell's Actions simply look up the current index.
final Map<int, FocusNode> desktopSectionSearchFocus = {};
final Map<int, VoidCallback> desktopSectionExportAction = {};
