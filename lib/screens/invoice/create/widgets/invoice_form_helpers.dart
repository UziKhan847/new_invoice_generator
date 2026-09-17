// Shared helper widgets used across create invoice form sections
import 'package:flutter/material.dart';

/// A titled card section used throughout the create invoice form.
class SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  /// Optional widget shown at the end of the title row (e.g. a "+ Add"
  /// button to create a customer/employee inline without leaving the form).
  final Widget? trailing;
  const SectionCard({
    super.key,
    required this.title,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                ?trailing,
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

/// A subtotal/tax/total row in the invoice summary.
class TotalLine extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  final Color? color;

  const TotalLine({
    super.key,
    required this.label,
    required this.value,
    this.bold = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontWeight: bold ? FontWeight.bold : FontWeight.normal,
      fontSize: bold ? 15 : 13,
      color: color,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(value, style: style),
        ],
      ),
    );
  }
}
