import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'package:new_invoice_generator/models/invoice.dart';
import 'package:new_invoice_generator/services/pdf.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';

class EmailService {
  static Future<void> emailInvoice({
    required BuildContext context,
    required Invoice invoice,
    required String recipientEmail,
    String? companyLogoUrl,
  }) async {
    final inv = companyLogoUrl != null
        ? invoice.copyWith(companyLogoUrl: companyLogoUrl)
        : invoice;

    final bytes = await PdfService.buildPdfBytes(inv);
    final fileName = 'invoice_${invoice.invoiceNumber}.pdf';

    // Save to temp file (needed for attachment on all platforms)
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes);

    final subject =
        'Invoice ${invoice.invoiceNumber} - ${invoice.customerName}';
    final body =
        'Dear ${invoice.customerName},\n\n'
        'Please find attached invoice ${invoice.invoiceNumber} '
        'for \$${invoice.total.toStringAsFixed(2)}.\n\n'
        'Thank you.';

    if (Platform.isAndroid) {
      // Android: flutter_email_sender opens the user's chosen mail app
      // with the PDF already attached and recipient pre-filled
      try {
        final email = Email(
          recipients: [recipientEmail],
          subject: subject,
          body: body,
          attachmentPaths: [file.path],
          isHTML: false,
        );
        await FlutterEmailSender.send(email);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Email sent successfully!')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error sending email: $e')));
        }
      }
    } else if (Platform.isIOS) {
      // iOS: same flutter_email_sender approach works
      try {
        final email = Email(
          recipients: [recipientEmail],
          subject: subject,
          body: body,
          attachmentPaths: [file.path],
          isHTML: false,
        );
        await FlutterEmailSender.send(email);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Email sent successfully!')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error sending email: $e')));
        }
      }
    } else {
      // Linux / desktop: open mailto link, then use printing package to
      // share/save the PDF since share_plus doesn't support Linux files
      final mailUri = Uri.parse(
        'mailto:$recipientEmail'
        '?subject=${Uri.encodeComponent(subject)}'
        '&body=${Uri.encodeComponent(body)}',
      );

      if (await canLaunchUrl(mailUri)) {
        await launchUrl(mailUri);
      }

      // Share PDF via printing (opens system dialog on Linux)
      await Printing.sharePdf(bytes: bytes, filename: fileName);
    }
  }
}
