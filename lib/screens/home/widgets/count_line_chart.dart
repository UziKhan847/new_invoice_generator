import 'package:flutter/material.dart';
import 'package:new_invoice_generator/models/monthly_bar.dart';

class CountLineChart extends StatelessWidget {
  final List<MonthlyBar> bars;
  final double labelSize;

  const CountLineChart({super.key, required this.bars, this.labelSize = 10});

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
            padding: const EdgeInsets.only(top: 16, left: 4, right: 4),
            child: isSingle
                ? _SinglePointChart(
                    bar: bars.first,
                    color: cs.primary,
                    labelSize: labelSize,
                  )
                : CustomPaint(
                    painter: _LinePainter(
                      bars: bars,
                      color: cs.primary,
                      labelSize: labelSize,
                    ),
                    size: Size.infinite,
                  ),
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: labelSize + 4,
          child: isSingle
              ? Center(
                  child: Text(
                    bars.first.label,
                    style: TextStyle(
                      fontSize: labelSize,
                      color: cs.onSurface.withAlpha(160),
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
                              fontSize: labelSize,
                              color: cs.onSurface.withAlpha(160),
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

class _SinglePointChart extends StatelessWidget {
  final MonthlyBar bar;
  final Color color;
  final double labelSize;
  const _SinglePointChart({
    required this.bar,
    required this.color,
    required this.labelSize,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withAlpha(30),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${bar.value.toInt()}',
                style: TextStyle(
                  fontSize: labelSize * 2,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'invoice${bar.value.toInt() == 1 ? '' : 's'} this month',
            style: TextStyle(fontSize: labelSize, color: color.withAlpha(180)),
          ),
        ],
      ),
    );
  }
}

class _LinePainter extends CustomPainter {
  final List<MonthlyBar> bars;
  final Color color;
  final double labelSize;

  _LinePainter({
    required this.bars,
    required this.color,
    required this.labelSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final max = bars.map((b) => b.value).fold(0.0, (a, b) => a > b ? a : b);
    if (max == 0) return;

    final topPad = labelSize + 8;
    final chartH = size.height - topPad;

    Offset point(int i) {
      final x = (i / (bars.length - 1)) * size.width;
      final y = topPad + chartH * (1 - bars[i].value / max);
      return Offset(x, y);
    }

    final points = List.generate(bars.length, point);

    // Gradient fill — left edge → points → right edge → close
    // Using 0 and size.width ensures the fill covers the full chart width
    // Shader bounds from topPad to avoid gradient starting above the chart
    final fillPath = Path()
      ..moveTo(0, size.height)
      ..lineTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      fillPath.lineTo(points[i].dx, points[i].dy);
    }
    fillPath
      ..lineTo(size.width, size.height)
      ..close();

    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withAlpha(55), color.withAlpha(0)],
        ).createShader(Rect.fromLTWH(0, topPad, size.width, chartH))
        ..style = PaintingStyle.fill,
    );

    // Line
    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      linePath.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(
      linePath,
      Paint()
        ..color = color
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // Dots + value labels
    for (int i = 0; i < points.length; i++) {
      final p = points[i];
      canvas.drawCircle(p, 6, Paint()..color = color.withAlpha(30));
      canvas.drawCircle(
        p,
        3.5,
        Paint()
          ..color = color
          ..style = PaintingStyle.fill,
      );

      final val = bars[i].value.toInt();
      if (val > 0) {
        final tp = TextPainter(
          text: TextSpan(
            text: '$val',
            style: TextStyle(
              fontSize: labelSize,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(
          canvas,
          Offset(
            (p.dx - tp.width / 2).clamp(0.0, size.width - tp.width),
            (p.dy - tp.height - 6).clamp(0.0, size.height - tp.height),
          ),
        );
      }
    }
  }

  @override
  bool shouldRepaint(_LinePainter old) =>
      old.bars != bars || old.labelSize != labelSize;
}
