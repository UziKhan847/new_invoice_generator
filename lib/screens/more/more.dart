import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:new_invoice_generator/main.dart';
import 'package:new_invoice_generator/providers/theme.dart';
import 'package:new_invoice_generator/screens/company_profile.dart';
import 'package:new_invoice_generator/screens/employees.dart';
import 'package:new_invoice_generator/screens/more/widgets/company_logo_card.dart';
import 'package:new_invoice_generator/screens/more/widgets/more_nav_tile.dart';
import 'package:new_invoice_generator/screens/recurring_invoices.dart';
import 'package:new_invoice_generator/screens/services.dart';

class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeProvider) == ThemeMode.dark;

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
            child: SwitchListTile(
              title: const Text('Dark Mode'),
              secondary: Icon(isDark ? Icons.dark_mode : Icons.light_mode),
              value: isDark,
              onChanged: (_) => ref.read(themeProvider.notifier).toggle(),
            ),
          ),
          const SizedBox(height: 16),

          // ── Business ─────────────────────────────────────────────
          const MoreSectionHeader(title: 'Business'),
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
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Account ──────────────────────────────────────────────
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
        content:
            const Text('You will be returned to the login screen.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Log out',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await supabase.auth.signOut();
    }
  }
}