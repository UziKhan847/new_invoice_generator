import 'package:flutter/material.dart';
import 'package:new_invoice_generator/models/invoice/invoice.dart';
import 'package:url_launcher/url_launcher.dart';

class SmsService {
  /// Opens the device's SMS app pre-filled with invoice summary.
  /// Only works on physical phones (not tablets/desktop).
  /// Shows a warning dialog about carrier rates first.
  static Future<void> sendInvoiceSms({
    required BuildContext context,
    required Invoice invoice,
    required String recipientPhone,
  }) async {
    // Warn user about SMS rates
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 20),
            SizedBox(width: 8),
            Text('Send via SMS?'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Sending to: $recipientPhone'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange.withAlpha(20),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withAlpha(60)),
              ),
              child: const Text(
                '⚠️ Standard SMS and carrier messaging rates may apply '
                'to you and the recipient. International SMS rates may '
                'be significantly higher.',
                style: TextStyle(fontSize: 12),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'The invoice summary will open in your SMS app. '
              'You can review and edit before sending.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Open SMS App'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final body = _buildSmsBody(invoice);
    final smsUri = Uri(
      scheme: 'sms',
      path: recipientPhone,
      query: 'body=${Uri.encodeComponent(body)}',
    );

    if (await canLaunchUrl(smsUri)) {
      await launchUrl(smsUri);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Could not open SMS app. Make sure you are on a phone.')),
      );
    }
  }

  static String _buildSmsBody(Invoice invoice) {
    final buf = StringBuffer();
    buf.writeln('Invoice #${invoice.invoiceNumber}');
    buf.writeln('From: ${invoice.senderName ?? 'Your provider'}');
    buf.writeln('Total: \$${invoice.total.toStringAsFixed(2)} CAD');
    buf.writeln('Date: ${invoice.issueDate.toLocal().toString().split(' ')[0]}');
    if (invoice.dueDate != null) {
      buf.writeln('Due: ${invoice.dueDate!.toLocal().toString().split(' ')[0]}');
    }
    buf.writeln();
    // Items
    for (final item in invoice.items) {
      buf.writeln('• ${item.description}: x${item.quantityDisplay} @ \$${item.unitPrice.toStringAsFixed(2)} = \$${item.total.toStringAsFixed(2)}');
    }
    buf.writeln();
    if (invoice.senderEmail != null) {
      buf.writeln('E-transfer to: ${invoice.senderEmail}');
      buf.writeln('Ref: Invoice #${invoice.invoiceNumber}');
    }
    if (invoice.stripePaymentLink?.isNotEmpty == true) {
      buf.writeln();
      buf.writeln('Pay online: ${invoice.stripePaymentLink}');
    }
    return buf.toString().trim();
  }
}