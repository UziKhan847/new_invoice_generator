import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:new_invoice_generator/services/windows_spell_check.dart';

/// Spell checking for free-text fields (notes, descriptions). Null — i.e.
/// disabled, unchanged behavior — everywhere except Windows. Cached so every
/// rebuild hands TextField an identical config and doesn't re-trigger a check.
final SpellCheckConfiguration? freeTextSpellCheck =
    WindowsSpellCheckService.instance == null
    ? null
    : SpellCheckConfiguration(
        spellCheckService: WindowsSpellCheckService.instance,
      );

/// Right-click menu that puts spelling suggestions for the clicked word above
/// the usual Cut/Copy/Paste. Pair with [freeTextSpellCheck] on a TextField.
Widget spellCheckContextMenu(BuildContext context, EditableTextState state) {
  final service = WindowsSpellCheckService.instance;
  final span = service == null ? null : _spanUnderPointer(state);
  if (service == null || span == null) {
    return AdaptiveTextSelectionToolbar.editableText(editableTextState: state);
  }

  final word = state.textEditingValue.text.substring(
    span.range.start,
    span.range.end,
  );
  final fixes = span.suggestions.isNotEmpty
      ? span.suggestions
      : service.suggest(word);

  return AdaptiveTextSelectionToolbar.buttonItems(
    anchors: state.contextMenuAnchors,
    buttonItems: [
      for (final fix in fixes)
        ContextMenuButtonItem(
          label: fix.isEmpty ? 'Delete repeated word' : fix,
          onPressed: () => _replace(state, span.range, fix),
        ),
      if (fixes.isEmpty)
        const ContextMenuButtonItem(label: 'No suggestions', onPressed: null),
      ContextMenuButtonItem(
        label: 'Add "$word" to dictionary',
        onPressed: () {
          service.addToDictionary(word);
          _clearWord(state, word);
          state.hideToolbar();
        },
      ),
      ...state.contextMenuButtonItems,
    ],
  );
}

SuggestionSpan? _spanUnderPointer(EditableTextState state) {
  final results = state.spellCheckResults;
  final value = state.textEditingValue;
  // Results lag one async check behind typing; ranges from a stale check
  // could point at the wrong characters.
  if (results == null || results.spellCheckedText != value.text) return null;

  // On Windows a right-click doesn't move the caret, so locate the word
  // under the pointer rather than at the selection.
  final tap = state.renderEditable.lastSecondaryTapDownPosition;
  final index = tap != null
      ? state.renderEditable.getPositionForPoint(tap).offset
      : value.selection.extentOffset;
  final span = state.findSuggestionSpanAtCursorIndex(index);
  if (span == null || span.range.end > value.text.length) return null;
  return span;
}

void _replace(EditableTextState state, TextRange range, String fix) {
  final text = state.textEditingValue.text;
  var target = range;
  // Deleting a repeated word ("the the") would otherwise leave a double space.
  if (fix.isEmpty && range.start > 0 && text[range.start - 1] == ' ') {
    target = TextRange(start: range.start - 1, end: range.end);
  }
  final newValue = state.textEditingValue.replaced(target, fix);
  state.userUpdateTextEditingValue(newValue, SelectionChangedCause.toolbar);
  SchedulerBinding.instance.addPostFrameCallback((_) {
    if (state.mounted) {
      state.bringIntoView(state.textEditingValue.selection.extent);
    }
  });
  state.hideToolbar();
}

// Flutter only re-checks when the text changes, so drop the underline for a
// newly-added word by hand instead of waiting for the next keystroke.
void _clearWord(EditableTextState state, String word) {
  final results = state.spellCheckResults;
  if (results == null) return;
  final text = results.spellCheckedText;
  state.spellCheckResults = SpellCheckResults(text, [
    for (final s in results.suggestionSpans)
      if (text.substring(s.range.start, s.range.end) != word) s,
  ]);
  state.renderEditable.text = state.buildTextSpan();
}
