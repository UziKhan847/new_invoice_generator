import 'package:flutter/material.dart';
import 'package:new_invoice_generator/app_theme.dart';
import 'package:new_invoice_generator/models/home_analytics.dart';
import 'package:new_invoice_generator/screens/home/widgets/ui_kit.dart';

class StatRow extends StatelessWidget {
  final HomeAnalytics analytics;
  const StatRow({super.key, required this.analytics});

  @override
  Widget build(BuildContext context) {
    final p = AppColors.of(context);
    return SizedBox(
      height: 116,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        children: [
          _StatCard(
            label: 'This Month',
            value: '\$${analytics.monthRevenue.toStringAsFixed(0)}',
            icon: Icons.calendar_today_outlined,
            tint: p.primaryTint,
            fg: p.primary,
            valueColor: p.primary,
          ),
          _StatCard(
            label: 'Outstanding',
            value: '\$${analytics.unpaid.toStringAsFixed(0)}',
            icon: Icons.warning_amber_rounded,
            tint: p.warningBg,
            fg: p.warningText,
            valueColor: p.warningText,
          ),
          _StatCard(
            label: 'Total Revenue',
            value: '\$${analytics.totalRevenue.toStringAsFixed(0)}',
            icon: Icons.attach_money,
            tint: p.successBg,
            fg: p.successText,
            valueColor: p.successText,
          ),
          _StatCard(
            label: 'Overdue',
            value: '${analytics.overdueCount}',
            icon: Icons.access_time_filled,
            tint: p.dangerBg,
            fg: p.dangerText,
            valueColor: p.dangerText,
          ),
          _StatCard(
            label: 'This Year',
            value: '\$${analytics.yearRevenue.toStringAsFixed(0)}',
            icon: Icons.bar_chart,
            tint: p.purpleBg,
            fg: p.purple,
            valueColor: p.purple,
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color tint, fg, valueColor;
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.tint,
    required this.fg,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final p = AppColors.of(context);
    return Container(
      width: 138,
      margin: const EdgeInsets.only(right: AppSpacing.sm),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: tint,
          borderRadius: BorderRadius.circular(AppRadii.card),
          border: Border.all(color: fg.withAlpha(40)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            AppIconTile(
              icon: icon,
              bg: p.surface.withAlpha(160),
              fg: fg,
              size: 32,
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.amount(
                    valueColor,
                  ).copyWith(fontSize: 23),
                ),
                const SizedBox(height: 2),
                Text(label, style: AppTypography.caption(fg.withAlpha(200))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
