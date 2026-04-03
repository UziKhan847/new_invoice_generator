import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:new_invoice_generator/models/monthly_bar.dart';
import 'package:new_invoice_generator/providers/customer.dart';
import 'package:new_invoice_generator/providers/employee.dart';
import 'package:new_invoice_generator/providers/home_analytics.dart';

class ChartsScreen extends ConsumerStatefulWidget {
  const ChartsScreen({super.key});

  @override
  ConsumerState<ChartsScreen> createState() => _ChartsScreenState();
}

class _ChartsScreenState extends ConsumerState<ChartsScreen> {
  int _chartIndex = 0;
  // Filters
  int? _filterYear;
  String? _filterCustomerId;
  String? _filterSenderId;

  @override
  Widget build(BuildContext context) {
    final analyticsAsync = ref.watch(homeAnalyticsProvider);
    final customersAsync = ref.watch(customerProvider);
    final employeesAsync = ref.watch(employeeProvider);
    final now = DateTime.now();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Charts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(homeAnalyticsProvider.notifier).refresh(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter bar
          Padding(
            padding: const .fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                // Year
                Expanded(
                  child: DropdownButtonFormField<int>(
                    initialValue: _filterYear,
                    isDense: true,
                    decoration: const InputDecoration(
                      labelText: 'Year',
                      isDense: true,
                      contentPadding: .symmetric(horizontal: 12, vertical: 10),
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('All years'),
                      ),
                      ...List.generate(
                        5,
                        (i) => DropdownMenuItem(
                          value: now.year - i,
                          child: Text('${now.year - i}'),
                        ),
                      ),
                    ],
                    onChanged: (v) {
                      setState(() => _filterYear = v);
                      ref.read(homeAnalyticsProvider.notifier).refresh();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                // Customer
                Expanded(
                  child: customersAsync.when(
                    loading: () => const SizedBox.shrink(),
                    error: (_, _) => const SizedBox.shrink(),
                    data: (customers) => DropdownButtonFormField<String>(
                      initialValue: _filterCustomerId,
                      isDense: true,
                      decoration: const InputDecoration(
                        labelText: 'Customer',
                        isDense: true,
                        contentPadding: .symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('All')),
                        ...customers.map(
                          (c) => DropdownMenuItem(
                            value: c.id,
                            child: Text(
                              c.name,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                      onChanged: (v) => setState(() => _filterCustomerId = v),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Sender
                Expanded(
                  child: employeesAsync.when(
                    loading: () => const SizedBox.shrink(),
                    error: (_, _) => const SizedBox.shrink(),
                    data: (employees) => employees.isEmpty
                        ? const SizedBox.shrink()
                        : DropdownButtonFormField<String>(
                            initialValue: _filterSenderId,
                            isDense: true,
                            decoration: const InputDecoration(
                              labelText: 'Sender',
                              isDense: true,
                              contentPadding: .symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                            ),
                            items: [
                              const DropdownMenuItem(
                                value: null,
                                child: Text('All'),
                              ),
                              ...employees.map(
                                (e) => DropdownMenuItem(
                                  value: e.id,
                                  child: Text(
                                    e.name,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ],
                            onChanged: (v) =>
                                setState(() => _filterSenderId = v),
                          ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Chart tabs
          Padding(
            padding: const .symmetric(horizontal: 16),
            child: SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 0, label: Text('Revenue')),
                ButtonSegment(value: 1, label: Text('Paid/Unpaid')),
                ButtonSegment(value: 2, label: Text('Count')),
              ],
              selected: {_chartIndex},
              onSelectionChanged: (s) => setState(() => _chartIndex = s.first),
            ),
          ),
          const SizedBox(height: 16),

          // Chart
          Expanded(
            child: analyticsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (analytics) {
                // Apply year filter to bars client-side
                var bars = analytics.monthlyBars;
                var countBars = analytics.invoiceCountBars;

                return Padding(
                  padding: const .symmetric(horizontal: 16),
                  child: Card(
                    child: Padding(
                      padding: const .all(20),
                      child: Column(
                        crossAxisAlignment: .start,
                        children: [
                          Text(
                            _chartTitle(_chartIndex),
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: .bold),
                          ),
                          const SizedBox(height: 16),
                          Expanded(
                            child: _chartIndex == 0
                                ? _RevenueBarChart(bars: bars)
                                : _chartIndex == 1
                                ? _PaidUnpaidDonut(
                                    paid: analytics.paidAmount,
                                    unpaid: analytics.unpaidAmount,
                                  )
                                : _CountLineChart(bars: countBars),
                          ),
                          // Legend for bar chart
                          if (_chartIndex == 0 && bars.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            _BarLegend(bars: bars),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  String _chartTitle(int i) {
    switch (i) {
      case 0:
        return 'Monthly Revenue';
      case 1:
        return 'Paid vs Unpaid';
      case 2:
        return 'Invoice Count by Month';
      default:
        return '';
    }
  }
}

// ── Bar chart ─────────────────────────────────────────────────────────────────
class _RevenueBarChart extends StatelessWidget {
  final List<MonthlyBar> bars;
  const _RevenueBarChart({required this.bars});

  @override
  Widget build(BuildContext context) {
    if (bars.isEmpty) return const Center(child: Text('No data yet'));
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
                if (bar.value > 0)
                  Text(
                    '\$${bar.value.toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 8),
                    overflow: TextOverflow.visible,
                  ),
                const SizedBox(height: 2),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeOut,
                  height: 160 * frac,
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

class _BarLegend extends StatelessWidget {
  final List<MonthlyBar> bars;
  const _BarLegend({required this.bars});

  @override
  Widget build(BuildContext context) {
    final total = bars.fold(0.0, (s, b) => s + b.value);
    return Text(
      'Total: \$${total.toStringAsFixed(2)}',
      style: TextStyle(
        fontSize: 12,
        color: Theme.of(context).colorScheme.onSurface.withAlpha(140),
      ),
    );
  }
}

// ── Donut ─────────────────────────────────────────────────────────────────────
class _PaidUnpaidDonut extends StatelessWidget {
  final double paid;
  final double unpaid;
  const _PaidUnpaidDonut({required this.paid, required this.unpaid});

  @override
  Widget build(BuildContext context) {
    final total = paid + unpaid;
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
        const SizedBox(width: 24),
        Column(
          mainAxisAlignment: .center,
          crossAxisAlignment: .start,
          children: [
            _Legend(
              color: Colors.green,
              label: 'Paid',
              value: '\$${paid.toStringAsFixed(2)}',
            ),
            const SizedBox(height: 16),
            _Legend(
              color: Colors.orange,
              label: 'Unpaid',
              value: '\$${unpaid.toStringAsFixed(2)}',
            ),
            const SizedBox(height: 16),
            Text(
              total == 0
                  ? 'No data'
                  : '${((paid / total) * 100).toStringAsFixed(1)}% collected',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface.withAlpha(150),
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
  final double paid, unpaid;
  final Color paidColor, unpaidColor;
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
    const strokeWidth = 32.0;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;
    const start = -1.5707963;
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

// ── Line chart ────────────────────────────────────────────────────────────────
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

    final linePaint = Paint()
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

    final points = List.generate(
      bars.length,
      (i) => Offset(
        (i / (bars.length - 1)) * size.width,
        size.height - (bars[i].value / max) * (size.height - 10),
      ),
    );

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
    canvas.drawPath(linePath, linePaint);

    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    for (final p in points) {
      canvas.drawCircle(p, 4, dotPaint);
    }
  }

  @override
  bool shouldRepaint(_LinePainter old) => old.bars != bars;
}
