import 'package:flutter/material.dart';
import 'package:new_invoice_generator/app_theme.dart';

/// A content card matching the design: white surface, hairline border, soft
/// shadow (light mode only), 17px radius.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final p = AppColors.of(context);
    final card = Container(
      decoration: BoxDecoration(
        color: color ?? p.surface,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: p.cardBorder),
        boxShadow: p.cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: onTap == null
            ? Padding(padding: padding, child: child)
            : InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(AppRadii.card),
                child: Padding(padding: padding, child: child),
              ),
      ),
    );
    return card;
  }
}

/// A small rounded icon tile (used on stat cards).
class AppIconTile extends StatelessWidget {
  final IconData icon;
  final Color bg;
  final Color fg;
  final double size;
  const AppIconTile({
    super.key,
    required this.icon,
    required this.bg,
    required this.fg,
    this.size = 34,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadii.tile),
      ),
      child: Icon(icon, color: fg, size: size * 0.5),
    );
  }
}

/// A status pill (Paid / Unpaid / etc.) with bg + border + text colors.
class AppPill extends StatelessWidget {
  final String label;
  final Color bg, border, text;
  final IconData? dot; // if set, draws a leading dot/icon
  const AppPill({
    super.key,
    required this.label,
    required this.bg,
    required this.border,
    required this.text,
    this.dot,
  });

  factory AppPill.paid(BuildContext context) {
    final p = AppColors.of(context);
    return AppPill(
      label: 'Paid',
      bg: p.successBg,
      border: p.successBorder,
      text: p.successText,
      dot: Icons.circle,
    );
  }
  factory AppPill.unpaid(BuildContext context) {
    final p = AppColors.of(context);
    return AppPill(
      label: 'Unpaid',
      bg: p.warningBg,
      border: p.warningBorder,
      text: p.warningText,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dot != null) ...[
            Icon(dot, size: 7, color: text),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: AppTypography.caption(text).copyWith(fontSize: 11.5),
          ),
        ],
      ),
    );
  }
}

/// Uppercase section label.
class AppLabel extends StatelessWidget {
  final String text;
  const AppLabel(this.text, {super.key});
  @override
  Widget build(BuildContext context) {
    final p = AppColors.of(context);
    return Text(
      text.toUpperCase(),
      style: AppTypography.label(p.textSecondary),
    );
  }
}
