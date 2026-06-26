import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:new_invoice_generator/app_theme.dart';
import 'package:new_invoice_generator/providers/home_analytics.dart';
import 'package:new_invoice_generator/screens/charts/screen.dart';
import 'package:new_invoice_generator/screens/home/widgets/ui_kit.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsync = ref.watch(homeAnalyticsProvider);
    final p = AppColors.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(homeAnalyticsProvider.notifier).refresh(),
          ),
        ],
      ),
      body: analyticsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (data) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 2x2 tinted stat grid
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    label: 'Total revenue',
                    value: '\$${data.totalRevenue.toStringAsFixed(0)}',
                    icon: Icons.attach_money,
                    tint: p.successBg,
                    fg: p.successText,
                    p: p,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    label: 'This month',
                    value: '\$${data.monthRevenue.toStringAsFixed(0)}',
                    icon: Icons.calendar_today_outlined,
                    tint: p.primaryTint,
                    fg: p.primary,
                    p: p,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    label: 'This year',
                    value: '\$${data.yearRevenue.toStringAsFixed(0)}',
                    icon: Icons.bar_chart,
                    tint: p.purpleBg,
                    fg: p.purple,
                    p: p,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    label: 'Outstanding',
                    value: '\$${data.unpaid.toStringAsFixed(0)}',
                    icon: Icons.warning_amber_rounded,
                    tint: p.warningBg,
                    fg: p.warningText,
                    p: p,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Overdue (full width, danger tint) when present
            if (data.overdueCount > 0)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: p.dangerBg,
                  borderRadius: BorderRadius.circular(AppRadii.card),
                  border: Border.all(color: p.dangerBorder),
                ),
                child: Row(
                  children: [
                    AppIconTile(
                      icon: Icons.access_time_filled,
                      bg: p.surface.withAlpha(160),
                      fg: p.dangerText,
                      size: 38,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        'Overdue invoices',
                        style: AppTypography.body(p.dangerText),
                      ),
                    ),
                    Text(
                      '${data.overdueCount}',
                      style: AppTypography.amount(
                        p.dangerText,
                      ).copyWith(fontSize: 24),
                    ),
                  ],
                ),
              ),
            if (data.overdueCount > 0) const SizedBox(height: 16),

            // View charts CTA (solid indigo)
            Material(
              color: p.primary,
              borderRadius: BorderRadius.circular(AppRadii.card),
              child: InkWell(
                borderRadius: BorderRadius.circular(AppRadii.card),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ChartsScreen()),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(50),
                          borderRadius: BorderRadius.circular(AppRadii.tile),
                        ),
                        child: const Icon(
                          Icons.show_chart,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'View charts',
                              style: AppTypography.title(
                                Colors.white,
                              ).copyWith(fontSize: 16),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Revenue, trends & breakdowns',
                              style: AppTypography.caption(
                                Colors.white.withAlpha(210),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: Colors.white),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color tint, fg;
  final AppPalette p;
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.tint,
    required this.fg,
    required this.p,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: fg.withAlpha(40)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: p.surface.withAlpha(150),
              borderRadius: BorderRadius.circular(AppRadii.tile),
            ),
            child: Icon(icon, color: fg, size: 19),
          ),
          const SizedBox(height: 14),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.amount(p.ink).copyWith(fontSize: 23),
          ),
          const SizedBox(height: 2),
          Text(label, style: AppTypography.caption(p.textSecondary)),
        ],
      ),
    );
  }
}
