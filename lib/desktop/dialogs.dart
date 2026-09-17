import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A confirm/cancel dialog with Enter bound to the primary action and that
/// action autofocused — so "Delete invoice?" can be confirmed by pressing
/// Enter instead of requiring a mouse click. Escape already dismisses (as
/// cancel) via the default `barrierDismissible: true` on [showDialog].
Future<bool?> confirmDialog(
  BuildContext context, {
  required String title,
  required String content,
  String confirmLabel = 'Confirm',
  String cancelLabel = 'Cancel',
  bool danger = false,
}) {
  return showDialog<bool>(
    context: context,
    builder: (dialogCtx) => CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.enter): () =>
            Navigator.pop(dialogCtx, true),
      },
      child: AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: Text(cancelLabel),
          ),
          ElevatedButton(
            autofocus: true,
            style: danger
                ? ElevatedButton.styleFrom(backgroundColor: Colors.red)
                : null,
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: Text(
              confirmLabel,
              style: danger ? const TextStyle(color: Colors.white) : null,
            ),
          ),
        ],
      ),
    ),
  );
}
