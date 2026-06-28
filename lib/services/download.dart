import 'dart:io';
import 'package:flutter/material.dart';
import 'package:new_invoice_generator/models/customer.dart';
import 'package:new_invoice_generator/models/invoice/invoice.dart';
import 'package:new_invoice_generator/services/pdf.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';

class DownloadService {
  /// Saves the invoice PDF to a date-organised folder:
  /// Android: /storage/emulated/0/Invoices/{year}/{month}/{filename}.pdf
  /// iOS/other: uses app documents directory then shares via share sheet
  static Future<void> downloadInvoice({
    required BuildContext context,
    required Invoice invoice,
    String? companyLogoUrl,
    Map<String, dynamic>? company,
    Customer? customer,
  }) async {
    final inv = companyLogoUrl != null
        ? invoice.copyWith(companyLogoUrl: companyLogoUrl)
        : invoice;

    final bytes = await PdfService.buildPdfBytes(
      inv,
      company: company,
      customer: customer,
    );

    final date = invoice.issueDate;
    final year = '${date.year}';
    final month = _monthName(date.month);
    final fileName = invoice.fileBaseName;

  if (!context.mounted) return;
    if (Platform.isAndroid) {
      await _saveAndroid(
        context: context,
        bytes: bytes,
        year: year,
        month: month,
        fileName: fileName,
        invoice: invoice,
      );
    } else if (Platform.isIOS) {
      await _saveIos(
        context: context,
        bytes: bytes,
        year: year,
        month: month,
        fileName: fileName,
      );
    } else {
      // Linux / desktop — use printing share dialog
      await _saveDesktop(context: context, bytes: bytes, fileName: fileName);
    }
  }

  // ── Android ──────────────────────────────────────────────────────────────
  static Future<void> _saveAndroid({
    required BuildContext context,
    required List<int> bytes,
    required String year,
    required String month,
    required String fileName,
    required Invoice invoice,
  }) async {
    // Check permission
    final granted = await _requestAndroidPermission(context);
    if (!granted) return;

    try {
      // Save into organised folder on external storage
      final dir = Directory('/storage/emulated/0/Invoices/$year/$month');
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      final filePath = '${dir.path}/$fileName.pdf';
      await File(filePath).writeAsBytes(bytes);

      if (context.mounted) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(
            SnackBar(
              content: Text('Saved: Invoices/$year/$month/$fileName.pdf'),
              duration: const Duration(seconds: 4),
            ),
          );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(
            SnackBar(
              content: Text('Save failed: $e'),
              duration: const Duration(seconds: 4),
            ),
          );
      }
    }
  }

  // ── iOS ───────────────────────────────────────────────────────────────────
  static Future<void> _saveIos({
    required BuildContext context,
    required List<int> bytes,
    required String year,
    required String month,
    required String fileName,
  }) async {
    try {
      // iOS sandboxed — save to Documents then share
      final dir = Directory('${(await _documentsDir())}/Invoices/$year/$month');
      if (!await dir.exists()) await dir.create(recursive: true);

      final filePath = '${dir.path}/$fileName.pdf';
      await File(filePath).writeAsBytes(bytes);

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(filePath, mimeType: 'application/pdf')],
          subject: fileName,
        ),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(
            SnackBar(
              content: Text('Save failed: $e'),
              duration: const Duration(seconds: 4),
            ),
          );
      }
    }
  }

  // ── Desktop / Linux ───────────────────────────────────────────────────────
  static Future<void> _saveDesktop({
    required BuildContext context,
    required List<int> bytes,
    required String fileName,
  }) async {
    try {
      // Save to user's home Documents folder
      final home =
          Platform.environment['HOME'] ??
          Platform.environment['USERPROFILE'] ??
          '/tmp';
      final dir = Directory('$home/Documents/Invoices');
      if (!await dir.exists()) await dir.create(recursive: true);

      final filePath = '${dir.path}/$fileName.pdf';
      await File(filePath).writeAsBytes(bytes);

      if (context.mounted) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(
            SnackBar(
              content: Text('Saved to Documents/Invoices/$fileName.pdf'),
              duration: const Duration(seconds: 4),
            ),
          );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(
            SnackBar(
              content: Text('Save failed: $e'),
              duration: const Duration(seconds: 4),
            ),
          );
      }
    }
  }

  // ── Permission handling (Android) ─────────────────────────────────────────
  static Future<bool> _requestAndroidPermission(BuildContext context) async {
    // Android 13+ uses READ_MEDIA_* — MANAGE_EXTERNAL_STORAGE covers all
    final status = await Permission.manageExternalStorage.status;

    if (status.isGranted) return true;

    if (status.isPermanentlyDenied) {
      // Show dialog to open settings
      if (context.mounted) await _showPermissionDialog(context);
      return false;
    }

    final result = await Permission.manageExternalStorage.request();
    if (result.isGranted) return true;

    if (context.mounted) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(
            content: Text('Storage permission denied. Cannot save file.'),
            duration: Duration(seconds: 4),
          ),
        );
    }
    return false;
  }

  static Future<void> _showPermissionDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Storage Permission Required'),
        content: const Text(
          'To save invoices to your device, please grant storage '
          'permission in Settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  static Future<String> _documentsDir() async {
    if (Platform.isIOS) {
      // path_provider's getApplicationDocumentsDirectory
      final dir = Directory('${Platform.environment['HOME']}/Documents');
      return dir.path;
    }
    return '/tmp';
  }

  static String _monthName(int m) {
    const months = [
      '',
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[m];
  }
}
