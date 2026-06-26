import 'package:flutter/material.dart';
import 'package:new_invoice_generator/app_theme.dart';
import 'package:new_invoice_generator/models/monthly_bar.dart';

class CountLineChart extends StatelessWidget {
  final List<MonthlyBar> bars;
  final double labelSize;

  const CountLineChart({super.key, required this.bars, this.labelSize = 10});

  static const double _pointSpacing = 54; // px per data point
  static const double _yAxisWidth = 38;

  @override
  Widget build(BuildContext context) {
    final p = AppColors.of(context);
    if (bars.isEmpty || bars.every((b) => b.value == 0)) {
      return Center(
        child: Text(
          'No invoice count data yet',
          style: AppTypography.bodyMuted(p.textTertiary),
        ),
      );
    }

    final isSingle = bars.length == 1;
    if (isSingle) {
      return _SinglePointChart(
        bar: bars.first,
        color: p.primary,
        labelSize: labelSize,
      );
    }

    final maxVal = bars.map((b) => b.value).fold(0.0, (a, b) => a > b ? a : b);
    final axisMax = maxVal <= 0 ? 1.0 : maxVal.ceilToDouble();

    return LayoutBuilder(
      builder: (context, constraints) {
        final chartHeight = constraints.maxHeight;
        const labelStrip = 22.0;
        final plotHeight = chartHeight - labelStrip;
        // Total plot width: enough for all points, but at least fill the view.
        final plotWidth = (bars.length * _pointSpacing).clamp(
          constraints.maxWidth - _yAxisWidth,
          5000.0,
        );

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Pinned Y axis
            SizedBox(
              width: _yAxisWidth,
              height: plotHeight,
              child: _CountYAxis(
                axisMax: axisMax,
                height: plotHeight,
                palette: p,
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: SizedBox(
                  width: plotWidth,
                  height: chartHeight,
                  child: Column(
                    children: [
                      SizedBox(
                        height: plotHeight,
                        child: CustomPaint(
                          painter: _LinePainter(
                            bars: bars,
                            color: p.primary,
                            axisMax: axisMax,
                            gridline: p.gridline,
                            labelColor: p.primary,
                            labelSize: labelSize,
                          ),
                          size: Size(plotWidth, plotHeight),
                        ),
                      ),
                      SizedBox(
                        height: labelStrip,
                        child: Row(
                          children: bars
                              .map(
                                (b) => SizedBox(
                                  width: plotWidth / bars.length,
                                  child: Text(
                                    b.label,
                                    textAlign: TextAlign.center,
                                    style: AppTypography.numeric(
                                      p.textTertiary,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _CountYAxis extends StatelessWidget {
  final double axisMax, height;
  final AppPalette palette;
  const _CountYAxis({
    required this.axisMax,
    required this.height,
    required this.palette,
  });
  @override
  Widget build(BuildContext context) {
    const divisions = 4;
    return SizedBox(
      height: height,
      child: Stack(
        children: List.generate(divisions + 1, (i) {
          final val = axisMax * (divisions - i) / divisions;
          final top = (height / divisions) * i - 6;
          return Positioned(
            top: top.clamp(0.0, height),
            right: 6,
            child: Text(
              val.toStringAsFixed(0),
              style: AppTypography.numeric(palette.textTertiary),
            ),
          );
        }),
      ),
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
  final double axisMax;
  final Color gridline;
  final Color labelColor;
  final double labelSize;

  _LinePainter({
    required this.bars,
    required this.color,
    required this.axisMax,
    required this.gridline,
    required this.labelColor,
    required this.labelSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final max = axisMax <= 0 ? 1.0 : axisMax;

    final topPad = labelSize + 10;
    final chartH = size.height - topPad;

    // Gridlines (4 divisions)
    const divisions = 4;
    final gridPaint = Paint()
      ..color = gridline
      ..strokeWidth = 1;
    for (int i = 0; i <= divisions; i++) {
      final y = topPad + chartH * i / divisions;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Inset points so first/last dots aren't on the edges
    final inset = size.width / bars.length / 2;
    final usableW = size.width - inset * 2;

    Offset point(int i) {
      final x = inset + (i / (bars.length - 1)) * usableW;
      final y = topPad + chartH * (1 - bars[i].value / max);
      return Offset(x, y);
    }

    final points = List.generate(bars.length, point);

    // Gradient fill — left edge → points → right edge → close
    // Using 0 and size.width ensures the fill covers the full chart width
    // Shader bounds from topPad to avoid gradient starting above the chart
    final fillPath = Path()
      ..moveTo(points.first.dx, size.height)
      ..lineTo(
        points.first.dy == 0 ? points.first.dx : points.first.dx,
        points.first.dy,
      );
    for (int i = 1; i < points.length; i++) {
      fillPath.lineTo(points[i].dx, points[i].dy);
    }
    fillPath
      ..lineTo(points.last.dx, size.height)
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
      old.bars != bars || old.axisMax != axisMax || old.color != color;
}
