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
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes);

    final subject = 'Invoice ${invoice.invoiceNumber} — ${invoice.customerName}';
    final htmlBody = _buildHtmlBody(invoice);
    final plainBody = _buildPlainBody(invoice);

    if (Platform.isAndroid || Platform.isIOS) {
      try {
        final email = Email(
          recipients: [recipientEmail],
          subject: subject,
          body: htmlBody,
          attachmentPaths: [file.path],
          isHTML: true,
        );
        await FlutterEmailSender.send(email);
        if (context.mounted) {
          ScaffoldMessenger.of(context)
            ..clearSnackBars()
            ..showSnackBar(
                const SnackBar(content: Text('Email opened successfully!')));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context)
            ..clearSnackBars()
            ..showSnackBar(SnackBar(content: Text('Error opening email: $e')));
        }
      }
    } else {
      // Linux / desktop — mailto with plain text body + separate PDF share
      final mailUri = Uri(
        scheme: 'mailto',
        path: recipientEmail,
        query: 'subject=${Uri.encodeQueryComponent(subject)}'
            '&body=${Uri.encodeQueryComponent(plainBody)}',
      );
      if (await canLaunchUrl(mailUri)) await launchUrl(mailUri);
      await Printing.sharePdf(bytes: bytes, filename: fileName);
    }
  }

  // ── HTML email body ────────────────────────────────────────────────────────
  static String _buildHtmlBody(Invoice invoice) {
    final itemRows = invoice.items.map((item) {
      final subtotalStr = '\$${item.subtotal.toStringAsFixed(2)}';
      final totalStr = '\$${item.total.toStringAsFixed(2)}';
      final discountHtml = item.hasDiscount
          ? '<br><small style="color:#888">Discount: ${item.discountLabel} '
              '(−\$${item.discountAmount.toStringAsFixed(2)})</small>'
          : '';
      return '''
        <tr>
          <td style="padding:8px 12px;border-bottom:1px solid #eee">
            ${item.description}$discountHtml
          </td>
          <td style="padding:8px 12px;border-bottom:1px solid #eee;text-align:center">${item.quantity}</td>
          <td style="padding:8px 12px;border-bottom:1px solid #eee;text-align:right">\$${item.unitPrice.toStringAsFixed(2)}</td>
          <td style="padding:8px 12px;border-bottom:1px solid #eee;text-align:right;${item.hasDiscount ? 'font-weight:bold' : ''}">
            ${item.hasDiscount ? '<span style="text-decoration:line-through;color:#aaa;font-size:11px">$subtotalStr</span><br>' : ''}
            $totalStr
          </td>
        </tr>''';
    }).join('\n');

    final dueDateHtml = invoice.dueDate != null
        ? '<p style="margin:4px 0;color:#555">Due Date: '
            '<strong>${invoice.dueDate!.toLocal().toString().split(' ')[0]}</strong></p>'
        : '';

    // Payment section — conditional on invoice.paymentMethod
    final paymentHtml = () {
      if (invoice.isPaid) {
        return '<div style="margin-top:16px;padding:12px;background:#f0fff4;border-radius:8px;border:1px solid #86efac">'
            '<p style="margin:0;font-size:13px;color:#16a34a;font-weight:bold">✓ PAID</p></div>';
      }
      switch (invoice.paymentMethod) {
        case 'etransfer':
          if (invoice.senderEmail == null) return '';
          return '<div style="margin-top:16px;padding:12px;background:#f0fdf4;border-radius:8px;border:1px solid #86efac">'
              '<p style="margin:0;font-size:13px;font-weight:bold;color:#16a34a">💸 Pay via E-Transfer</p>'
              '<p style="margin:6px 0 0;font-size:13px;color:#333">Send to: '
              '<a href="mailto:\${invoice.senderEmail}">\${invoice.senderEmail}</a></p>'
              '<p style="margin:4px 0 0;font-size:11px;color:#888">'
              'Please include invoice #\${invoice.invoiceNumber} in the message.</p></div>';
        case 'stripe':
          final linkPart = invoice.stripePaymentLink?.isNotEmpty == true
              ? '<div style="text-align:center;margin-top:12px">'
                '<a href="\${invoice.stripePaymentLink}" style="display:inline-block;padding:14px 32px;'
                'background:#635bff;color:white;text-decoration:none;border-radius:8px;font-size:16px;font-weight:bold">'
                '💳 Pay Now — \$\${invoice.total.toStringAsFixed(2)} CAD</a>'
                '<p style="margin:8px 0 0;font-size:11px;color:#aaa">Secure payment via Stripe. Amount in CAD.</p></div>'
              : '<p style="font-size:12px;color:#555;margin-top:6px">Contact sender for payment link.</p>';
          return '<div style="margin-top:16px;padding:12px;background:#f5f3ff;border-radius:8px;border:1px solid #c4b5fd">'
              '<p style="margin:0;font-size:13px;font-weight:bold;color:#635bff">💳 Pay Online via Stripe</p>'
              '$linkPart</div>';
        default:
          return ''; // 'other' — no payment instructions
      }
    }();

    final senderHtml = invoice.senderName != null
        ? '''
        <div style="margin-top:16px;padding:12px;background:#f8f8f8;border-radius:8px">
          <p style="margin:0;font-size:13px;color:#333">
            <strong>From:</strong> ${invoice.senderName}
            ${invoice.senderRole != null ? '· ${invoice.senderRole}' : ''}
          </p>
          ${invoice.senderEmail != null ? '''
          <p style="margin:4px 0 0;font-size:13px;color:#333">
            <strong>E-Transfer:</strong>
            <a href="mailto:${invoice.senderEmail}">${invoice.senderEmail}</a>
          </p>
          <p style="margin:4px 0 0;font-size:11px;color:#888">
            Please include invoice #${invoice.invoiceNumber} in the e-transfer message.
          </p>''' : ''}
        </div>''' : '';

    final notesHtml = (invoice.notes?.isNotEmpty == true)
        ? '''
        <div style="margin-top:20px;padding:12px;border:1px solid #eee;border-radius:8px">
          <p style="margin:0 0 6px;font-weight:bold;color:#333;font-size:13px">Notes & Payment Terms</p>
          <p style="margin:0;color:#555;font-size:13px">${invoice.notes}</p>
        </div>''' : '';

    return '''
<!DOCTYPE html>
<html>
<body style="font-family:Arial,sans-serif;color:#333;max-width:600px;margin:0 auto;padding:20px">

  <div style="background:#1a1a2e;color:white;padding:20px 24px;border-radius:12px 12px 0 0">
    <h2 style="margin:0;font-size:22px">Invoice ${invoice.invoiceNumber}</h2>
    <p style="margin:4px 0 0;opacity:0.8;font-size:14px">${invoice.customerName}</p>
  </div>

  <div style="border:1px solid #eee;border-top:none;padding:20px 24px;border-radius:0 0 12px 12px">

    <p style="margin:0 0 4px;color:#555">
      Issue Date: <strong>${invoice.issueDate.toLocal().toString().split(' ')[0]}</strong>
    </p>
    $dueDateHtml

    <!-- Items table -->
    <table style="width:100%;border-collapse:collapse;margin-top:20px">
      <thead>
        <tr style="background:#f5f5f5">
          <th style="padding:8px 12px;text-align:left;font-size:13px">Description</th>
          <th style="padding:8px 12px;text-align:center;font-size:13px">Qty</th>
          <th style="padding:8px 12px;text-align:right;font-size:13px">Unit Price</th>
          <th style="padding:8px 12px;text-align:right;font-size:13px">Total</th>
        </tr>
      </thead>
      <tbody>
        $itemRows
      </tbody>
    </table>

    <!-- Totals -->
    <table style="width:100%;margin-top:12px">
      <tr>
        <td style="padding:4px 12px;text-align:right;color:#555">Subtotal</td>
        <td style="padding:4px 12px;text-align:right;min-width:100px">
          \$${invoice.subtotal.toStringAsFixed(2)}
        </td>
      </tr>
      <tr>
        <td style="padding:4px 12px;text-align:right;color:#555">
          \${invoice.isExport ? 'Export — 0% Tax' : '${invoice.taxLabel}'}
        </td>
        <td style="padding:4px 12px;text-align:right">
          \$\${invoice.tax.toStringAsFixed(2)}
        </td>
      </tr>
      <tr style="font-size:16px;font-weight:bold">
        <td style="padding:8px 12px;text-align:right;border-top:2px solid #333">Total</td>
        <td style="padding:8px 12px;text-align:right;border-top:2px solid #333;color:#1a1a2e">
          \$${invoice.total.toStringAsFixed(2)}
        </td>
      </tr>
    </table>

    $paymentHtml
    $senderHtml
    $notesHtml

    <hr style="border:none;border-top:1px solid #eee;margin:24px 0">
    <p style="margin:0;font-size:12px;color:#aaa;text-align:center">
      The full invoice PDF is attached to this email for your records.
    </p>
  </div>

</body>
</html>''';
  }

  // ── Plain text fallback (for Linux/desktop mailto) ─────────────────────────
  static String _buildPlainBody(Invoice invoice) {
    final lines = StringBuffer();
    lines.writeln('Dear ${invoice.customerName},');
    lines.writeln();
    lines.writeln('Please find below the details for Invoice ${invoice.invoiceNumber}.');
    lines.writeln('Issue Date: ${invoice.issueDate.toLocal().toString().split(' ')[0]}');
    if (invoice.dueDate != null) {
      lines.writeln('Due Date: ${invoice.dueDate!.toLocal().toString().split(' ')[0]}');
    }
    lines.writeln();
    lines.writeln('ITEMS');
    lines.writeln('─────────────────────────────────────────');
    for (final item in invoice.items) {
      lines.writeln(
          '${item.description} × ${item.quantity}  @  \$${item.unitPrice.toStringAsFixed(2)}  =  \$${item.total.toStringAsFixed(2)}');
      if (item.hasDiscount) {
        lines.writeln('  Discount: ${item.discountLabel}  (−\$${item.discountAmount.toStringAsFixed(2)})');
      }
    }
    lines.writeln('─────────────────────────────────────────');
    lines.writeln('Subtotal: \$${invoice.subtotal.toStringAsFixed(2)}');
    lines.writeln('Tax (13%): \$${invoice.tax.toStringAsFixed(2)}');
    lines.writeln('TOTAL: \$${invoice.total.toStringAsFixed(2)}');
    switch (invoice.paymentMethod) {
      case 'etransfer':
        if (invoice.senderEmail != null) {
          lines.writeln();
          lines.writeln('Pay via E-Transfer to: ${invoice.senderEmail}');
          lines.writeln('Please include invoice #${invoice.invoiceNumber} in the message.');
        }
      case 'stripe':
        lines.writeln();
        if (invoice.stripePaymentLink?.isNotEmpty == true) {
          lines.writeln('Pay via Stripe: ${invoice.stripePaymentLink}');
        } else {
          lines.writeln('Pay via Stripe — contact sender for payment link.');
        }
      default:
        break;
    }
    if (invoice.notes?.isNotEmpty == true) {
      lines.writeln();
      lines.writeln('Notes: ${invoice.notes}');
    }
    lines.writeln();
    lines.writeln('The full invoice PDF is attached for your records.');
    return lines.toString();
  }
}