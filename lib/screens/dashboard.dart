import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:new_invoice_generator/providers/home_analytics.dart';
import 'package:new_invoice_generator/screens/charts/screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsync = ref.watch(homeAnalyticsProvider);
    final cs = Theme.of(context).colorScheme;

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
          padding: const .all(16),
          children: [
            // Stat cards
            _StatCard(
              label: 'Total Revenue',
              value: '\$${data.totalRevenue.toStringAsFixed(2)}',
              icon: Icons.attach_money,
              color: Colors.green,
            ),
            const SizedBox(height: 12),
            _StatCard(
              label: 'This Month',
              value: '\$${data.monthRevenue.toStringAsFixed(2)}',
              icon: Icons.calendar_month,
              color: Colors.blue,
            ),
            const SizedBox(height: 12),
            _StatCard(
              label: 'This Year',
              value: '\$${data.yearRevenue.toStringAsFixed(2)}',
              icon: Icons.bar_chart,
              color: Colors.purple,
            ),
            const SizedBox(height: 12),
            _StatCard(
              label: 'Outstanding',
              value: '\$${data.unpaid.toStringAsFixed(2)}',
              icon: Icons.warning_amber,
              color: Colors.orange,
            ),
            const SizedBox(height: 12),
            if (data.overdueCount > 0)
              _StatCard(
                label: 'Overdue invoices',
                value: '${data.overdueCount}',
                icon: Icons.access_time_filled,
                color: Colors.red,
              ),
            const SizedBox(height: 24),

            // Charts shortcut
            Card(
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ChartsScreen()),
                ),
                child: Padding(
                  padding: const .all(20),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: cs.primaryContainer,
                        child: Icon(
                          Icons.bar_chart,
                          color: cs.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: .start,
                          children: [
                            Text(
                              'View Charts',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: .bold),
                            ),
                            Text(
                              'Revenue, trends & breakdowns',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right),
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
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const .all(20),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withAlpha(30),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: .start,
              children: [
                Text(label, style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: .bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
