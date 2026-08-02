import 'package:flutter/material.dart';
import 'package:new_invoice_generator/app_theme.dart';
import 'package:new_invoice_generator/models/customer.dart';
import 'package:new_invoice_generator/models/invoice/invoice.dart';
import 'package:new_invoice_generator/screens/home/widgets/ui_kit.dart';

/// On-screen rendering of an invoice document, mirroring the PDF layout.
/// Shared by the desktop Invoices preview pane and the invoice detail viewer.
/// Pass [company] (the company row map) and optionally a resolved [customer]
/// so older invoices without a frozen snapshot still show full details.
class InvoiceDocumentView extends StatelessWidget {
  final Invoice invoice;
  final Map<String, dynamic>? company;
  final Customer? customer;

  const InvoiceDocumentView({
    super.key,
    required this.invoice,
    this.company,
    this.customer,
  });

  String _pick(String? snapshot, String? live, [String fallback = '']) {
    if (snapshot != null && snapshot.trim().isNotEmpty) return snapshot;
    if (live != null && live.trim().isNotEmpty) return live;
    return fallback;
  }

  @override
  Widget build(BuildContext context) {
    final p = AppColors.of(context);
    final c = company ?? {};

    final companyName = _pick(
      invoice.companyName,
      c['name'] as String?,
      'My Company',
    );
    final bn = _pick(invoice.businessNumber, c['business_number'] as String?);
    final rt = _pick(invoice.rtNumber, c['rt_number'] as String?);
    final compCity = _pick(invoice.companyAddress.city, c['city'] as String?);
    final compProv = _pick(
      invoice.companyAddress.province,
      c['province_region'] as String?,
    );

    final custName = invoice.customerName.isNotEmpty
        ? invoice.customerName
        : (customer?.name ?? '');
    final custEmail = _pick(invoice.customerEmail, customer?.email);

    final issued = invoice.issueDate.toIso8601String().split('T').first;
    final due = invoice.dueDate?.toIso8601String().split('T').first ?? '—';

    final taxLine = invoice.isExport
        ? 'Export — 0% Tax'
        : '${invoice.taxLabel} (${_pct(invoice.effectiveTaxRate)})';

    final bnLine = [
      if (bn.isNotEmpty) 'BN: $bn',
      if (rt.isNotEmpty) 'RT $rt',
    ].join(' ');
    final locLine = [
      if (compCity.isNotEmpty) compCity,
      if (compProv.isNotEmpty) compProv,
    ].join(', ');

    return Container(
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: p.cardBorder),
        boxShadow: p.cardShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top indigo accent bar
          Container(height: 4, color: p.primary),
          Padding(
            padding: const EdgeInsets.all(26),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Company header + status
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: p.primary,
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Text(
                        _initials(companyName),
                        style: AppTypography.title(
                          Colors.white,
                        ).copyWith(fontSize: 15),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            companyName,
                            style: AppTypography.title(
                              p.ink,
                            ).copyWith(fontSize: 18),
                          ),
                          if (bnLine.isNotEmpty || locLine.isNotEmpty)
                            Text(
                              [
                                bnLine,
                                locLine,
                              ].where((s) => s.isNotEmpty).join(' · '),
                              style: AppTypography.caption(p.textSecondary),
                            ),
                        ],
                      ),
                    ),
                    AppPill(
                      label: invoice.isPaid ? 'Paid' : 'Unpaid',
                      bg: invoice.isPaid ? p.successBg : p.warningBg,
                      text: invoice.isPaid ? p.successText : p.warningText,
                      dot: Icons.circle,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 5,
                      ),
                      fontSize: 12,
                    ),
                  ],
                ),
                const SizedBox(height: 22),

                // TAX INVOICE label + number, issued/due
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'TAX INVOICE',
                            style: AppTypography.label(p.primary),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '#${invoice.invoiceNumber}',
                            style: AppTypography.display(
                              p.ink,
                            ).copyWith(fontSize: 24),
                          ),
                        ],
                      ),
                    ),
                    _DateCol(label: 'ISSUED', value: issued),
                    const SizedBox(width: 28),
                    _DateCol(label: 'DUE', value: due),
                  ],
                ),
                const SizedBox(height: 18),
                Divider(height: 1, color: p.border),
                const SizedBox(height: 18),

                // Billed to + amount
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'BILLED TO',
                            style: AppTypography.label(p.textTertiary),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            custName,
                            style: AppTypography.title(
                              p.ink,
                            ).copyWith(fontSize: 18),
                          ),
                          if (custEmail.isNotEmpty)
                            Text(
                              custEmail,
                              style: AppTypography.bodyMuted(p.textSecondary),
                            ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          invoice.isPaid ? 'AMOUNT PAID' : 'AMOUNT DUE',
                          style: AppTypography.label(p.textTertiary),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '\$${invoice.total.toStringAsFixed(2)}',
                          style: AppTypography.amount(
                            p.ink,
                          ).copyWith(fontSize: 30),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 22),

                // Items table
                _ItemsTable(invoice: invoice),
                const SizedBox(height: 14),
                Divider(height: 1, color: p.border),
                const SizedBox(height: 12),

                // Totals
                Align(
                  alignment: Alignment.centerRight,
                  child: SizedBox(
                    width: 280,
                    child: Column(
                      children: [
                        _totalRow(
                          context,
                          'Subtotal',
                          '\$${invoice.taxableSubtotal.toStringAsFixed(2)}',
                        ),
                        if (invoice.totalDiscountAmount > 0)
                          _totalRow(
                            context,
                            'Discount',
                            '−\$${invoice.totalDiscountAmount.toStringAsFixed(2)}',
                          ),
                        _totalRow(
                          context,
                          taxLine,
                          '\$${invoice.tax.toStringAsFixed(2)}',
                        ),
                        const SizedBox(height: 4),
                        Divider(height: 1, color: p.border),
                        const SizedBox(height: 4),
                        _totalRow(
                          context,
                          'Total',
                          '\$${invoice.total.toStringAsFixed(2)}',
                          bold: true,
                        ),
                      ],
                    ),
                  ),
                ),

                // Notes
                if (invoice.notes != null &&
                    invoice.notes!.trim().isNotEmpty) ...[
                  const SizedBox(height: 18),
                  Text(
                    invoice.notes!,
                    style: AppTypography.bodyMuted(p.textSecondary),
                  ),
                ],

                // Payment box
                const SizedBox(height: 18),
                _PaymentBox(invoice: invoice, custEmail: custEmail),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _totalRow(
    BuildContext context,
    String label,
    String value, {
    bool bold = false,
  }) {
    final p = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: bold
                ? AppTypography.title(p.ink).copyWith(fontSize: 16)
                : AppTypography.bodyMuted(p.textSecondary),
          ),
          Text(
            value,
            style: bold
                ? AppTypography.amount(p.primary).copyWith(fontSize: 19)
                : AppTypography.body(p.ink).copyWith(fontSize: 13),
          ),
        ],
      ),
    );
  }

  static String _pct(double rate) {
    final pc = rate * 100;
    if (pc == pc.truncateToDouble()) return '${pc.toInt()}%';
    return '${pc.toStringAsFixed(2)}%';
  }

  static String _initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((s) => s.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first[0] + parts[1][0]).toUpperCase();
  }
}

class _DateCol extends StatelessWidget {
  final String label, value;
  const _DateCol({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    final p = AppColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(label, style: AppTypography.label(p.textTertiary)),
        const SizedBox(height: 3),
        Text(value, style: AppTypography.title(p.ink).copyWith(fontSize: 14)),
      ],
    );
  }
}

class _ItemsTable extends StatelessWidget {
  final Invoice invoice;
  const _ItemsTable({required this.invoice});
  @override
  Widget build(BuildContext context) {
    final p = AppColors.of(context);
    return Column(
      children: [
        // Header strip
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: p.surfaceAlt,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Expanded(flex: 5, child: _h(context, 'DESCRIPTION')),
              Expanded(flex: 2, child: _h(context, 'QTY', right: true)),
              Expanded(flex: 3, child: _h(context, 'UNIT PRICE', right: true)),
              Expanded(flex: 3, child: _h(context, 'TOTAL', right: true)),
            ],
          ),
        ),
        ...invoice.items.map(
          (it) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 5,
                  child: Text(
                    it.description,
                    style: AppTypography.title(p.ink).copyWith(fontSize: 14),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    it.quantityDisplay,
                    textAlign: TextAlign.right,
                    style: AppTypography.body(p.ink).copyWith(fontSize: 13),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    '\$${it.unitPrice.toStringAsFixed(2)}',
                    textAlign: TextAlign.right,
                    style: AppTypography.body(
                      p.textSecondary,
                    ).copyWith(fontSize: 13),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    '\$${it.total.toStringAsFixed(2)}',
                    textAlign: TextAlign.right,
                    style: AppTypography.title(p.ink).copyWith(fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _h(BuildContext context, String t, {bool right = false}) {
    final p = AppColors.of(context);
    return Text(
      t,
      textAlign: right ? TextAlign.right : TextAlign.left,
      style: AppTypography.label(p.textSecondary),
    );
  }
}

class _PaymentBox extends StatelessWidget {
  final Invoice invoice;
  final String custEmail;
  const _PaymentBox({required this.invoice, required this.custEmail});

  @override
  Widget build(BuildContext context) {
    final p = AppColors.of(context);

    String title;
    List<Widget> body;
    switch (invoice.paymentMethod) {
      case 'stripe':
        title = 'Pay online';
        body = [
          if ((invoice.stripePaymentLink ?? '').isNotEmpty)
            Text(
              invoice.stripePaymentLink!,
              style: AppTypography.body(p.primary).copyWith(fontSize: 13),
            ),
        ];
        break;
      case 'other':
        title = 'Payment';
        body = [
          Text(
            'See the notes above for payment instructions.',
            style: AppTypography.bodyMuted(p.textSecondary),
          ),
        ];
        break;
      default: // etransfer
        title = 'Pay via E-Transfer';
        body = [
          if (custEmail.isNotEmpty)
            Text(
              custEmail,
              style: AppTypography.body(p.primary).copyWith(fontSize: 13),
            ),
          Text(
            'Include invoice #${invoice.invoiceNumber} in the message.',
            style: AppTypography.bodyMuted(p.textSecondary),
          ),
        ];
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.primaryPanel,
        borderRadius: BorderRadius.circular(AppRadii.button),
        border: Border.all(color: p.primaryPanelBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.credit_card, size: 16, color: p.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: AppTypography.title(p.primary).copyWith(fontSize: 14),
              ),
            ],
          ),
          if (body.isNotEmpty) const SizedBox(height: 6),
          ...body,
        ],
      ),
    );
  }
}
