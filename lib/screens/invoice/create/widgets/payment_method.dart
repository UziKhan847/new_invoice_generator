import 'package:flutter/material.dart';
import 'package:new_invoice_generator/screens/invoice/create/widgets/invoice_form_helpers.dart';

/// The three supported payment methods.
enum PaymentMethod {
  etransfer('etransfer', 'E-Transfer', Icons.account_balance_wallet_outlined),
  stripe('stripe', 'Stripe', Icons.credit_card_outlined),
  other('other', 'Other / Cash', Icons.payments_outlined);

  final String value;
  final String label;
  final IconData icon;
  const PaymentMethod(this.value, this.label, this.icon);

  static PaymentMethod fromValue(String v) => PaymentMethod.values.firstWhere(
    (m) => m.value == v,
    orElse: () => PaymentMethod.etransfer,
  );
}

class PaymentMethodSection extends StatelessWidget {
  final PaymentMethod selected;
  final String? senderEmail; // for e-transfer hint
  final String? stripeLink; // current stripe link value
  final TextEditingController stripeLinkCtrl;
  final ValueChanged<PaymentMethod> onMethodChanged;

  const PaymentMethodSection({
    super.key,
    required this.selected,
    required this.senderEmail,
    required this.stripeLink,
    required this.stripeLinkCtrl,
    required this.onMethodChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SectionCard(
      title: 'Payment Method',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Segmented selector
          SegmentedButton<PaymentMethod>(
            segments: PaymentMethod.values
                .map(
                  (m) => ButtonSegment<PaymentMethod>(
                    value: m,
                    label: Text(m.label, style: const TextStyle(fontSize: 12)),
                    icon: Icon(m.icon, size: 16),
                  ),
                )
                .toList(),
            selected: {selected},
            onSelectionChanged: (s) => onMethodChanged(s.first),
            style: SegmentedButton.styleFrom(minimumSize: const Size(0, 40)),
          ),
          const SizedBox(height: 12),

          // Contextual content per method
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: KeyedSubtree(
              key: ValueKey(selected),
              child: switch (selected) {
                PaymentMethod.etransfer => _ETransferInfo(
                  senderEmail: senderEmail,
                  cs: cs,
                ),
                PaymentMethod.stripe => _StripeInfo(
                  stripeLinkCtrl: stripeLinkCtrl,
                  cs: cs,
                ),
                PaymentMethod.other => _OtherInfo(cs: cs),
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── E-Transfer ─────────────────────────────────────────────────────────────
class _ETransferInfo extends StatelessWidget {
  final String? senderEmail;
  final ColorScheme cs;
  const _ETransferInfo({required this.senderEmail, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.withAlpha(15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.withAlpha(50)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.account_balance_wallet_outlined,
                size: 15,
                color: Colors.green,
              ),
              SizedBox(width: 8),
              Text(
                'E-Transfer payment',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (senderEmail != null && senderEmail!.isNotEmpty)
            Text(
              'Customer will be instructed to e-transfer to: $senderEmail',
              style: TextStyle(
                fontSize: 12,
                color: cs.onSurface.withAlpha(160),
              ),
            )
          else
            Text(
              'Select a sender/employee above to show their e-transfer email on the invoice.',
              style: TextStyle(
                fontSize: 12,
                color: cs.onSurface.withAlpha(130),
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      ),
    );
  }
}

// ── Stripe ──────────────────────────────────────────────────────────────────
class _StripeInfo extends StatelessWidget {
  final TextEditingController stripeLinkCtrl;
  final ColorScheme cs;
  const _StripeInfo({required this.stripeLinkCtrl, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: stripeLinkCtrl,
          keyboardType: TextInputType.url,
          decoration: const InputDecoration(
            labelText: 'Stripe Payment Link',
            hintText: 'https://buy.stripe.com/...',
            prefixIcon: Icon(Icons.link_outlined),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF635BFF).withAlpha(12),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF635BFF).withAlpha(50)),
          ),
          child: Text(
            'The PDF and email will show a "Pay Now" button. '
            'Always set the Stripe amount in CAD to match this invoice. '
            'E-transfer instructions will NOT appear.',
            style: TextStyle(fontSize: 11, color: cs.onSurface.withAlpha(150)),
          ),
        ),
      ],
    );
  }
}

// ── Other / Cash ────────────────────────────────────────────────────────────
class _OtherInfo extends StatelessWidget {
  final ColorScheme cs;
  const _OtherInfo({required this.cs});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withAlpha(100),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cs.outlineVariant.withAlpha(80)),
      ),
      child: Text(
        'No specific payment instructions will appear on the invoice or PDF. '
        'Use the Notes field below to add custom payment details if needed '
        '(e.g. "Cash accepted", "Cheque payable to…").',
        style: TextStyle(fontSize: 12, color: cs.onSurface.withAlpha(160)),
      ),
    );
  }
}
