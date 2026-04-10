import 'package:flutter/material.dart';
import 'package:new_invoice_generator/models/monthly_bar.dart';

class RevenueBarChart extends StatelessWidget {
  final List<MonthlyBar> bars;
  final double labelSize;

  const RevenueBarChart({super.key, required this.bars, this.labelSize = 10});

  @override
  Widget build(BuildContext context) {
    if (bars.isEmpty) {
      return const Center(child: Text('No revenue data yet'));
    }

    final max = bars.map((b) => b.value).fold(0.0, (a, b) => a > b ? a : b);
    final cs = Theme.of(context).colorScheme;
    final isSingle = bars.length == 1;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Reserve: value label slot + gap + month label slot + gap
        final reservedVertical = labelSize * 2 + 10.0;
        final availableBarHeight = constraints.maxHeight - reservedVertical;

        return Column(
          children: [
            // ── Bar area ────────────────────────────────────────────
            SizedBox(
              height: availableBarHeight,
              child: Row(
                crossAxisAlignment: .end,
                mainAxisAlignment: isSingle ? .center : .spaceEvenly,
                children: bars.map((bar) {
                  final frac = max == 0
                      ? 0.0
                      : (bar.value / max).clamp(0.0, 1.0);
                  final barH = ((availableBarHeight - labelSize - 4) * frac)
                      .clamp(0.0, availableBarHeight - labelSize - 4);
                  final isHighest = bar.value == max && max > 0;
                  final barW = isSingle
                      ? 56.0
                      : ((constraints.maxWidth / bars.length) - 6).clamp(
                          6.0,
                          44.0,
                        );

                  return SizedBox(
                    width: barW,
                    child: Column(
                      mainAxisAlignment: .end,
                      children: [
                        // Value label
                        SizedBox(
                          height: labelSize + 2,
                          child: bar.value > 0
                              ? FittedBox(
                                  fit: .scaleDown,
                                  child: Text(
                                    bar.value >= 1000
                                        ? '\$${(bar.value / 1000).toStringAsFixed(1)}k'
                                        : '\$${bar.value.toStringAsFixed(0)}',
                                    style: TextStyle(
                                      fontSize: labelSize,
                                      fontWeight: isHighest ? .bold : .normal,
                                      color: isHighest
                                          ? cs.primary
                                          : cs.onSurface.withAlpha(160),
                                    ),
                                    textAlign: .center,
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),
                        const SizedBox(height: 2),
                        // Bar
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 700),
                          curve: Curves.easeOutCubic,
                          height: barH,
                          decoration: BoxDecoration(
                            color: isHighest
                                ? cs.primary
                                : cs.primary.withAlpha(140),
                            borderRadius: const BorderRadius.vertical(
                              top: .circular(4),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),

            // ── Month labels ────────────────────────────────────────
            const SizedBox(height: 4),
            SizedBox(
              height: labelSize + 2,
              child: Row(
                mainAxisAlignment: isSingle ? .center : .spaceEvenly,
                children: bars.map((bar) {
                  final barW = isSingle
                      ? 56.0
                      : ((constraints.maxWidth / bars.length) - 6).clamp(
                          6.0,
                          44.0,
                        );
                  return SizedBox(
                    width: barW,
                    child: FittedBox(
                      fit: .scaleDown,
                      child: Text(
                        bar.label,
                        textAlign: .center,
                        style: TextStyle(
                          fontSize: labelSize,
                          color: cs.onSurface.withAlpha(160),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        );
      },
    );
  }
}
