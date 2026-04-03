import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:new_invoice_generator/models/home_analytics.dart';
import 'package:new_invoice_generator/models/monthly_bar.dart';
import 'package:new_invoice_generator/providers/home_analytics.dart';
import 'package:new_invoice_generator/providers/invoice.dart';
import 'package:new_invoice_generator/providers/theme.dart';
import 'package:new_invoice_generator/screens/invoice/create.dart';
import 'package:new_invoice_generator/screens/invoice/detail.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _invoiceLimit = 5; // show current month's invoices, load more on tap
  int _chartIndex = 0; // 0 = revenue bar, 1 = paid/unpaid donut, 2 = count line

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final analyticsAsync = ref.watch(homeAnalyticsProvider);
    final invoicesAsync = ref.watch(invoiceProvider);
    final isDark = ref.watch(themeProvider) == ThemeMode.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // ── App Bar ──────────────────────────────────────────────
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
                onPressed: () =>
                    ref.read(homeAnalyticsProvider.notifier).refresh(),
              ),
            ],
          ),

          // ── Body ─────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: analyticsAsync.when(
              loading: () => const SizedBox(
                height: 300,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (analytics) => Column(
                crossAxisAlignment: .start,
                children: [
                  // Stat cards row
                  _StatRow(analytics: analytics),
                  const SizedBox(height: 16),

                  // Chart selector tabs
                  Padding(
                    padding: const .symmetric(horizontal: 16),
                    child: SegmentedButton<int>(
                      segments: const [
                        ButtonSegment(value: 0, label: Text('Revenue')),
                        ButtonSegment(value: 1, label: Text('Paid/Unpaid')),
                        ButtonSegment(value: 2, label: Text('Count')),
                      ],
                      selected: {_chartIndex},
                      onSelectionChanged: (s) =>
                          setState(() => _chartIndex = s.first),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Chart
                  Padding(
                    padding: const .symmetric(horizontal: 16),
                    child: Card(
                      child: Padding(
                        padding: const .all(16),
                        child: SizedBox(
                          height: 200,
                          child: _chartIndex == 0
                              ? _RevenueBarChart(bars: analytics.monthlyBars)
                              : _chartIndex == 1
                              ? _PaidUnpaidDonut(
                                  paid: analytics.paidAmount,
                                  unpaid: analytics.unpaidAmount,
                                )
                              : _CountLineChart(
                                  bars: analytics.invoiceCountBars,
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

          // ── Recent Invoices header ────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const .fromLTRB(16, 0, 16, 8),
              child: Row(
                mainAxisAlignment: .spaceBetween,
                children: [
                  Text(
                    'This Month\'s Invoices',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: .bold,
                    ),
                  ),
                ],
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
              // Filter to current month only
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
                return const SliverToBoxAdapter(
                  child: Padding(
                    padding: .all(32),
                    child: Center(child: Text('No invoices this month yet')),
                  ),
                );
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    if (i == showing.length) {
                      // Load more button
                      if (_invoiceLimit >= thisMonth.length) {
                        return null;
                      }
                      return Padding(
                        padding: const .all(16),
                        child: OutlinedButton(
                          onPressed: () => setState(() => _invoiceLimit += 5),
                          child: const Text('Load More'),
                        ),
                      );
                    }
                    final inv = showing[i];
                    return Padding(
                      padding: const .symmetric(horizontal: 16, vertical: 4),
                      child: Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: inv.isPaid
                                ? Colors.green.withAlpha(30)
                                : cs.primary.withAlpha(30),
                            child: Icon(
                              inv.isPaid ? Icons.check : Icons.receipt_long,
                              color: inv.isPaid ? Colors.green : cs.primary,
                              size: 18,
                            ),
                          ),
                          title: Text(inv.invoiceNumber),
                          subtitle: Text(inv.customerName),
                          trailing: Column(
                            mainAxisAlignment: .center,
                            crossAxisAlignment: .end,
                            children: [
                              Text(
                                '\$${inv.total.toStringAsFixed(2)}',
                                style: const TextStyle(fontWeight: .bold),
                              ),
                              Container(
                                padding: const .symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: inv.isPaid
                                      ? Colors.green.withAlpha(20)
                                      : Colors.orange.withAlpha(20),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  inv.isPaid ? 'Paid' : 'Unpaid',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: inv.isPaid
                                        ? Colors.green
                                        : Colors.orange,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  InvoiceDetailScreen(invoiceId: inv.id!),
                            ),
                          ),
                        ),
                      ),
                    );
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

// ─────────────────────────────────────────────────────────────────────────────
// Stat Row
// ─────────────────────────────────────────────────────────────────────────────
class _StatRow extends StatelessWidget {
  final HomeAnalytics analytics;
  const _StatRow({required this.analytics});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 110,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const .symmetric(horizontal: 16),
        children: [
          _StatChip(
            label: 'This Month',
            value: '\$${analytics.monthRevenue.toStringAsFixed(0)}',
            icon: Icons.calendar_month,
            color: Colors.blue,
          ),
          _StatChip(
            label: 'Outstanding',
            value: '\$${analytics.unpaid.toStringAsFixed(0)}',
            icon: Icons.warning_amber_rounded,
            color: Colors.orange,
          ),
          _StatChip(
            label: 'Total Revenue',
            value: '\$${analytics.totalRevenue.toStringAsFixed(0)}',
            icon: Icons.attach_money,
            color: Colors.green,
          ),
          _StatChip(
            label: 'Overdue',
            value: '${analytics.overdueCount}',
            icon: Icons.access_time_filled,
            color: Colors.red,
          ),
          _StatChip(
            label: 'This Year',
            value: '\$${analytics.yearRevenue.toStringAsFixed(0)}',
            icon: Icons.bar_chart,
            color: Colors.purple,
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatChip({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      margin: const .only(right: 12, top: 4, bottom: 4),
      padding: const .all(14),
      decoration: BoxDecoration(
        color: color.withAlpha(18),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlpha(40)),
      ),
      child: Column(
        crossAxisAlignment: .start,
        children: [
          Icon(icon, color: color, size: 20),
          const Spacer(),
          Text(
            value,
            style: TextStyle(fontWeight: .bold, fontSize: 18, color: color),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: color.withAlpha(180)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Revenue Bar Chart (custom painter — no external chart lib needed)
// ─────────────────────────────────────────────────────────────────────────────
class _RevenueBarChart extends StatelessWidget {
  final List<MonthlyBar> bars;
  const _RevenueBarChart({required this.bars});

  @override
  Widget build(BuildContext context) {
    if (bars.isEmpty) {
      return const Center(child: Text('No data yet'));
    }
    final max = bars.map((b) => b.value).fold(0.0, (a, b) => a > b ? a : b);
    final cs = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: .end,
      children: bars.map((bar) {
        final frac = max == 0 ? 0.0 : bar.value / max;
        return Expanded(
          child: Padding(
            padding: const .symmetric(horizontal: 2),
            child: Column(
              mainAxisAlignment: .end,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeOut,
                  height: 140 * frac,
                  decoration: BoxDecoration(
                    color: cs.primary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  bar.label,
                  style: const TextStyle(fontSize: 9),
                  overflow: TextOverflow.visible,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Paid / Unpaid Donut (custom painter)
// ─────────────────────────────────────────────────────────────────────────────
class _PaidUnpaidDonut extends StatelessWidget {
  final double paid;
  final double unpaid;
  const _PaidUnpaidDonut({required this.paid, required this.unpaid});

  @override
  Widget build(BuildContext context) {
    final total = paid + unpaid;
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: CustomPaint(
            painter: _DonutPainter(
              paid: paid,
              unpaid: unpaid,
              paidColor: Colors.green,
              unpaidColor: Colors.orange,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Column(
          mainAxisAlignment: .center,
          crossAxisAlignment: .start,
          children: [
            _Legend(
              color: Colors.green,
              label: 'Paid',
              value: '\$${paid.toStringAsFixed(0)}',
            ),
            const SizedBox(height: 12),
            _Legend(
              color: Colors.orange,
              label: 'Unpaid',
              value: '\$${unpaid.toStringAsFixed(0)}',
            ),
            const SizedBox(height: 12),
            Text(
              total == 0
                  ? '—'
                  : '${((paid / total) * 100).toStringAsFixed(0)}% collected',
              style: TextStyle(
                fontSize: 12,
                color: cs.onSurface.withAlpha(150),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  final String value;
  const _Legend({
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: .start,
          children: [
            Text(label, style: const TextStyle(fontSize: 12)),
            Text(
              value,
              style: const TextStyle(fontWeight: .bold, fontSize: 14),
            ),
          ],
        ),
      ],
    );
  }
}

class _DonutPainter extends CustomPainter {
  final double paid;
  final double unpaid;
  final Color paidColor;
  final Color unpaidColor;

  _DonutPainter({
    required this.paid,
    required this.unpaid,
    required this.paidColor,
    required this.unpaidColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final total = paid + unpaid;
    if (total == 0) return;
    final rect = Rect.fromCircle(
      center: Offset(size.width / 2, size.height / 2),
      radius: size.height / 2 - 8,
    );
    const strokeWidth = 28.0;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    const start = -1.5707963; // -π/2 (top)
    final paidSweep = (paid / total) * 6.2831853;

    paint.color = paidColor;
    canvas.drawArc(rect, start, paidSweep, false, paint);

    paint.color = unpaidColor;
    canvas.drawArc(
      rect,
      start + paidSweep,
      6.2831853 - paidSweep,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_DonutPainter old) =>
      old.paid != paid || old.unpaid != unpaid;
}

// ─────────────────────────────────────────────────────────────────────────────
// Invoice Count Line Chart (custom painter)
// ─────────────────────────────────────────────────────────────────────────────
class _CountLineChart extends StatelessWidget {
  final List<MonthlyBar> bars;
  const _CountLineChart({required this.bars});

  @override
  Widget build(BuildContext context) {
    if (bars.isEmpty) return const Center(child: Text('No data yet'));
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        Expanded(
          child: CustomPaint(
            painter: _LinePainter(bars: bars, color: cs.primary),
            size: Size.infinite,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: bars
              .map(
                (b) => Expanded(
                  child: Text(
                    b.label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 9),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _LinePainter extends CustomPainter {
  final List<MonthlyBar> bars;
  final Color color;
  _LinePainter({required this.bars, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (bars.length < 2) return;
    final max = bars.map((b) => b.value).fold(0.0, (a, b) => a > b ? a : b);
    if (max == 0) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color.withAlpha(80), color.withAlpha(0)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final points = List.generate(bars.length, (i) {
      final x = (i / (bars.length - 1)) * size.width;
      final y = size.height - (bars[i].value / max) * size.height;
      return Offset(x, y);
    });

    final linePath = Path()..moveTo(points[0].dx, points[0].dy);
    for (int i = 1; i < points.length; i++) {
      linePath.lineTo(points[i].dx, points[i].dy);
    }

    final fillPath = Path()..moveTo(points[0].dx, size.height);
    for (final p in points) {
      fillPath.lineTo(p.dx, p.dy);
    }
    fillPath.lineTo(points.last.dx, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(linePath, paint);

    // Dots
    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    for (final p in points) {
      canvas.drawCircle(p, 3.5, dotPaint);
    }
  }

  @override
  bool shouldRepaint(_LinePainter old) => old.bars != bars;
}
