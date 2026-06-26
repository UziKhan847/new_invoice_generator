import 'package:flutter/material.dart';
import 'package:new_invoice_generator/app_theme.dart';

class StatusBadge extends StatelessWidget {
  final bool isPaid;
  const StatusBadge({super.key, required this.isPaid});

  @override
  Widget build(BuildContext context) {
    final p = AppColors.of(context);
    final bg = isPaid ? p.successBg : p.warningBg;
    final border = isPaid ? p.successBorder : p.warningBorder;
    final text = isPaid ? p.successText : p.warningText;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        border: Border.all(color: border),
      ),
      child: Text(
        isPaid ? 'Paid' : 'Unpaid',
        style: AppTypography.caption(text).copyWith(fontSize: 11.5),
      ),
    );
  }
}
