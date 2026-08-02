import 'package:flutter/material.dart';
import 'package:new_invoice_generator/app_theme.dart';
import 'package:new_invoice_generator/screens/home/widgets/ui_kit.dart';

class StatusBadge extends StatelessWidget {
  final bool isPaid;
  const StatusBadge({super.key, required this.isPaid});

  @override
  Widget build(BuildContext context) {
    final p = AppColors.of(context);
    return AppPill(
      label: isPaid ? 'Paid' : 'Unpaid',
      bg: isPaid ? p.successBg : p.warningBg,
      border: isPaid ? p.successBorder : p.warningBorder,
      text: isPaid ? p.successText : p.warningText,
    );
  }
}
