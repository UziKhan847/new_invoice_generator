import 'package:flutter/material.dart';

class MoreSectionHeader extends StatelessWidget {
  final String title;
  const MoreSectionHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
          color: Theme.of(context).colorScheme.onSurface.withAlpha(120),
        ),
      ),
    );
  }
}

class MoreNavTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? iconColor;

  const MoreNavTile({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(label,
          style: iconColor != null ? TextStyle(color: iconColor) : null),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}