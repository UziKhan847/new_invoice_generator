import 'package:flutter/material.dart';
import 'package:new_invoice_generator/models/home_analytics.dart';

class StatRow extends StatelessWidget {
  final HomeAnalytics analytics;
  const StatRow({super.key, required this.analytics});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 110,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _StatChip(
            label: 'This Month',
            value: '\$${analytics.monthRevenue.toStringAsFixed(0)}',
            icon: Icons.calendar_month,
            color: Colors.blue,
          ),
          _StatChip(
            label: 'Outstanding',
            value: '\$${analytics.unpaid.toStringAsFixed(0)}',
            icon: Icons.warning_amber_rounded,
            color: Colors.orange,
          ),
          _StatChip(
            label: 'Total Revenue',
            value: '\$${analytics.totalRevenue.toStringAsFixed(0)}',
            icon: Icons.attach_money,
            color: Colors.green,
          ),
          _StatChip(
            label: 'Overdue',
            value: '${analytics.overdueCount}',
            icon: Icons.access_time_filled,
            color: Colors.red,
          ),
          _StatChip(
            label: 'This Year',
            value: '\$${analytics.yearRevenue.toStringAsFixed(0)}',
            icon: Icons.bar_chart,
            color: Colors.purple,
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatChip({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12, top: 4, bottom: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withAlpha(18),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlpha(40)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
                fontWeight: FontWeight.bold, fontSize: 18, color: color),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: color.withAlpha(180)),
          ),
        ],
      ),
    );
  }
}