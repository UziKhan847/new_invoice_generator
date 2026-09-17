import 'package:flutter/material.dart';
import 'package:new_invoice_generator/app_theme.dart';
import 'package:new_invoice_generator/desktop/widgets.dart';
import 'package:new_invoice_generator/screens/services.dart';

/// Services, promoted to a top-level desktop section (was buried in
/// Settings) — desktop has the horizontal space to show it directly.
class DesktopServices extends StatelessWidget {
  const DesktopServices({super.key});

  @override
  Widget build(BuildContext context) {
    final p = AppColors.of(context);
    final radius = BorderRadius.circular(AppRadii.card);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const DesktopTopBar(
          title: 'Services',
          subtitle: 'Reusable line items you bill customers for',
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: radius,
                border: Border.all(color: p.cardBorder),
              ),
              child: ClipRRect(
                borderRadius: radius,
                child: const EmbeddedMobileSection(child: ServicesScreen()),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
