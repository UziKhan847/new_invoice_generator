import 'package:flutter/material.dart';
import 'package:new_invoice_generator/app_theme.dart';
import 'package:new_invoice_generator/models/monthly_bar.dart';

/// Horizontally-scrollable revenue bar chart. Bars have a fixed width so on a
/// phone you see ~7 at a time and scroll for the rest (matches the design).
/// A fixed Y-axis (with gridlines) stays pinned on the left.
class RevenueBarChart extends StatelessWidget {
  final List<MonthlyBar> bars;
  final void Function(int index)? onBarTap;
  final int? selectedIndex;

  const RevenueBarChart({
    super.key,
    required this.bars,
    this.onBarTap,
    this.selectedIndex,
  });

  static const double _barWidth = 26;
  static const double _barGap = 18;
  static const double _yAxisWidth = 38;

  @override
  Widget build(BuildContext context) {
    final p = AppColors.of(context);
    if (bars.isEmpty) {
      return Center(
          child: Text('No revenue data yet',
              style: AppTypography.bodyMuted(p.textTertiary)));
    }

    final maxVal = bars.map((b) => b.value).fold(0.0, (a, b) => a > b ? a : b);
    // Round the axis max up to a "nice" number
    final axisMax = _niceMax(maxVal);
    // The default selected bar = highest (or the explicit selection)
    final selected = selectedIndex ??
        bars.indexWhere((b) => b.value == maxVal).clamp(0, bars.length - 1);

    return LayoutBuilder(builder: (context, constraints) {
      final chartHeight = constraints.maxHeight;
      const labelStrip = 22.0; // month labels under bars
      const valueStrip = 16.0; // value label above the tallest
      final plotHeight = chartHeight - labelStrip - valueStrip;

      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Fixed Y axis ────────────────────────────────────────
          SizedBox(
            width: _yAxisWidth,
            child: Padding(
              padding: const EdgeInsets.only(top: valueStrip),
              child: _YAxis(axisMax: axisMax, height: plotHeight, palette: p),
            ),
          ),
          // ── Scrollable bars ─────────────────────────────────────
          Expanded(
            child: Stack(
              children: [
                // Gridlines behind the bars
                Padding(
                  padding: const EdgeInsets.only(top: valueStrip),
                  child: _Gridlines(height: plotHeight, palette: p),
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: List.generate(bars.length, (i) {
                      final bar = bars[i];
                      final frac =
                          axisMax == 0 ? 0.0 : (bar.value / axisMax).clamp(0.0, 1.0);
                      final barH = plotHeight * frac;
                      final isSel = i == selected;

                      return Padding(
                        padding: EdgeInsets.only(
                            right: _barGap,
                            left: i == 0 ? 4 : 0),
                        child: GestureDetector(
                          onTap: onBarTap == null ? null : () => onBarTap!(i),
                          behavior: HitTestBehavior.opaque,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              // Value label (only on selected)
                              SizedBox(
                                height: valueStrip,
                                child: isSel && bar.value > 0
                                    ? _ValueChip(
                                        text: _money(bar.value), palette: p)
                                    : null,
                              ),
                              // Bar
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 500),
                                curve: Curves.easeOutCubic,
                                width: _barWidth,
                                height: barH < 2 ? 2 : barH,
                                decoration: BoxDecoration(
                                  color: isSel ? p.primary : p.barMuted,
                                  borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(5)),
                                ),
                              ),
                              const SizedBox(height: 6),
                              // Month label
                              SizedBox(
                                height: labelStrip - 6,
                                width: _barWidth + 8,
                                child: Text(
                                  bar.label,
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  style: AppTypography.numeric(
                                      isSel ? p.ink : p.textTertiary),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    });
  }

  static String _money(double v) => v >= 1000
      ? '\$${(v / 1000).toStringAsFixed(1)}k'
      : '\$${v.toStringAsFixed(0)}';

  static double _niceMax(double v) {
    if (v <= 0) return 100;
    final mag = v.toString().split('.').first.length;
    final step = [1, 2, 5, 10].map((s) => s * (mag <= 3 ? 100 : 1000)).toList();
    for (final s in step) {
      if (v <= s * 4) return (v / s).ceilToDouble() * s;
    }
    return (v / 1000).ceilToDouble() * 1000;
  }
}

class _ValueChip extends StatelessWidget {
  final String text;
  final AppPalette palette;
  const _ValueChip({required this.text, required this.palette});
  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
        decoration: BoxDecoration(
          color: palette.primaryTint,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(text,
            style: AppTypography.numeric(palette.primary)
                .copyWith(fontWeight: FontWeight.w800, fontSize: 10)),
      ),
    );
  }
}

class _YAxis extends StatelessWidget {
  final double axisMax, height;
  final AppPalette palette;
  const _YAxis(
      {required this.axisMax, required this.height, required this.palette});
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
              val >= 1000
                  ? '\$${(val / 1000).toStringAsFixed(0)}k'
                  : '\$${val.toStringAsFixed(0)}',
              style: AppTypography.numeric(palette.textTertiary),
            ),
          );
        }),
      ),
    );
  }
}

class _Gridlines extends StatelessWidget {
  final double height;
  final AppPalette palette;
  const _Gridlines({required this.height, required this.palette});
  @override
  Widget build(BuildContext context) {
    const divisions = 4;
    return SizedBox(
      height: height,
      width: double.infinity,
      child: Stack(
        children: List.generate(divisions + 1, (i) {
          final top = (height / divisions) * i;
          return Positioned(
            top: top,
            left: 0,
            right: 0,
            child: Container(height: 1, color: palette.gridline),
          );
        }),
      ),
    );
  }
}