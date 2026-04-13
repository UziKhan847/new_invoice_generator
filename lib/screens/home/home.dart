import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:new_invoice_generator/providers/home_analytics.dart';
import 'package:new_invoice_generator/providers/invoice.dart';
import 'package:new_invoice_generator/providers/theme.dart';
import 'package:new_invoice_generator/screens/home/widgets/count_line_chart.dart';
import 'package:new_invoice_generator/screens/home/widgets/invoice_tile.dart';
import 'package:new_invoice_generator/screens/home/widgets/paid_unpaid_donut.dart';
import 'package:new_invoice_generator/screens/home/widgets/revenue_bar_chart.dart';
import 'package:new_invoice_generator/screens/home/widgets/stat_row.dart';
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
    final isDark = ref.watch(themeProvider) == ThemeMode.dark;

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
                tooltip: isDark ? 'Light mode' : 'Dark mode',
                icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
                onPressed: () => ref.read(themeProvider.notifier).toggle(),
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

                  // Chart card — fixed height so painters have a real size
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
                        child: SizedBox(
                          height: 200,
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: KeyedSubtree(
                              key: ValueKey(_chartIndex),
                              child: _chartIndex == 0
                                  ? RevenueBarChart(bars: analytics.monthlyBars)
                                  : _chartIndex == 1
                                  ? PaidUnpaidDonut(
                                      paid: analytics.paidAmount,
                                      unpaid: analytics.unpaidAmount,
                                    )
                                  : CountLineChart(
                                      bars: analytics.invoiceCountBars,
                                    ),
                            ),
                          ),
                        ),
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
