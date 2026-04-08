import 'package:flutter/material.dart';
import 'package:new_invoice_generator/models/monthly_bar.dart';

class RevenueBarChart extends StatelessWidget {
  final List<MonthlyBar> bars;
  const RevenueBarChart({super.key, required this.bars});

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
        // Reserve space: value label (~14px) + gap (2px) + month label (14px) + gap (4px)
        const reservedVertical = 34.0;
        final availableBarHeight = constraints.maxHeight - reservedVertical;

        return Column(
          children: [
            // Bar area
            SizedBox(
              height: availableBarHeight,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: isSingle
                    ? MainAxisAlignment.center
                    : MainAxisAlignment.spaceEvenly,
                children: bars.map((bar) {
                  final frac = max == 0
                      ? 0.0
                      : (bar.value / max).clamp(0.0, 1.0);
                  final barH = (availableBarHeight - 16) * frac;
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
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Value label — fixed 14px slot
                        SizedBox(
                          height: 14,
                          child: bar.value > 0
                              ? FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    bar.value >= 1000
                                        ? '\$${(bar.value / 1000).toStringAsFixed(1)}k'
                                        : '\$${bar.value.toStringAsFixed(0)}',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: isHighest
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      color: isHighest
                                          ? cs.primary
                                          : cs.onSurface.withAlpha(140),
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),
                        const SizedBox(height: 2),
                        // Bar — clamped so it can never exceed available space
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 700),
                          curve: Curves.easeOutCubic,
                          height: barH.clamp(0.0, availableBarHeight - 16),
                          decoration: BoxDecoration(
                            color: isHighest
                                ? cs.primary
                                : cs.primary.withAlpha(140),
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(4),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),

            // Month labels — fixed 14px + 4px gap
            const SizedBox(height: 4),
            SizedBox(
              height: 14,
              child: Row(
                mainAxisAlignment: isSingle
                    ? MainAxisAlignment.center
                    : MainAxisAlignment.spaceEvenly,
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
                      fit: BoxFit.scaleDown,
                      child: Text(
                        bar.label,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 9,
                          color: cs.onSurface.withAlpha(140),
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
