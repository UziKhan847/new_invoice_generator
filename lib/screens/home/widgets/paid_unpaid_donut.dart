import 'dart:math' as math;
import 'package:flutter/material.dart';

class PaidUnpaidDonut extends StatelessWidget {
  final double paid;
  final double unpaid;
  const PaidUnpaidDonut(
      {super.key, required this.paid, required this.unpaid});

  @override
  Widget build(BuildContext context) {
    final total = paid + unpaid;
    final cs = Theme.of(context).colorScheme;

    return Row(
      children: [
        // Donut — takes up half the available width
        Expanded(
          flex: 1,
          child: total == 0
              ? Center(
                  child: Text('No data',
                      style: TextStyle(
                          color: cs.onSurface.withAlpha(100))),
                )
              : CustomPaint(
                  // Explicit size constraint so painter has room
                  painter: _DonutPainter(paid: paid, unpaid: unpaid),
                  child: const SizedBox.expand(),
                ),
        ),
        const SizedBox(width: 24),
        // Legend
        Expanded(
          flex: 1,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _LegendItem(
                color: Colors.green,
                label: 'Paid',
                value: '\$${paid.toStringAsFixed(2)}',
                percent: total == 0
                    ? null
                    : (paid / total * 100).toStringAsFixed(1),
              ),
              const SizedBox(height: 16),
              _LegendItem(
                color: Colors.orange,
                label: 'Unpaid',
                value: '\$${unpaid.toStringAsFixed(2)}',
                percent: total == 0
                    ? null
                    : (unpaid / total * 100).toStringAsFixed(1),
              ),
              const SizedBox(height: 12),
              Text(
                'Total: \$${total.toStringAsFixed(2)}',
                style: TextStyle(
                    fontSize: 11, color: cs.onSurface.withAlpha(140)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final String value;
  final String? percent;

  const _LegendItem({
    required this.color,
    required this.label,
    required this.value,
    this.percent,
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(fontSize: 12)),
            Text(
              value,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 13),
            ),
            if (percent != null)
              Text('$percent%',
                  style: TextStyle(
                      fontSize: 11, color: color.withAlpha(200))),
          ],
        ),
      ],
    );
  }
}

class _DonutPainter extends CustomPainter {
  final double paid;
  final double unpaid;

  _DonutPainter({required this.paid, required this.unpaid});

  @override
  void paint(Canvas canvas, Size size) {
    final total = paid + unpaid;
    if (total == 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    // Radius uses the smaller dimension so it never gets clipped
    final radius = math.min(size.width, size.height) / 2 - 8;
    // Stroke is 25% of radius so it scales with size
    final strokeWidth = (radius * 0.5).clamp(12.0, 32.0);

    final rect = Rect.fromCircle(center: center, radius: radius);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    const startAngle = -math.pi / 2; // top
    final paidSweep = (paid / total) * 2 * math.pi;

    // Paid arc (green)
    paint.color = Colors.green;
    canvas.drawArc(rect, startAngle, paidSweep, false, paint);

    // Unpaid arc (orange)
    paint.color = Colors.orange;
    canvas.drawArc(
        rect, startAngle + paidSweep, 2 * math.pi - paidSweep, false, paint);

    // Centre label
    final pct = (paid / total * 100).toStringAsFixed(0);
    final tp = TextPainter(
      text: TextSpan(
        children: [
          TextSpan(
            text: '$pct%\n',
            style: TextStyle(
              fontSize: radius * 0.3,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          TextSpan(
            text: 'paid',
            style: TextStyle(
              fontSize: radius * 0.18,
              color: Colors.green.withAlpha(180),
            ),
          ),
        ],
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
      canvas,
      center - Offset(tp.width / 2, tp.height / 2),
    );
  }

  @override
  bool shouldRepaint(_DonutPainter old) =>
      old.paid != paid || old.unpaid != unpaid;
}