import 'package:flutter/material.dart';
import 'package:new_invoice_generator/app_theme.dart';
import 'package:new_invoice_generator/desktop/widgets.dart';
import 'package:new_invoice_generator/screens/guide.dart';
import 'package:url_launcher/url_launcher.dart';

/// Desktop "How to Use This App": top bar with quick links, then the same
/// accordion content as the mobile guide in a centered reading column.
class DesktopGuide extends StatelessWidget {
  const DesktopGuide({super.key});

  @override
  Widget build(BuildContext context) {
    final p = AppColors.of(context);
    return Scaffold(
      backgroundColor: p.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DesktopTopBar(
              leading: _BackBtn(onTap: () => Navigator.maybePop(context)),
              title: 'How to Use This App',
              subtitle: 'Guides, tax notes & quick links',
              actions: [
                OutlinedButton.icon(
                  onPressed: () => launchUrl(
                    Uri.parse('https://dashboard.stripe.com'),
                    mode: LaunchMode.externalApplication,
                  ),
                  icon: const Icon(Icons.open_in_new, size: 16),
                  label: const Text('Stripe Dashboard'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 11,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton.icon(
                  onPressed: () => launchUrl(
                    Uri.parse(
                      'https://www.canada.ca/en/revenue-agency/services/tax/businesses/topics/gst-hst-businesses.html',
                    ),
                    mode: LaunchMode.externalApplication,
                  ),
                  icon: const Icon(Icons.open_in_new, size: 16),
                  label: const Text('CRA HST/GST Guide'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 11,
                    ),
                  ),
                ),
              ],
            ),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 860),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
                    children: [
                      ...guideSections,
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => launchUrl(
                                Uri.parse('https://dashboard.stripe.com'),
                                mode: LaunchMode.externalApplication,
                              ),
                              icon: const Icon(Icons.open_in_new, size: 16),
                              label: const Text('Open Stripe Dashboard'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => launchUrl(
                                Uri.parse(
                                  'https://www.canada.ca/en/revenue-agency/services/tax/businesses/topics/gst-hst-businesses.html',
                                ),
                                mode: LaunchMode.externalApplication,
                              ),
                              icon: const Icon(Icons.open_in_new, size: 16),
                              label: const Text('CRA HST/GST Guide'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
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

class _BackBtn extends StatelessWidget {
  final VoidCallback onTap;
  const _BackBtn({required this.onTap});
  @override
  Widget build(BuildContext context) {
    final p = AppColors.of(context);
    return Material(
      color: p.surface,
      borderRadius: BorderRadius.circular(AppRadii.button),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.button),
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.button),
            border: Border.all(color: p.cardBorder),
          ),
          child: Icon(Icons.arrow_back, size: 20, color: p.ink),
        ),
      ),
    );
  }
}
