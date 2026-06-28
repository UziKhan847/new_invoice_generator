import 'package:flutter/material.dart';
import 'package:new_invoice_generator/models/invoice/invoice.dart';
import 'package:new_invoice_generator/services/email.dart';

/// Shows the "Email Invoice" dialog. Auto-fills the customer email if present,
/// explains the two-step share-sheet flow, and triggers EmailService on send.
Future<void> showEmailInvoiceDialog({
  required BuildContext context,
  required Invoice invoice,
  String? logoUrl,
}) async {
  final emailCtrl = TextEditingController(text: invoice.customerEmail ?? '');
  await showDialog<void>(
    context: context,
    builder: (dialogCtx) => AlertDialog(
      title: const Text('Email Invoice'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (invoice.customerEmail != null) ...[
            Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 14),
                const SizedBox(width: 6),
                Text(
                  'Auto-filled from customer',
                  style: TextStyle(fontSize: 12, color: Colors.green.shade700),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          TextField(
            controller: emailCtrl,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Recipient email',
              hintText: 'customer@example.com',
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.blue.withAlpha(15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.withAlpha(40)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, size: 14, color: Colors.blue),
                    SizedBox(width: 6),
                    Text(
                      'How it works',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 6),
                Text(
                  '1. Your mail app opens with the recipient pre-filled.\n'
                  '2. A share sheet opens — pick your mail app again to attach the PDF.\n'
                  '3. Hit send.',
                  style: TextStyle(fontSize: 11, color: Colors.blue),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogCtx),
          child: const Text('Cancel'),
        ),
        ElevatedButton.icon(
          icon: const Icon(Icons.send_outlined, size: 16),
          label: const Text('Send'),
          onPressed: () async {
            if (emailCtrl.text.trim().isEmpty) return;
            Navigator.pop(dialogCtx);
            if (!context.mounted) return;
            await EmailService.emailInvoice(
              context: context,
              invoice: invoice,
              recipientEmail: emailCtrl.text.trim(),
              companyLogoUrl: logoUrl,
            );
          },
        ),
      ],
    ),
  );
}
