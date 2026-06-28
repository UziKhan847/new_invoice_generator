import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:new_invoice_generator/main.dart';
import 'package:new_invoice_generator/providers/layout_mode.dart';
import 'package:new_invoice_generator/providers/theme.dart';
import 'package:new_invoice_generator/screens/company_profile.dart';
import 'package:new_invoice_generator/screens/employees.dart';
import 'package:new_invoice_generator/screens/expense.dart';
import 'package:new_invoice_generator/screens/guide.dart';
import 'package:new_invoice_generator/screens/more/widgets/company_logo_card.dart';
import 'package:new_invoice_generator/screens/more/widgets/more_nav_tile.dart';
import 'package:new_invoice_generator/screens/recurring_invoices.dart';
import 'package:new_invoice_generator/screens/services.dart';
import 'package:new_invoice_generator/screens/tax_report.dart';

class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('More')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Company card ─────────────────────────────────────────
          const CompanyLogoCard(),
          const SizedBox(height: 16),

          // ── Settings ─────────────────────────────────────────────
          const MoreSectionHeader(title: 'Settings'),
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        themeMode.icon,
                        size: 20,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Theme',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SegmentedButton<AppThemeMode>(
                    segments: AppThemeMode.values
                        .map(
                          (m) => ButtonSegment<AppThemeMode>(
                            value: m,
                            label: Text(
                              m.label,
                              style: const TextStyle(fontSize: 12),
                            ),
                            icon: Icon(m.icon, size: 16),
                          ),
                        )
                        .toList(),
                    selected: {themeMode},
                    onSelectionChanged: (s) =>
                        ref.read(themeProvider.notifier).set(s.first),
                    style: SegmentedButton.styleFrom(
                      minimumSize: const Size(0, 38),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    themeMode == AppThemeMode.oled
                        ? 'Pure black background — saves battery on OLED screens.'
                        : themeMode == AppThemeMode.dark
                        ? 'Soft dark greys — easy on the eyes at night.'
                        : 'Default light theme.',
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withAlpha(140),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Layout ───────────────────────────────────────────────
          const MoreSectionHeader(title: 'Layout'),
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 8, 6),
              child: Builder(
                builder: (context) {
                  final mode = ref.watch(layoutModeProvider);
                  final desktop = mode.isDesktop;
                  return SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: desktop,
                    onChanged: (v) => ref
                        .read(layoutModeProvider.notifier)
                        .set(v ? LayoutMode.desktop : LayoutMode.mobile),
                    secondary: Icon(
                      desktop
                          ? Icons.desktop_windows_outlined
                          : Icons.phone_iphone_outlined,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    title: const Text(
                      'Desktop layout',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      isDesktopPlatform
                          ? 'Sidebar + tables. Turn off to preview the mobile layout.'
                          : 'Sidebar + tables — handy on tablets and larger screens.',
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withAlpha(140),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                MoreNavTile(
                  icon: Icons.business_outlined,
                  label: 'Company Profile',
                  onTap: () => _push(context, const CompanyProfileScreen()),
                ),
                const Divider(height: 0, indent: 56),
                MoreNavTile(
                  icon: Icons.design_services_outlined,
                  label: 'Services',
                  onTap: () => _push(context, const ServicesScreen()),
                ),
                const Divider(height: 0, indent: 56),
                MoreNavTile(
                  icon: Icons.badge_outlined,
                  label: 'Employees',
                  onTap: () => _push(context, const EmployeesScreen()),
                ),
                const Divider(height: 0, indent: 56),
                MoreNavTile(
                  icon: Icons.repeat,
                  label: 'Recurring Invoices',
                  onTap: () => _push(context, const RecurringInvoicesScreen()),
                ),
                const Divider(height: 0, indent: 56),
                MoreNavTile(
                  icon: Icons.receipt_long_outlined,
                  label: 'Expenses',
                  onTap: () => _push(context, const ExpensesScreen()),
                ),
                const Divider(height: 0, indent: 56),
                MoreNavTile(
                  icon: Icons.calculate_outlined,
                  label: 'Tax Report',
                  onTap: () => _push(context, const TaxReportScreen()),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Account ──────────────────────────────────────────────
          const MoreSectionHeader(title: 'Help'),
          Card(
            child: MoreNavTile(
              icon: Icons.menu_book_outlined,
              label: 'How to Use This App',
              onTap: () => _push(context, const GuideScreen()),
            ),
          ),
          const SizedBox(height: 16),

          const MoreSectionHeader(title: 'Account'),
          Card(
            child: MoreNavTile(
              icon: Icons.logout,
              label: 'Log out',
              iconColor: Colors.red,
              onTap: () => _confirmLogout(context),
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  void _push(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('You will be returned to the login screen.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Log out', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await supabase.auth.signOut();
    }
  }
}
