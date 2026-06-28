import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:new_invoice_generator/app_theme.dart';
import 'package:new_invoice_generator/models/home_analytics.dart';
import 'package:new_invoice_generator/models/invoice/invoice.dart';
import 'package:new_invoice_generator/providers/company.dart';
import 'package:new_invoice_generator/providers/invoice/invoice.dart';
import 'package:new_invoice_generator/desktop/invoice/detail.dart';
import 'package:new_invoice_generator/desktop/shell.dart';
import 'package:new_invoice_generator/desktop/widgets.dart';
import 'package:new_invoice_generator/screens/home/widgets/paid_unpaid_donut.dart';
import 'package:new_invoice_generator/screens/home/widgets/revenue_bar_chart.dart';
import 'package:new_invoice_generator/screens/home/widgets/ui_kit.dart';
import 'package:new_invoice_generator/screens/invoice/create/create.dart';

class DesktopOverview extends ConsumerStatefulWidget {
  const DesktopOverview({super.key});

  @override
  ConsumerState<DesktopOverview> createState() => _DesktopOverviewState();
}

class _DesktopOverviewState extends ConsumerState<DesktopOverview> {
  int? _selectedBar;

  @override
  Widget build(BuildContext context) {
    final p = AppColors.of(context);
    final analyticsAsync = ref.watch(homeAnalyticsProvider);
    final company = ref.watch(companyProvider).asData?.value ?? {};
    final ownerName =
        (company['email'] as String?)?.split('@').first ?? 'there';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DesktopTopBar(
          title: 'Overview',
          subtitle: 'Welcome back, $ownerName',
          actions: [
            const DesktopSearchField(hint: 'Search invoices, customers'),
            const SizedBox(width: 12),
            DesktopPrimaryButton(
              icon: Icons.add,
              label: 'New Invoice',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreateInvoiceScreen()),
              ),
            ),
            const SizedBox(width: 10),
            _IconBtn(icon: Icons.notifications_outlined, onTap: () {}),
          ],
        ),
        Expanded(
          child: analyticsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (a) {
              final collection = (a.totalRevenue + a.unpaid) == 0
                  ? 0.0
                  : a.totalRevenue / (a.totalRevenue + a.unpaid) * 100;
              final dueCount =
                  ref
                      .watch(invoiceProvider)
                      .asData
                      ?.value
                      .where((i) => !i.isPaid && !i.isPrivate)
                      .length ??
                  0;

              return ListView(
                padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
                children: [
                  // KPI row
                  Row(
                    children: [
                      Expanded(
                        child: DesktopKpiCard(
                          label: 'Billed this month',
                          value: '\$${a.monthRevenue.toStringAsFixed(2)}',
                          icon: Icons.calendar_today_outlined,
                          tint: p.primaryTint,
                          fg: p.primary,
                          badge: _monthAbbr(DateTime.now().month),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DesktopKpiCard(
                          label: 'Outstanding',
                          value: '\$${a.unpaid.toStringAsFixed(2)}',
                          icon: Icons.warning_amber_rounded,
                          tint: p.warningBg,
                          fg: p.warningText,
                          badge: dueCount > 0 ? '$dueCount due' : null,
                          badgeBg: p.warningBg,
                          badgeFg: p.warningText,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DesktopKpiCard(
                          label: 'Total revenue',
                          value: '\$${a.totalRevenue.toStringAsFixed(0)}',
                          icon: Icons.attach_money,
                          tint: p.successBg,
                          fg: p.successText,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DesktopKpiCard(
                          label: 'Collection rate',
                          value: '${collection.toStringAsFixed(1)}%',
                          icon: Icons.check_circle_outline,
                          tint: p.successBg,
                          fg: p.successText,
                          badge: '${a.totalInvoices} inv',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Monthly revenue (full width)
                  DesktopPanel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _RevenueHeader(analytics: a, selectedBar: _selectedBar),
                        const SizedBox(height: 18),
                        SizedBox(
                          height: 260,
                          child: RevenueBarChart(
                            bars: a.monthlyBars,
                            selectedIndex: _selectedBar,
                            onBarTap: (i) => setState(() => _selectedBar = i),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Recent invoices + donut
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 3, child: _RecentInvoices()),
                        const SizedBox(width: 20),
                        Expanded(
                          flex: 2,
                          child: DesktopPanel(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Paid vs Unpaid',
                                  style: AppTypography.title(
                                    p.ink,
                                  ).copyWith(fontSize: 17),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${collection.toStringAsFixed(1)}% collected · \$${a.unpaid.toStringAsFixed(2)} outstanding',
                                  style: AppTypography.bodyMuted(
                                    p.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  height: 280,
                                  child: PaidUnpaidDonut(
                                    paid: a.paidAmount,
                                    unpaid: a.unpaidAmount,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  static String _monthAbbr(int m) => const [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ][m - 1];
}

class _RevenueHeader extends StatelessWidget {
  final HomeAnalytics analytics;
  final int? selectedBar;
  const _RevenueHeader({required this.analytics, this.selectedBar});

  @override
  Widget build(BuildContext context) {
    final p = AppColors.of(context);
    final bars = analytics.monthlyBars;
    int defaultIdx = -1;
    double maxVal = -1;
    for (var i = 0; i < bars.length; i++) {
      if (bars[i].value > maxVal) {
        maxVal = bars[i].value;
        defaultIdx = i;
      }
    }
    final activeIdx =
        (selectedBar != null && selectedBar! >= 0 && selectedBar! < bars.length)
        ? selectedBar!
        : defaultIdx;
    final active = activeIdx >= 0 && activeIdx < bars.length
        ? bars[activeIdx]
        : null;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Monthly Revenue',
                style: AppTypography.title(p.ink).copyWith(fontSize: 17),
              ),
              const SizedBox(height: 2),
              Text(
                'Total paid \$${analytics.totalRevenue.toStringAsFixed(2)}',
                style: AppTypography.bodyMuted(p.textSecondary),
              ),
            ],
          ),
        ),
        if (active != null) ...[
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                active.label.replaceAll('\n', ' '),
                style: AppTypography.label(p.textTertiary),
              ),
              Text(
                '\$${active.value.toStringAsFixed(0)}',
                style: AppTypography.amount(p.primary).copyWith(fontSize: 24),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _RecentInvoices extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = AppColors.of(context);
    final invoices =
        (ref.watch(invoiceProvider).asData?.value ?? [])
            .where((i) => !i.isPrivate)
            .toList()
          ..sort((a, b) => b.issueDate.compareTo(a.issueDate));
    final recent = invoices.take(6).toList();

    return DesktopPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Recent Invoices',
                style: AppTypography.title(p.ink).copyWith(fontSize: 17),
              ),
              const Spacer(),
              InkWell(
                onTap: () => ref.read(desktopNavProvider.notifier).select(1),
                child: Text(
                  'View all',
                  style: AppTypography.body(p.primary).copyWith(fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Header row
          Row(
            children: [
              Expanded(flex: 4, child: _hcell(context, 'INVOICE')),
              Expanded(flex: 3, child: _hcell(context, 'DATE')),
              Expanded(flex: 2, child: _hcell(context, 'AMOUNT', right: true)),
              Expanded(flex: 2, child: _hcell(context, 'STATUS', right: true)),
            ],
          ),
          const SizedBox(height: 4),
          Divider(height: 1, color: p.border),
          if (recent.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'No invoices yet',
                  style: AppTypography.bodyMuted(p.textTertiary),
                ),
              ),
            )
          else
            ...recent.map((inv) => _RecentRow(invoice: inv)),
        ],
      ),
    );
  }

  Widget _hcell(BuildContext context, String t, {bool right = false}) {
    final p = AppColors.of(context);
    return Text(
      t,
      textAlign: right ? TextAlign.right : TextAlign.left,
      style: AppTypography.label(p.textTertiary),
    );
  }
}

class _RecentRow extends StatelessWidget {
  final Invoice invoice;
  const _RecentRow({required this.invoice});

  @override
  Widget build(BuildContext context) {
    final p = AppColors.of(context);
    final date = invoice.issueDate.toIso8601String().split('T').first;
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DesktopInvoiceDetail(invoiceId: invoice.id ?? ''),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 11),
        child: Row(
          children: [
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    invoice.invoiceNumber,
                    style: AppTypography.title(p.ink).copyWith(fontSize: 14),
                  ),
                  Text(
                    invoice.customerName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.caption(p.textSecondary),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                date,
                style: AppTypography.body(
                  p.textSecondary,
                ).copyWith(fontSize: 13),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                '\$${invoice.total.toStringAsFixed(2)}',
                textAlign: TextAlign.right,
                style: AppTypography.title(p.ink).copyWith(fontSize: 14),
              ),
            ),
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerRight,
                child: invoice.isPaid
                    ? AppPill.paid(context)
                    : AppPill.unpaid(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _IconBtn({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final p = AppColors.of(context);
    return Material(
      color: p.surface,
      borderRadius: BorderRadius.circular(AppRadii.button),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.button),
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.button),
            border: Border.all(color: p.cardBorder),
          ),
          child: Icon(icon, size: 20, color: p.ink),
        ),
      ),
    );
  }
}
