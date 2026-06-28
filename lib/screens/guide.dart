import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class GuideScreen extends StatelessWidget {
  const GuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      appBar: AppBar(title: const Text('How to Use This App')),
      body: ListView(
        padding: EdgeInsets.fromLTRB(16, 16, 16, bottom + 24),
        children: [
          ...guideSections,
          const SizedBox(height: 8),
          OutlinedButton.icon(
            icon: const Icon(Icons.open_in_new),
            label: const Text('Open Stripe Dashboard'),
            onPressed: () => launchUrl(
              Uri.parse('https://dashboard.stripe.com'),
              mode: LaunchMode.externalApplication,
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            icon: const Icon(Icons.open_in_new),
            label: const Text('CRA HST/GST Guide'),
            onPressed: () => launchUrl(
              Uri.parse(
                'https://www.canada.ca/en/revenue-agency/services/tax/businesses/topics/gst-hst-businesses.html',
              ),
              mode: LaunchMode.externalApplication,
            ),
          ),
        ],
      ),
    );
  }
}

/// Shared guide content, reused by the mobile and desktop guide screens.
const List<Widget> guideSections = [
  GuideSection(
    icon: Icons.receipt_long_outlined,
    title: 'Creating an Invoice',
    color: Colors.blue,
    steps: [
      '1. Tap the + button from the Invoices or Home screen.',
      '2. Select a customer — their email auto-fills for you.',
      '3. Select the employee (sender) who delivered the service.',
      '4. Add items by typing a description, quantity, and price.',
      '   Tip: tap a Service chip to quick-add a preset service.',
      '5. Use decimal quantities for partial hours/weeks (e.g. 3.5).',
      '6. Add a discount per item if applicable (% or flat \$).',
      '7. Toggle "International" if the customer is outside Canada — tax becomes 0% automatically.',
      '8. Optionally add a Stripe payment link and notes/terms.',
      '9. Tap Save Invoice.',
    ],
  ),
  GuideSection(
    icon: Icons.credit_card_outlined,
    title: 'Using Stripe for International Customers',
    color: Color(0xFF635BFF),
    steps: [
      'Stripe is used for international customers who cannot e-transfer.',
      '',
      'STEP 1 — Create a Payment Link in Stripe:',
      '  • Go to stripe.com → Dashboard → Payment Links → Create.',
      '  • Add your service as a product.',
      '  • Set the currency to CAD (Canadian dollars).',
      '  • Set the exact amount matching your invoice total.',
      '  • Copy the link (e.g. https://buy.stripe.com/abc123).',
      '',
      'STEP 2 — Add the link to your invoice:',
      '  • In the "Stripe Payment Link" field when creating the invoice.',
      '  • The customer will see a "Pay Now" button in the email and PDF.',
      '',
      'STEP 3 — After the customer pays:',
      '  • You receive a Stripe notification.',
      '  • Mark the invoice as paid in the app.',
      '  • Log the Stripe fee as a business expense (see below).',
    ],
  ),
  GuideSection(
    icon: Icons.attach_money,
    title: 'Always Charge in CAD on Stripe',
    color: Colors.green,
    steps: [
      'Always set your Stripe Payment Link amount in Canadian dollars (CAD).',
      '',
      'Why? Because your invoices are in CAD, your bank account is in CAD, '
          'and your tax report is in CAD. Charging in another currency creates '
          'reconciliation headaches.',
      '',
      'If your customer is in the USA, they pay in USD — Stripe converts '
          'automatically at the current rate. You receive CAD in your bank.',
      '',
      'Your invoice and Stripe always show the same CAD number. Simple.',
    ],
  ),
  GuideSection(
    icon: Icons.receipt_outlined,
    title: 'Logging Stripe Fees as Expenses',
    color: Colors.orange,
    steps: [
      'Stripe charges a fee on every payment (typically 2.9–3.9% + \$0.30).',
      'This fee is a legitimate business expense and is tax-deductible.',
      '',
      'After each Stripe payment:',
      '  1. Check your Stripe Dashboard to see the exact fee charged.',
      '  2. Go to More → Expenses → + (add new expense).',
      '  3. Description: "Stripe fee — Invoice #XXX".',
      '  4. Category: "Professional Services" or "Software & Subscriptions".',
      '  5. Amount: the fee amount.',
      '  6. Tax paid: Stripe may charge GST/HST on their fees — check.',
      '  7. Vendor: Stripe.',
      '',
      'These fees appear in your Tax Report as business expenses, '
          'reducing your net profit and your taxable income.',
    ],
  ),
  GuideSection(
    icon: Icons.percent_outlined,
    title: 'Tax: Canadian vs International',
    color: Colors.teal,
    steps: [
      'Canadian customers:',
      '  • Tax is charged automatically based on your province.',
      '  • Ontario = 13% HST, Alberta = 5% GST, etc.',
      '  • Set your province in More → Company Profile.',
      '',
      'International customers (outside Canada):',
      '  • Toggle "International" when creating the invoice.',
      '  • Tax becomes 0% — exports are zero-rated under CRA rules.',
      '  • The invoice clearly states "Export — 0% Tax".',
      '',
      'You can change your province at any time in Company Profile. '
          'Existing invoices are not affected — they keep the tax rate '
          'from when they were created.',
    ],
  ),
  GuideSection(
    icon: Icons.loop_outlined,
    title: 'Recurring Invoices',
    color: Colors.purple,
    steps: [
      'For students/customers you bill every month:',
      '  1. Go to More → Recurring Invoices → +.',
      '  2. Set the customer, service, frequency, and price.',
      '  3. Tap "Generate Now" to instantly create an invoice from the template.',
      '',
      'Tip: use this for monthly Arabic or Quran class billing. '
          'Takes 2 seconds instead of recreating from scratch each month.',
    ],
  ),
  GuideSection(
    icon: Icons.content_copy_outlined,
    title: 'Duplicating Invoices',
    color: Colors.indigo,
    steps: [
      'Need to re-bill a customer for the same service?',
      '  1. Open the existing invoice.',
      '  2. Scroll down and tap "Duplicate Invoice".',
      '  3. A new invoice is created with today\'s date, same items and customer.',
      '  4. Edit as needed before saving.',
      '',
      'Faster than rebuilding from scratch every month.',
    ],
  ),
  GuideSection(
    icon: Icons.calculate_outlined,
    title: 'Tax Report (for CRA filing)',
    color: Colors.red,
    steps: [
      'Go to More → Tax Report to see your annual summary.',
      '',
      'The report shows:',
      '  • Total revenue (pre-tax)',
      '  • HST/GST collected from customers (what you owe CRA)',
      '  • Input tax credits from your business expenses',
      '  • Net tax owing = Tax collected − Input tax credits',
      '  • Net profit = Revenue − Expenses',
      '',
      'Tap "Export Full Tax Report PDF" to share or save the full breakdown.',
      '',
      'Note: this is a summary tool — always consult your accountant for official filing.',
    ],
  ),
  GuideSection(
    icon: Icons.bar_chart_outlined,
    title: 'Charts',
    color: Colors.cyan,
    steps: [
      'The Charts screen lets you visualize your business performance.',
      '',
      '  • Revenue — monthly bars showing paid revenue.',
      '  • Paid / Unpaid — how much has been collected vs outstanding.',
      '  • Count — number of invoices issued per month.',
      '',
      'Use the filters (Year, Customer, Sender) to drill down.',
      'Charts auto-update when you add or mark invoices paid.',
    ],
  ),
];

class GuideSection extends StatefulWidget {
  final IconData icon;
  final String title;
  final Color color;
  final List<String> steps;

  const GuideSection({
    super.key,
    required this.icon,
    required this.title,
    required this.color,
    required this.steps,
  });

  @override
  State<GuideSection> createState() => GuideSectionState();
}

class GuideSectionState extends State<GuideSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => setState(() => _expanded = !_expanded),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: widget.color.withAlpha(25),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(widget.icon, color: widget.color, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    color: cs.onSurface.withAlpha(150),
                  ),
                ],
              ),
              if (_expanded) ...[
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),
                ...widget.steps.map(
                  (step) => step.isEmpty
                      ? const SizedBox(height: 6)
                      : Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            step,
                            style: TextStyle(
                              fontSize: 13,
                              color: cs.onSurface.withAlpha(180),
                              height: 1.4,
                            ),
                          ),
                        ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
