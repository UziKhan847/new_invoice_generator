import 'package:flutter/material.dart';
import 'package:new_invoice_generator/models/monthly_bar.dart';

class CountLineChart extends StatelessWidget {
  final List<MonthlyBar> bars;
  const CountLineChart({super.key, required this.bars});

  @override
  Widget build(BuildContext context) {
    if (bars.isEmpty || bars.every((b) => b.value == 0)) {
      return const Center(child: Text('No invoice count data yet'));
    }

    final cs = Theme.of(context).colorScheme;
    final isSingle = bars.length == 1;

    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 16, left: 8, right: 8),
            child: isSingle
                // Single data point — draw a centred dot with value
                ? _SinglePointChart(bar: bars.first, color: cs.primary)
                : CustomPaint(
                    painter: _LinePainter(bars: bars, color: cs.primary),
                    size: Size.infinite,
                  ),
          ),
        ),
        const SizedBox(height: 4),
        // Labels
        SizedBox(
          height: 14,
          child: isSingle
              ? Center(
                  child: Text(
                    bars.first.label,
                    style: TextStyle(
                      fontSize: 9,
                      color: cs.onSurface.withAlpha(140),
                    ),
                  ),
                )
              : Row(
                  children: bars
                      .map(
                        (b) => Expanded(
                          child: Text(
                            b.label,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 9,
                              color: cs.onSurface.withAlpha(140),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
        ),
      ],
    );
  }
}

/// Shown when there's only 1 month of data — a simple centred dot + label
class _SinglePointChart extends StatelessWidget {
  final MonthlyBar bar;
  final Color color;
  const _SinglePointChart({required this.bar, required this.color});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withAlpha(30),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${bar.value.toInt()}',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'invoice${bar.value.toInt() == 1 ? '' : 's'} this month',
            style: TextStyle(fontSize: 11, color: color.withAlpha(180)),
          ),
        ],
      ),
    );
  }
}

class _LinePainter extends CustomPainter {
  final List<MonthlyBar> bars;
  final Color color;

  _LinePainter({required this.bars, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final max = bars.map((b) => b.value).fold(0.0, (a, b) => a > b ? a : b);
    if (max == 0) return;

    const topPad = 18.0;
    final chartH = size.height - topPad;

    Offset point(int i) {
      final x = (i / (bars.length - 1)) * size.width;
      final y = topPad + chartH * (1 - bars[i].value / max);
      return Offset(x, y);
    }

    final points = List.generate(bars.length, point);

    // Gradient fill
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color.withAlpha(70), color.withAlpha(0)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final fillPath = Path()..moveTo(points.first.dx, size.height);
    for (final p in points) {
      fillPath.lineTo(p.dx, p.dy);
    }
    fillPath.lineTo(points.last.dx, size.height);
    fillPath.close();
    canvas.drawPath(fillPath, fillPaint);

    // Line
    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      linePath.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(linePath, linePaint);

    // Dots + value labels
    final dotFill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final dotBg = Paint()
      ..color = color.withAlpha(30)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < points.length; i++) {
      final p = points[i];
      canvas.drawCircle(p, 6, dotBg);
      canvas.drawCircle(p, 3.5, dotFill);

      final val = bars[i].value.toInt();
      if (val > 0) {
        final tp = TextPainter(
          text: TextSpan(
            text: '$val',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        final lx = (p.dx - tp.width / 2).clamp(0.0, size.width - tp.width);
        final ly = (p.dy - tp.height - 8).clamp(0.0, size.height - tp.height);
        tp.paint(canvas, Offset(lx, ly));
      }
    }
  }

  @override
  bool shouldRepaint(_LinePainter old) => old.bars != bars;
}
