import 'package:flutter/material.dart';
import 'package:new_invoice_generator/app_theme.dart';
import 'package:new_invoice_generator/models/monthly_bar.dart';
import 'package:new_invoice_generator/screens/charts/data.dart';
import 'package:new_invoice_generator/screens/home/widgets/count_line_chart.dart';
import 'package:new_invoice_generator/screens/home/widgets/paid_unpaid_donut.dart';
import 'package:new_invoice_generator/screens/home/widgets/revenue_bar_chart.dart';

class ChartCard extends StatefulWidget {
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
  State<ChartCard> createState() => _ChartCardState();
}

class _ChartCardState extends State<ChartCard> {
  // Selected revenue bar. null = default (highest-earning period).
  int? _selectedBar;

  @override
  void didUpdateWidget(ChartCard old) {
    super.didUpdateWidget(old);
    // Reset selection when the chart type or underlying data changes.
    if (old.chartIndex != widget.chartIndex || old.data != widget.data) {
      _selectedBar = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = AppColors.of(context);
    final data = widget.data;
    final chartIndex = widget.chartIndex;

    // For revenue: resolve the active bar (selection or highest) for the header.
    String? rightLabel;
    String? rightValue;
    if (chartIndex == 0) {
      final bars = data.revenueBars;
      int defaultIdx = -1;
      double maxVal = -1;
      for (var i = 0; i < bars.length; i++) {
        if (bars[i].value > maxVal) {
          maxVal = bars[i].value;
          defaultIdx = i;
        }
      }
      final activeIdx =
          (_selectedBar != null &&
              _selectedBar! >= 0 &&
              _selectedBar! < bars.length)
          ? _selectedBar!
          : defaultIdx;
      final MonthlyBar? activeBar = activeIdx >= 0 && activeIdx < bars.length
          ? bars[activeIdx]
          : null;
      if (activeBar != null) {
        rightLabel = activeBar.label.replaceAll('\n', ' ');
        rightValue = '\$${activeBar.value.toStringAsFixed(0)}';
      }
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data.titleFor(chartIndex),
                        style: AppTypography.title(
                          p.ink,
                        ).copyWith(fontSize: 17),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        data.subtitleFor(chartIndex),
                        style: AppTypography.bodyMuted(p.textSecondary),
                      ),
                    ],
                  ),
                ),
                if (rightValue != null) ...[
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (rightLabel != null)
                        Text(
                          rightLabel,
                          style: AppTypography.label(p.textTertiary),
                        ),
                      Text(
                        rightValue,
                        style: AppTypography.amount(
                          p.primary,
                        ).copyWith(fontSize: 22),
                      ),
                    ],
                  ),
                ],
              ],
            ),
            const SizedBox(height: 14),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: KeyedSubtree(
                  key: ValueKey(chartIndex),
                  child: switch (chartIndex) {
                    0 => RevenueBarChart(
                      bars: data.revenueBars,
                      selectedIndex: _selectedBar,
                      onBarTap: (i) => setState(() => _selectedBar = i),
                    ),
                    1 => PaidUnpaidDonut(paid: data.paid, unpaid: data.unpaid),
                    _ => CountLineChart(
                      bars: data.countBars,
                      labelSize: widget.labelSize,
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
