import 'package:flutter/material.dart';

/// Shows a modal loading overlay while [task] runs, then removes it.
/// Use for any slow async operation (PDF generation, upload, download).
///
/// Example:
///   await withLoadingOverlay(context, message: 'Generating PDF…', task: () async {
///     await DownloadService.downloadInvoice(...);
///   });
Future<T> withLoadingOverlay<T>(
  BuildContext context, {
  required Future<T> Function() task,
  String message = 'Please wait…',
}) async {
  final route = _LoadingRoute(message: message);
  Navigator.of(context).push(route);
  try {
    final result = await task();
    if (context.mounted) Navigator.of(context).removeRoute(route);
    return result;
  } catch (e) {
    if (context.mounted) Navigator.of(context).removeRoute(route);
    rethrow;
  }
}

class _LoadingRoute extends ModalRoute<void> {
  final String message;
  _LoadingRoute({required this.message});

  @override
  Duration get transitionDuration => const Duration(milliseconds: 180);
  @override
  bool get opaque => false;
  @override
  bool get barrierDismissible => false;
  @override
  Color get barrierColor => Colors.black.withAlpha(160);
  @override
  String? get barrierLabel => null;
  @override
  bool get maintainState => true;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return FadeTransition(
      opacity: animation,
      child: Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(60),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 48,
                  height: 48,
                  child: CircularProgressIndicator(strokeWidth: 3),
                ),
                const SizedBox(height: 20),
                Text(
                  message,
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
