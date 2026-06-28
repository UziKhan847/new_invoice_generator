import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:new_invoice_generator/app_theme.dart';
import 'package:new_invoice_generator/providers/home_analytics.dart';
import 'package:new_invoice_generator/providers/invoice/invoice.dart';
import 'package:new_invoice_generator/desktop/shell.dart';
import 'package:new_invoice_generator/desktop/widgets.dart';
import 'package:new_invoice_generator/screens/home/widgets/count_line_chart.dart';

class DesktopDashboard extends ConsumerWidget {
  const DesktopDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = AppColors.of(context);
    final analyticsAsync = ref.watch(homeAnalyticsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DesktopTopBar(
          title: 'Dashboard',
          subtitle: 'Performance at a glance',
          actions: [
            OutlinedButton.icon(
              onPressed: () =>
                  ref.read(homeAnalyticsProvider.notifier).refresh(),
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Refresh'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 11,
                ),
              ),
            ),
          ],
        ),
        Expanded(
          child: analyticsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (a) {
              final overdueAmount =
                  (ref.watch(invoiceProvider).asData?.value ?? [])
                      .where(
                        (i) =>
                            !i.isPaid &&
                            !i.isPrivate &&
                            i.dueDate != null &&
                            i.dueDate!.isBefore(DateTime.now()),
                      )
                      .fold<double>(0, (s, i) => s + i.total);

              final peak = a.invoiceCountBars.isEmpty
                  ? 0
                  : a.invoiceCountBars
                        .map((b) => b.value)
                        .reduce((x, y) => x > y ? x : y)
                        .toInt();
              final totalCount = a.invoiceCountBars
                  .fold<double>(0, (s, b) => s + b.value)
                  .toInt();

              return ListView(
                padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
                children: [
                  // KPI row
                  Row(
                    children: [
                      Expanded(
                        child: DesktopKpiCard(
                          label: 'Total revenue',
                          value: '\$${a.totalRevenue.toStringAsFixed(0)}',
                          icon: Icons.attach_money,
                          tint: p.primaryTint,
                          fg: p.primary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DesktopKpiCard(
                          label: 'This month',
                          value: '\$${a.monthRevenue.toStringAsFixed(2)}',
                          icon: Icons.calendar_today_outlined,
                          tint: p.primaryTint,
                          fg: p.primary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DesktopKpiCard(
                          label: 'This year',
                          value: '\$${a.yearRevenue.toStringAsFixed(0)}',
                          icon: Icons.bar_chart,
                          tint: p.purpleBg,
                          fg: p.purple,
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
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Overdue alert + Full charts CTA
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: DesktopPanel(
                            child: Row(
                              children: [
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: p.dangerBg,
                                    borderRadius: BorderRadius.circular(
                                      AppRadii.tile,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.access_time_filled,
                                    color: p.dangerText,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Overdue invoices',
                                        style: AppTypography.title(
                                          p.ink,
                                        ).copyWith(fontSize: 15),
                                      ),
                                      Text(
                                        '${a.overdueCount} · \$${overdueAmount.toStringAsFixed(2)}',
                                        style: AppTypography.bodyMuted(
                                          p.dangerText,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                InkWell(
                                  onTap: () => ref
                                      .read(desktopNavProvider.notifier)
                                      .select(1),
                                  child: Text(
                                    'Review →',
                                    style: AppTypography.body(
                                      p.dangerText,
                                    ).copyWith(fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Material(
                            color: p.primary,
                            borderRadius: BorderRadius.circular(AppRadii.card),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(
                                AppRadii.card,
                              ),
                              onTap: () => ref
                                  .read(desktopNavProvider.notifier)
                                  .select(4),
                              child: Padding(
                                padding: const EdgeInsets.all(18),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 42,
                                      height: 42,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withAlpha(50),
                                        borderRadius: BorderRadius.circular(
                                          AppRadii.tile,
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.show_chart,
                                        color: Colors.white,
                                        size: 22,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Full charts',
                                            style: AppTypography.title(
                                              Colors.white,
                                            ).copyWith(fontSize: 16),
                                          ),
                                          Text(
                                            'Revenue, trends & breakdowns',
                                            style: AppTypography.caption(
                                              Colors.white.withAlpha(210),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(
                                      Icons.chevron_right,
                                      color: Colors.white,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Invoice count line chart
                  DesktopPanel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Invoice Count',
                                    style: AppTypography.title(
                                      p.ink,
                                    ).copyWith(fontSize: 17),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '$totalCount invoices total',
                                    style: AppTypography.bodyMuted(
                                      p.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'PEAK',
                                  style: AppTypography.label(p.textTertiary),
                                ),
                                Text(
                                  '$peak',
                                  style: AppTypography.amount(
                                    p.primary,
                                  ).copyWith(fontSize: 22),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          height: 280,
                          child: CountLineChart(bars: a.invoiceCountBars),
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
}
