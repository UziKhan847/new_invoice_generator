import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/widgets.dart' as pw;

/// Loads (once) and exposes the Unicode-capable fonts used for PDF
/// generation, reusing the app's bundled Plus Jakarta Sans TTFs instead of
/// the default base-14 Helvetica (which is Latin-1 only).
class PdfFonts {
  static pw.Font? _regular;
  static pw.Font? _bold;

  static Future<void> ensureLoaded() async {
    _regular ??= pw.Font.ttf(
      await rootBundle.load('assets/fonts/PlusJakartaSans-Regular.ttf'),
    );
    _bold ??= pw.Font.ttf(
      await rootBundle.load('assets/fonts/PlusJakartaSans-Bold.ttf'),
    );
  }

  static pw.ThemeData get theme =>
      pw.ThemeData.withFont(base: _regular!, bold: _bold!);
}
