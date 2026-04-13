import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:new_invoice_generator/models/expense.dart';
import 'package:new_invoice_generator/models/invoice.dart';
import 'package:new_invoice_generator/providers/expense.dart';
import 'package:new_invoice_generator/providers/invoice.dart';

/// Shows a "Mark as Paid" confirmation.
/// If the invoice has a Stripe payment link, also offers to log the Stripe fee
/// as a business expense in one step.
///
/// Returns true if the invoice was marked paid, false/null otherwise.
Future<bool> showMarkPaidDialog({
  required BuildContext context,
  required WidgetRef ref,
  required Invoice invoice,
}) async {
  final hasStripe = invoice.stripePaymentLink?.isNotEmpty == true;

  if (hasStripe) {
    return await showDialog<bool>(
          context: context,
          builder: (_) => _StripePaidDialog(invoice: invoice),
        ) ??
        false;
  }

  // Plain confirmation for non-Stripe invoices
  final confirm = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Mark as paid?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Mark Paid', style: TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );

  if (confirm == true) {
    await ref.read(invoiceProvider.notifier).markPaid(invoice.id!);
    return true;
  }
  return false;
}

// ── Stripe-aware paid dialog ──────────────────────────────────────────────────
class _StripePaidDialog extends ConsumerStatefulWidget {
  final Invoice invoice;
  const _StripePaidDialog({required this.invoice});

  @override
  ConsumerState<_StripePaidDialog> createState() => _StripePaidDialogState();
}

class _StripePaidDialogState extends ConsumerState<_StripePaidDialog> {
  bool _logFee = true;
  final _feeCtrl = TextEditingController();
  bool _saving = false;

  // Pre-calculate a Stripe fee estimate (3.9% + $0.30 for international card)
  double get _estimatedFee => (widget.invoice.total * 0.039 + 0.30);

  @override
  void initState() {
    super.initState();
    _feeCtrl.text = _estimatedFee.toStringAsFixed(2);
  }

  @override
  void dispose() {
    _feeCtrl.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    setState(() => _saving = true);
    try {
      // Mark the invoice paid
      await ref.read(invoiceProvider.notifier).markPaid(widget.invoice.id!);

      // Optionally log Stripe fee as expense
      if (_logFee) {
        final fee = double.tryParse(_feeCtrl.text) ?? _estimatedFee;
        if (fee > 0) {
          final expense = Expense(
            description:
                'Stripe fee — Invoice #${widget.invoice.invoiceNumber}',
            category: 'Professional Services',
            date: DateTime.now(),
            amount: fee,
            taxAmount: 0,
            vendor: 'Stripe',
            notes:
                'Processing fee for Invoice #${widget.invoice.invoiceNumber} '
                '(\$${widget.invoice.total.toStringAsFixed(2)} CAD)',
          );
          await ref.read(expenseProvider.notifier).add(expense);
        }
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return AlertDialog(
      title: const Text('Mark as Paid via Stripe'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Invoice amount
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.green.withAlpha(20),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Invoice total:', style: TextStyle(fontSize: 13)),
                Text(
                  '\$${widget.invoice.total.toStringAsFixed(2)} CAD',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Stripe fee toggle
          Row(
            children: [
              Checkbox(
                value: _logFee,
                onChanged: (v) => setState(() => _logFee = v ?? true),
              ),
              const Expanded(
                child: Text(
                  'Log Stripe fee as business expense',
                  style: TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),

          // Fee amount field
          if (_logFee) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _feeCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Fee amount (\$)',
                      prefixText: '\$',
                      isDense: true,
                      helperText: 'Check Stripe dashboard for exact fee',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF635BFF).withAlpha(15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline,
                    size: 13,
                    color: Color(0xFF635BFF),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Estimated: \$${_estimatedFee.toStringAsFixed(2)} '
                      '(3.9% + \$0.30). Check your Stripe dashboard '
                      'for the exact amount and update above.',
                      style: TextStyle(
                        fontSize: 10,
                        color: cs.onSurface.withAlpha(150),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          onPressed: _saving ? null : _confirm,
          child: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Mark Paid', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
