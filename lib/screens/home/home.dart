import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:new_invoice_generator/app_theme.dart';
import 'package:new_invoice_generator/models/home_analytics.dart';
import 'package:new_invoice_generator/models/monthly_bar.dart';
import 'package:new_invoice_generator/providers/invoice.dart';
import 'package:new_invoice_generator/providers/theme.dart';
import 'package:new_invoice_generator/screens/home/widgets/count_line_chart.dart';
import 'package:new_invoice_generator/screens/home/widgets/invoice_tile.dart';
import 'package:new_invoice_generator/screens/home/widgets/paid_unpaid_donut.dart';
import 'package:new_invoice_generator/screens/home/widgets/revenue_bar_chart.dart';
import 'package:new_invoice_generator/screens/home/widgets/stat_row.dart';
import 'package:new_invoice_generator/screens/home/widgets/ui_kit.dart';
import 'package:new_invoice_generator/screens/invoice/create/create.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _invoiceLimit = 5;
  int _chartIndex = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final analyticsAsync = ref.watch(homeAnalyticsProvider);
    final invoicesAsync = ref.watch(invoiceProvider);
    final themeMode = ref.watch(themeProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── App bar ─────────────────────────────────────────────
          SliverAppBar(
            floating: true,
            snap: true,
            title: const Text('Overview'),
            actions: [
              IconButton(
                tooltip: 'Theme: ${themeMode.label} (tap to cycle)',
                icon: Icon(themeMode.icon),
                onPressed: () => ref.read(themeProvider.notifier).cycle(),
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh',
                onPressed: () =>
                    ref.read(homeAnalyticsProvider.notifier).refresh(),
              ),
            ],
          ),

          // ── Stats + charts ───────────────────────────────────────
          SliverToBoxAdapter(
            child: analyticsAsync.when(
              loading: () => const SizedBox(
                height: 300,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (analytics) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  StatRow(analytics: analytics),
                  const SizedBox(height: 20),

                  // Chart tab selector
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SegmentedButton<int>(
                      segments: const [
                        ButtonSegment(value: 0, label: Text('Revenue')),
                        ButtonSegment(value: 1, label: Text('Paid / Unpaid')),
                        ButtonSegment(value: 2, label: Text('Count')),
                      ],
                      selected: {_chartIndex},
                      onSelectionChanged: (s) =>
                          setState(() => _chartIndex = s.first),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Chart card with header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: AppCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _ChartHeader(
                            index: _chartIndex,
                            analytics: analytics,
                          ),
                          const SizedBox(height: 18),
                          SizedBox(
                            height: 250,
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              child: KeyedSubtree(
                                key: ValueKey(_chartIndex),
                                child: _chartIndex == 0
                                    ? RevenueBarChart(
                                        bars: analytics.monthlyBars,
                                      )
                                    : _chartIndex == 1
                                    ? Builder(
                                        builder: (ctx) {
                                          final invs =
                                              (ref
                                                          .watch(
                                                            invoiceProvider,
                                                          )
                                                          .asData
                                                          ?.value ??
                                                      [])
                                                  .where((i) => !i.isPrivate)
                                                  .toList();
                                          final pd = invs.fold(
                                            0.0,
                                            (s, i) =>
                                                s + (i.isPaid ? i.total : 0.0),
                                          );
                                          final u = invs.fold(
                                            0.0,
                                            (s, i) =>
                                                s + (i.isPaid ? 0.0 : i.total),
                                          );
                                          return PaidUnpaidDonut(
                                            paid: pd,
                                            unpaid: u,
                                          );
                                        },
                                      )
                                    : CountLineChart(
                                        bars: analytics.invoiceCountBars,
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // ── This month's invoices header ─────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                "This Month's Invoices",
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // ── Invoice list ─────────────────────────────────────────
          invoicesAsync.when(
            loading: () => const SliverToBoxAdapter(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) =>
                SliverToBoxAdapter(child: Center(child: Text('Error: $e'))),
            data: (allInvoices) {
              final now = DateTime.now();
              final thisMonth = allInvoices
                  .where(
                    (i) =>
                        i.issueDate.month == now.month &&
                        i.issueDate.year == now.year,
                  )
                  .toList();
              final showing = thisMonth.take(_invoiceLimit).toList();

              if (thisMonth.isEmpty) {
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(
                      child: Text(
                        'No invoices this month yet',
                        style: TextStyle(color: cs.onSurface.withAlpha(120)),
                      ),
                    ),
                  ),
                );
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    if (i == showing.length) {
                      if (_invoiceLimit >= thisMonth.length) {
                        return null;
                      }
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                        child: OutlinedButton(
                          onPressed: () => setState(() => _invoiceLimit += 5),
                          child: const Text('Load More'),
                        ),
                      );
                    }
                    return HomeInvoiceTile(invoice: showing[i]);
                  },
                  childCount:
                      showing.length +
                      (_invoiceLimit < thisMonth.length ? 1 : 0),
                ),
              );
            },
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CreateInvoiceScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('New Invoice'),
      ),
    );
  }
}

/// Header row above the chart: title + subtitle on the left, the highlighted
/// period + value on the right (matches the design mockups).
class _ChartHeader extends StatelessWidget {
  final int index;
  final HomeAnalytics analytics;
  const _ChartHeader({required this.index, required this.analytics});

  @override
  Widget build(BuildContext context) {
    final p = AppColors.of(context);

    String title, subtitle, rightLabel, rightValue;
    Color rightValueColor = p.primary;

    if (index == 0) {
      final List<MonthlyBar> bars = analytics.monthlyBars;
      MonthlyBar? maxBar;
      for (final b in bars) {
        if (maxBar == null || b.value >= maxBar.value) maxBar = b;
      }
      title = 'Monthly Revenue';
      subtitle = 'Total paid \$${analytics.totalRevenue.toStringAsFixed(2)}';
      rightLabel = maxBar?.label.replaceAll('\n', ' ') ?? '';
      rightValue = maxBar == null ? '' : '\$${maxBar.value.toStringAsFixed(0)}';
    } else if (index == 1) {
      title = 'Paid vs Unpaid';
      final collected = analytics.totalRevenue == 0
          ? 0.0
          : analytics.totalRevenue /
                (analytics.totalRevenue + analytics.unpaid) *
                100;
      subtitle =
          '${collected.toStringAsFixed(1)}% collected · \$${analytics.unpaid.toStringAsFixed(2)} outstanding';
      rightLabel = '';
      rightValue = '';
    } else {
      final List<MonthlyBar> bars = analytics.invoiceCountBars;
      final total = bars.fold<double>(0, (s, b) => s + b.value);
      double peak = 0;
      for (final b in bars) {
        if (b.value > peak) peak = b.value;
      }
      title = 'Invoice Count';
      subtitle = '${total.toInt()} invoices total';
      rightLabel = 'PEAK';
      rightValue = '${peak.toInt()}';
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.title(p.ink).copyWith(fontSize: 17),
              ),
              const SizedBox(height: 2),
              Text(subtitle, style: AppTypography.bodyMuted(p.textSecondary)),
            ],
          ),
        ),
        if (rightValue.isNotEmpty) ...[
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (rightLabel.isNotEmpty)
                Text(rightLabel, style: AppTypography.label(p.textTertiary)),
              Text(
                rightValue,
                style: AppTypography.amount(
                  rightValueColor,
                ).copyWith(fontSize: 22),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
