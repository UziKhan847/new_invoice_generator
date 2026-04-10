import 'package:flutter/material.dart';
import 'package:new_invoice_generator/screens/charts/data.dart';
import 'package:new_invoice_generator/screens/home/widgets/count_line_chart.dart';
import 'package:new_invoice_generator/screens/home/widgets/paid_unpaid_donut.dart';
import 'package:new_invoice_generator/screens/home/widgets/revenue_bar_chart.dart';

class ChartCard extends StatelessWidget {
  final int chartIndex;
  final ChartData data;
  final double labelSize;

  const ChartCard({
    super.key,
    required this.chartIndex,
    required this.data,
    this.labelSize = 12,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 14, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              data.titleFor(chartIndex),
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
            Text(
              data.subtitleFor(chartIndex),
              style: TextStyle(
                  fontSize: 12, color: cs.onSurface.withAlpha(140)),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: KeyedSubtree(
                  key: ValueKey(chartIndex),
                  child: switch (chartIndex) {
                    0 => RevenueBarChart(
                        bars: data.revenueBars,
                        labelSize: labelSize,
                      ),
                    1 => PaidUnpaidDonut(
                        paid: data.paid,
                        unpaid: data.unpaid,
                      ),
                    _ => CountLineChart(
                        bars: data.countBars,
                        labelSize: labelSize,
                      ),
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}