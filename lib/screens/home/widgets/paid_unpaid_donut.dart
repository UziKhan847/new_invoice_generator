import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:new_invoice_generator/app_theme.dart';

class PaidUnpaidDonut extends StatelessWidget {
  final double paid;
  final double unpaid;
  const PaidUnpaidDonut({super.key, required this.paid, required this.unpaid});

  @override
  Widget build(BuildContext context) {
    final total = paid + unpaid;
    final p = AppColors.of(context);

    if (total == 0) {
      return Center(
        child: Text('No data', style: AppTypography.bodyMuted(p.textTertiary)),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // Reserve space for the legend cards (~74px) + the gap, then let the
        // donut fill whatever vertical space remains. This guarantees the column
        // never overflows its parent.
        const legendHeight = 74.0;
        const gap = 18.0;
        final available = constraints.maxHeight - legendHeight - gap;
        final donutSize = math
            .min(constraints.maxWidth, available > 0 ? available : 0)
            .clamp(70.0, 200.0)
            .toDouble();

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Donut takes the flexible top area, centered
            Expanded(
              child: Center(
                child: SizedBox(
                  width: donutSize,
                  height: donutSize,
                  child: CustomPaint(
                    painter: _DonutPainter(
                      paid: paid,
                      unpaid: unpaid,
                      paidColor: p.primary,
                      unpaidColor: p.gold,
                      track: p.chartTrack,
                      centerText: p.primary,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: gap),
            Row(
              children: [
                Expanded(
                  child: _LegendCard(
                    label: 'Paid',
                    amount: paid,
                    pct: paid / total * 100,
                    dot: p.primary,
                    bg: p.primaryTint,
                    border: p.primaryPanelBorder,
                    text: p.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _LegendCard(
                    label: 'Unpaid',
                    amount: unpaid,
                    pct: unpaid / total * 100,
                    dot: p.gold,
                    bg: p.warningBg,
                    border: p.warningBorder,
                    text: p.warningText,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _LegendCard extends StatelessWidget {
  final String label;
  final double amount, pct;
  final Color dot, bg, border, text;
  const _LegendCard({
    required this.label,
    required this.amount,
    required this.pct,
    required this.dot,
    required this.bg,
    required this.border,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadii.button),
        border: Border.all(color: border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: AppTypography.caption(text),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '\$${amount.toStringAsFixed(2)}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.title(text).copyWith(fontSize: 16),
          ),
          Text(
            '${pct.toStringAsFixed(1)}%',
            style: AppTypography.numeric(text.withAlpha(190)),
          ),
        ],
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final double paid, unpaid;
  final Color paidColor, unpaidColor, track, centerText;
  _DonutPainter({
    required this.paid,
    required this.unpaid,
    required this.paidColor,
    required this.unpaidColor,
    required this.track,
    required this.centerText,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final total = paid + unpaid;
    if (total == 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 4;
    final strokeWidth = (radius * 0.30).clamp(12.0, 30.0);
    final rect = Rect.fromCircle(center: center, radius: radius);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Track
    paint.color = track;
    canvas.drawArc(rect, 0, 2 * math.pi, false, paint);

    const startAngle = -math.pi / 2;
    final paidSweep = (paid / total) * 2 * math.pi;

    // Unpaid first (under), then paid on top
    paint.color = unpaidColor;
    canvas.drawArc(
      rect,
      startAngle + paidSweep,
      2 * math.pi - paidSweep,
      false,
      paint,
    );

    paint.color = paidColor;
    canvas.drawArc(rect, startAngle, paidSweep, false, paint);

    final pct = (paid / total * 100).toStringAsFixed(0);
    final tp = TextPainter(
      text: TextSpan(
        children: [
          TextSpan(
            text: '$pct%\n',
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: radius * 0.34,
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
              color: centerText,
            ),
          ),
          TextSpan(
            text: 'paid',
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: radius * 0.15,
              fontWeight: FontWeight.w600,
              color: centerText.withAlpha(170),
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
