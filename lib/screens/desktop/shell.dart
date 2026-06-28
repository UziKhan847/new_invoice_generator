import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:new_invoice_generator/app_theme.dart';
import 'package:new_invoice_generator/providers/company.dart';
import 'package:new_invoice_generator/providers/invoice.dart';
import 'package:new_invoice_generator/screens/charts/screen.dart';
import 'package:new_invoice_generator/screens/desktop/customers.dart';
import 'package:new_invoice_generator/screens/desktop/dashboard.dart';
import 'package:new_invoice_generator/screens/desktop/invoice/invoices.dart';
import 'package:new_invoice_generator/screens/desktop/overview.dart';
import 'package:new_invoice_generator/screens/desktop/settings.dart';
import 'package:new_invoice_generator/screens/desktop/tax_report.dart';

/// Which top-level desktop section is showing.
class DesktopNavNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void select(int index) => state = index;
}

final desktopNavProvider = NotifierProvider<DesktopNavNotifier, int>(
  DesktopNavNotifier.new,
);

class DesktopShell extends ConsumerWidget {
  const DesktopShell({super.key});

  // Sections, in sidebar order. Each maps to a content widget.
  static const _sections = [
    _NavItem('Overview', Icons.home_outlined, Icons.home),
    _NavItem('Invoices', Icons.receipt_long_outlined, Icons.receipt_long),
    _NavItem('Customers', Icons.people_outline, Icons.people),
    _NavItem('Dashboard', Icons.dashboard_outlined, Icons.dashboard),
    _NavItem('Charts', Icons.bar_chart_outlined, Icons.bar_chart),
    _NavItem(
      'Tax Report',
      Icons.account_balance_outlined,
      Icons.account_balance,
    ),
  ];

  static const _pages = [
    DesktopOverview(),
    DesktopInvoices(),
    DesktopCustomers(),
    DesktopDashboard(),
    ChartsScreen(),
    DesktopTaxReport(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = AppColors.of(context);
    final selected = ref.watch(desktopNavProvider);

    return Scaffold(
      backgroundColor: p.background,
      body: Row(
        children: [
          _Sidebar(selected: selected),
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: p.background,
                borderRadius: BorderRadius.circular(18),
              ),
              clipBehavior: Clip.antiAlias,
              // The hosted screen provides its own Scaffold/body. We strip its
              // app bar visually by letting it fill; mobile screens still work.
              child: _pages[selected],
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem {
  final String label;
  final IconData icon, activeIcon;
  const _NavItem(this.label, this.icon, this.activeIcon);
}

class _Sidebar extends ConsumerWidget {
  final int selected;
  const _Sidebar({required this.selected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = AppColors.of(context);
    final company = ref.watch(companyProvider).asData?.value ?? {};
    final companyName = (company['name'] as String?)?.trim().isNotEmpty == true
        ? company['name'] as String
        : 'My Company';
    final initials = _initials(companyName);

    // Invoices awaiting payment → badge count
    final invoices = ref.watch(invoiceProvider).asData?.value ?? [];
    final awaiting = invoices.where((i) => !i.isPaid && !i.isPrivate).length;

    return Container(
      width: 236,
      color: p.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Brand block
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 22, 18, 18),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: p.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    initials,
                    style: AppTypography.title(
                      Colors.white,
                    ).copyWith(fontSize: 14),
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        companyName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.title(
                          p.ink,
                        ).copyWith(fontSize: 14),
                      ),
                      Text(
                        'Invoicing workspace',
                        style: AppTypography.caption(
                          p.textTertiary,
                        ).copyWith(fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Text(
              'WORKSPACE',
              style: AppTypography.label(p.textTertiary),
            ),
          ),

          // Nav items
          ...List.generate(DesktopShell._sections.length, (i) {
            final s = DesktopShell._sections[i];
            final active = i == selected;
            final badge = i == 1 && awaiting > 0 ? awaiting : null;
            return _SidebarTile(
              item: s,
              active: active,
              badge: badge,
              onTap: () => ref.read(desktopNavProvider.notifier).select(i),
            );
          }),

          const Spacer(),
          Divider(height: 1, color: p.border),

          // Settings
          _SidebarTile(
            item: const _NavItem(
              'Settings',
              Icons.settings_outlined,
              Icons.settings,
            ),
            active: false,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DesktopSettings()),
            ),
          ),

          // User chip
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: p.primaryTint,
                  child: Text(
                    initials.isNotEmpty ? initials[0] : '?',
                    style: AppTypography.title(
                      p.primary,
                    ).copyWith(fontSize: 13),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (company['email'] as String?)?.split('@').first ??
                            'You',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.body(p.ink).copyWith(fontSize: 13),
                      ),
                      Text(
                        'Workspace owner',
                        style: AppTypography.caption(
                          p.textTertiary,
                        ).copyWith(fontSize: 11),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.unfold_more, size: 16, color: p.textTertiary),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((s) => s.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return (parts.first[0] + parts[1][0]).toUpperCase();
  }
}

class _SidebarTile extends StatelessWidget {
  final _NavItem item;
  final bool active;
  final int? badge;
  final VoidCallback onTap;
  const _SidebarTile({
    required this.item,
    required this.active,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final p = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: active ? p.primaryTint : Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadii.button),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadii.button),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            child: Row(
              children: [
                Icon(
                  active ? item.activeIcon : item.icon,
                  size: 20,
                  color: active ? p.primary : p.textSecondary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.label,
                    style: active
                        ? AppTypography.title(p.primary).copyWith(fontSize: 14)
                        : AppTypography.body(p.textSecondary),
                  ),
                ),
                if (badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: p.warningBg,
                      borderRadius: BorderRadius.circular(AppRadii.pill),
                    ),
                    child: Text(
                      '$badge',
                      style: AppTypography.caption(
                        p.warningText,
                      ).copyWith(fontSize: 11),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
