import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' show Locale, WidgetsBinding;
import 'package:win32/win32.dart';

/// Spell checking backed by the Windows Spell Checking API — the same
/// dictionaries (and the user's custom words) that Word and Edge use.
class WindowsSpellCheckService extends SpellCheckService {
  WindowsSpellCheckService._(this._factory);

  final ISpellCheckerFactory _factory;
  ISpellChecker? _checker;
  bool _checkerResolved = false;

  static WindowsSpellCheckService? _instance;
  static bool _unavailable = false;

  /// Null when not on Windows or the spell-check API can't be created.
  static WindowsSpellCheckService? get instance {
    if (_instance != null || _unavailable) return _instance;
    if (!Platform.isWindows) {
      _unavailable = true;
      return null;
    }
    try {
      // The runner already initializes COM on the platform thread, but Dart
      // may run on a separate UI thread; S_FALSE / RPC_E_CHANGED_MODE here
      // both still leave COM usable.
      CoInitializeEx(COINIT_APARTMENTTHREADED);
      _instance = WindowsSpellCheckService._(
        createInstance<ISpellCheckerFactory>(SpellCheckerFactory),
      );
    } catch (_) {
      _unavailable = true;
    }
    return _instance;
  }

  // Prefer the OS language (e.g. en-CA) over the app's Localizations locale,
  // which is always en-US because the app declares no supportedLocales.
  ISpellChecker? _resolveChecker(Locale fallback) {
    if (_checkerResolved) return _checker;
    _checkerResolved = true;
    final tags = {
      WidgetsBinding.instance.platformDispatcher.locale.toLanguageTag(),
      fallback.toLanguageTag(),
      'en-US',
    };
    for (final tag in tags) {
      try {
        final checker = using((arena) {
          final p = arena.pcwstr(tag);
          return _factory.isSupported(p)
              ? _factory.createSpellChecker(p)
              : null;
        });
        if (checker != null) return _checker = checker;
      } catch (_) {}
    }
    return null;
  }

  @override
  Future<List<SuggestionSpan>?> fetchSpellCheckSuggestions(
    Locale locale,
    String text,
  ) async {
    final checker = _resolveChecker(locale);
    if (checker == null) return const [];
    try {
      return using<List<SuggestionSpan>>(
        (arena) => _check(checker, text, arena),
      );
    } catch (_) {
      // Null tells EditableText to keep its previous results.
      return null;
    }
  }

  List<SuggestionSpan> _check(ISpellChecker checker, String text, Arena arena) {
    final errors = checker.check(arena.pcwstr(text));
    if (errors == null) return const [];
    final spans = <SuggestionSpan>[];
    final out = arena<VTablePointer>();
    try {
      while (errors.next(out) == S_OK) {
        final error = ISpellingError(out.value);
        try {
          final start = error.startIndex;
          final action = error.correctiveAction;
          // Suggestions are fetched lazily on right-click (see [suggest]);
          // only Windows' definite fixes are captured up front. An empty
          // string means "delete" (a repeated word).
          final List<String> fixes;
          if (action == CORRECTIVE_ACTION_REPLACE) {
            final replacement = error.replacement;
            fixes = [replacement.toDartString()];
            CoTaskMemFree(replacement);
          } else if (action == CORRECTIVE_ACTION_DELETE) {
            fixes = const [''];
          } else {
            fixes = const [];
          }
          spans.add(
            SuggestionSpan(
              TextRange(start: start, end: start + error.length),
              fixes,
            ),
          );
        } finally {
          error.release();
        }
      }
    } finally {
      errors.release();
    }
    return spans;
  }

  /// Up to [max] replacement candidates for a misspelled [word].
  List<String> suggest(String word, {int max = 6}) {
    final checker = _checker;
    if (checker == null) return const [];
    try {
      return using((arena) {
        final enumerator = checker.suggest(arena.pcwstr(word));
        if (enumerator == null) return const <String>[];
        final out = arena<Pointer<Utf16>>();
        final fetched = arena<Uint32>();
        final results = <String>[];
        try {
          while (results.length < max &&
              enumerator.next(1, out, fetched) == S_OK &&
              fetched.value == 1) {
            results.add(out.value.toDartString());
            CoTaskMemFree(out.value);
          }
        } finally {
          enumerator.release();
        }
        return results;
      });
    } catch (_) {
      return const [];
    }
  }

  /// Adds [word] to the user's Windows dictionary (shared with other apps).
  void addToDictionary(String word) {
    final checker = _checker;
    if (checker == null) return;
    try {
      using((arena) => checker.add(arena.pcwstr(word)));
    } catch (_) {}
  }
}
