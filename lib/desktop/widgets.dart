import 'package:flutter/material.dart';
import 'package:new_invoice_generator/app_theme.dart';

/// Standard desktop page top bar: title + subtitle on the left, actions on the
/// right. Used by every desktop screen for a consistent header.
class DesktopTopBar extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget> actions;
  final Widget? leading;
  const DesktopTopBar({
    super.key,
    required this.title,
    this.subtitle,
    this.actions = const [],
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    final p = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 22, 28, 18),
      child: Row(
        children: [
          if (leading != null) ...[leading!, const SizedBox(width: 14)],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: AppTypography.display(p.ink).copyWith(fontSize: 24)),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!,
                      style: AppTypography.bodyMuted(p.textSecondary)),
                ],
              ],
            ),
          ),
          ...actions,
        ],
      ),
    );
  }
}

/// A compact desktop search field for the top bar.
class DesktopSearchField extends StatelessWidget {
  final String hint;
  final ValueChanged<String>? onChanged;
  final double width;
  final TextEditingController? controller;
  const DesktopSearchField({
    super.key,
    this.hint = 'Search',
    this.onChanged,
    this.width = 260,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final p = AppColors.of(context);
    return SizedBox(
      width: width,
      height: 42,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: AppTypography.body(p.ink).copyWith(fontSize: 13),
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(Icons.search, size: 18, color: p.textTertiary),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
        ),
      ),
    );
  }
}

/// A KPI card for the desktop dashboards: icon tile top-left, optional badge
/// top-right, big value, label underneath.
class DesktopKpiCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color tint;
  final Color fg;
  final String? badge;
  final Color? badgeBg;
  final Color? badgeFg;
  const DesktopKpiCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.tint,
    required this.fg,
    this.badge,
    this.badgeBg,
    this.badgeFg,
  });

  @override
  Widget build(BuildContext context) {
    final p = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: p.cardBorder),
        boxShadow: p.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: tint,
                  borderRadius: BorderRadius.circular(AppRadii.tile),
                ),
                child: Icon(icon, color: fg, size: 19),
              ),
              const Spacer(),
              if (badge != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                  decoration: BoxDecoration(
                    color: badgeBg ?? p.surfaceAlt,
                    borderRadius: BorderRadius.circular(AppRadii.pill),
                  ),
                  child: Text(badge!,
                      style: AppTypography.caption(badgeFg ?? p.textSecondary)
                          .copyWith(fontSize: 11)),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.amount(p.ink).copyWith(fontSize: 26)),
          const SizedBox(height: 3),
          Text(label, style: AppTypography.bodyMuted(p.textSecondary)),
        ],
      ),
    );
  }
}

/// A surface card wrapper for desktop content blocks (white, bordered, shadowed).
class DesktopPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  const DesktopPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
  });

  @override
  Widget build(BuildContext context) {
    final p = AppColors.of(context);
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: p.cardBorder),
        boxShadow: p.cardShadow,
      ),
      child: child,
    );
  }
}

/// A "+ New Invoice"-style primary button used in desktop top bars.
class DesktopPrimaryButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const DesktopPrimaryButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
      ),
    );
  }
}