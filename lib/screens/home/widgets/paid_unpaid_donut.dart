import 'dart:math' as math;
import 'package:flutter/material.dart';

class PaidUnpaidDonut extends StatelessWidget {
  final double paid;
  final double unpaid;
  const PaidUnpaidDonut({super.key, required this.paid, required this.unpaid});

  @override
  Widget build(BuildContext context) {
    final total = paid + unpaid;
    final cs = Theme.of(context).colorScheme;

    if (total == 0) {
      return Center(
        child: Text(
          'No data',
          style: TextStyle(color: cs.onSurface.withAlpha(100)),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // Donut takes 55% of height, legend gets remaining
        final donutSize = math
            .min(constraints.maxWidth, constraints.maxHeight * 0.58)
            .clamp(80.0, 220.0);

        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ── Donut (centred) ───────────────────────────────────
            Center(
              child: SizedBox(
                width: donutSize,
                height: donutSize,
                child: CustomPaint(
                  painter: _DonutPainter(paid: paid, unpaid: unpaid),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Legend row ────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _Dot(Colors.green),
                const SizedBox(width: 6),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Paid', style: TextStyle(fontSize: 11)),
                    Text(
                      '\$${paid.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    if (total > 0)
                      Text(
                        '${(paid / total * 100).toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.green.withAlpha(200),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 24),
                _Dot(Colors.orange),
                const SizedBox(width: 6),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Unpaid', style: TextStyle(fontSize: 11)),
                    Text(
                      '\$${unpaid.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    if (total > 0)
                      Text(
                        '${(unpaid / total * 100).toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.orange.withAlpha(200),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _Dot extends StatelessWidget {
  final Color color;
  const _Dot(this.color);
  @override
  Widget build(BuildContext context) => Container(
    width: 10,
    height: 10,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
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
    final radius = math.min(size.width, size.height) / 2 - 4;
    final strokeWidth = (radius * 0.38).clamp(10.0, 28.0);
    final rect = Rect.fromCircle(center: center, radius: radius);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    const startAngle = -math.pi / 2;
    final paidSweep = (paid / total) * 2 * math.pi;

    paint.color = Colors.green;
    canvas.drawArc(rect, startAngle, paidSweep, false, paint);

    paint.color = Colors.orange;
    canvas.drawArc(
      rect,
      startAngle + paidSweep,
      2 * math.pi - paidSweep,
      false,
      paint,
    );

    // Centre % label
    final pct = (paid / total * 100).toStringAsFixed(0);
    final tp = TextPainter(
      text: TextSpan(
        children: [
          TextSpan(
            text: '$pct%\n',
            style: TextStyle(
              fontSize: radius * 0.28,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          TextSpan(
            text: 'paid',
            style: TextStyle(
              fontSize: radius * 0.16,
              color: Colors.green.withAlpha(180),
            ),
          ),
        ],
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(_DonutPainter old) =>
      old.paid != paid || old.unpaid != unpaid;
}
