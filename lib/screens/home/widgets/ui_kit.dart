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

/// A status pill (Paid / Unpaid / etc.) with bg + optional border + text colors.
class AppPill extends StatelessWidget {
  final String label;
  final Color bg, text;
  final Color? border; // null = no border
  final IconData? dot; // if set, draws a leading dot/icon
  final EdgeInsetsGeometry padding;
  final double fontSize;
  const AppPill({
    super.key,
    required this.label,
    required this.bg,
    required this.text,
    this.border,
    this.dot,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    this.fontSize = 11.5,
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
      padding: padding,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        border: border == null ? null : Border.all(color: border!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dot != null) ...[
            Icon(dot, size: 7, color: text),
            const SizedBox(width: 5),
          ],
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: AppTypography.caption(text).copyWith(fontSize: fontSize),
            ),
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
