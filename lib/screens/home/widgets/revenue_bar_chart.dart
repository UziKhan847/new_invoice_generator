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

    // When there's only 1 bar, cap its width so it doesn't fill the screen
    final isSingle = bars.length == 1;

    return Column(
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: isSingle
                    ? MainAxisAlignment.center
                    : MainAxisAlignment.spaceEvenly,
                children: bars.map((bar) {
                  final frac = max == 0
                      ? 0.02
                      : (bar.value / max).clamp(0.02, 1.0);
                  // Cap single-bar width at 60px, multi-bar fills evenly
                  final barW = isSingle
                      ? 60.0
                      : (constraints.maxWidth / bars.length - 6).clamp(
                          8.0,
                          48.0,
                        );
                  final barH = (constraints.maxHeight - 24) * frac;
                  final isHighest = bar.value == max && max > 0;

                  return SizedBox(
                    width: barW,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Value label
                        Text(
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
                          overflow: TextOverflow.visible,
                        ),
                        const SizedBox(height: 2),
                        // Bar
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 700),
                          curve: Curves.easeOutCubic,
                          height: barH.clamp(4.0, constraints.maxHeight - 24),
                          decoration: BoxDecoration(
                            color: isHighest
                                ? cs.primary
                                : cs.primary.withAlpha(140),
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(5),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ),
        // Month labels row — fixed 16px height, won't overflow
        const SizedBox(height: 4),
        SizedBox(
          height: 14,
          child: Row(
            mainAxisAlignment: isSingle
                ? MainAxisAlignment.center
                : MainAxisAlignment.spaceEvenly,
            children: bars.map((bar) {
              return Text(
                bar.label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 9,
                  color: cs.onSurface.withAlpha(140),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
