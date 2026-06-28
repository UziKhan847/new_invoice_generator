import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:new_invoice_generator/app_theme.dart';
import 'package:new_invoice_generator/providers/company.dart';
import 'package:new_invoice_generator/providers/employee.dart';
import 'package:new_invoice_generator/providers/layout_mode.dart';
import 'package:new_invoice_generator/providers/service.dart';
import 'package:new_invoice_generator/providers/theme.dart';
import 'package:new_invoice_generator/screens/company_profile.dart';
import 'package:new_invoice_generator/screens/desktop/widgets.dart';
import 'package:new_invoice_generator/screens/employees.dart';
import 'package:new_invoice_generator/screens/expense.dart';
import 'package:new_invoice_generator/screens/recurring_invoices.dart';
import 'package:new_invoice_generator/screens/services.dart';

/// Which settings section is shown.
class SettingsSectionNotifier extends Notifier<int> {
  @override
  int build() => 0;
  void select(int i) => state = i;
}

final settingsSectionProvider = NotifierProvider<SettingsSectionNotifier, int>(
  SettingsSectionNotifier.new,
);

class DesktopSettings extends ConsumerWidget {
  const DesktopSettings({super.key});

  static const _sections = [
    ('Company Profile', Color(0xFF2C56B5)),
    ('Services', Color(0xFF7C5CCB)),
    ('Employees', Color(0xFF157A45)),
    ('Recurring Invoices', Color(0xFFC29A43)),
    ('Expenses', Color(0xFFC2453E)),
    ('Appearance', Color(0xFF157A45)),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = AppColors.of(context);
    final selected = ref.watch(settingsSectionProvider);

    return Scaffold(
      backgroundColor: p.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DesktopTopBar(
              leading: _BackBtn(onTap: () => Navigator.maybePop(context)),
              title: 'Settings',
              subtitle: 'Manage your workspace',
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section rail
                    SizedBox(
                      width: 220,
                      child: Column(
                        children: List.generate(_sections.length, (i) {
                          final (label, dot) = _sections[i];
                          final active = i == selected;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Material(
                              color: active
                                  ? p.primaryTint
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(
                                AppRadii.button,
                              ),
                              child: InkWell(
                                onTap: () => ref
                                    .read(settingsSectionProvider.notifier)
                                    .select(i),
                                borderRadius: BorderRadius.circular(
                                  AppRadii.button,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 12,
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: dot,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 11),
                                      Text(
                                        label,
                                        style: active
                                            ? AppTypography.title(
                                                p.primary,
                                              ).copyWith(fontSize: 14)
                                            : AppTypography.body(
                                                p.textSecondary,
                                              ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                    const SizedBox(width: 24),
                    // Content
                    Expanded(
                      child: switch (selected) {
                        0 => const _CompanyProfileSection(),
                        1 => const _EmbeddedSection(
                          key: ValueKey('services'),
                          child: ServicesScreen(),
                        ),
                        2 => const _EmbeddedSection(
                          key: ValueKey('employees'),
                          child: EmployeesScreen(),
                        ),
                        3 => const _EmbeddedSection(
                          key: ValueKey('recurring'),
                          child: RecurringInvoicesScreen(),
                        ),
                        4 => const _EmbeddedSection(
                          key: ValueKey('expenses'),
                          child: ExpensesScreen(),
                        ),
                        _ => const _AppearanceSection(),
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Wraps an existing mobile screen so it renders cleanly inside the content
/// area. A nested [Navigator] gives it a fresh routing root, so its own AppBar
/// shows no spurious back arrow (it can't pop past this boundary), and any
/// dialogs/sheets it opens still work.
class _EmbeddedSection extends StatelessWidget {
  final Widget child;
  const _EmbeddedSection({super.key, required this.child});
  @override
  Widget build(BuildContext context) {
    final p = AppColors.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadii.card),
      child: Container(
        color: p.surface,
        child: Navigator(
          onGenerateRoute: (settings) =>
              MaterialPageRoute(settings: settings, builder: (_) => child),
        ),
      ),
    );
  }
}

class _CompanyProfileSection extends ConsumerWidget {
  const _CompanyProfileSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = AppColors.of(context);
    final company = ref.watch(companyProvider).asData?.value ?? {};
    final name = (company['name'] as String?) ?? 'My Company';
    final email = (company['email'] as String?) ?? '';
    final phone = (company['phone'] as String?) ?? '';
    final bn = (company['business_number'] as String?) ?? '';
    final rt = (company['rt_number'] as String?) ?? '';
    final bnLine = [
      if (bn.isNotEmpty) bn,
      if (rt.isNotEmpty) 'RT $rt',
    ].join(' ');
    final addr = [
      company['address_line'],
      company['city'],
      company['province_region'],
      company['postal_code'],
    ].where((s) => s != null && (s as String).trim().isNotEmpty).join(', ');

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        // Header card
        DesktopPanel(
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: p.primary,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Text(
                  _initials(name),
                  style: AppTypography.title(
                    Colors.white,
                  ).copyWith(fontSize: 17),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: AppTypography.title(p.ink).copyWith(fontSize: 18),
                    ),
                    if (email.isNotEmpty)
                      Text(
                        email,
                        style: AppTypography.bodyMuted(p.textSecondary),
                      ),
                  ],
                ),
              ),
              OutlinedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CompanyProfileScreen(),
                  ),
                ),
                child: const Text('Edit profile'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        Text('COMPANY DETAILS', style: AppTypography.label(p.textTertiary)),
        const SizedBox(height: 10),
        DesktopPanel(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _DetailRow(label: 'Legal name', value: name),
              _divider(p),
              _DetailRow(
                label: 'Business number',
                value: bnLine.isEmpty ? '—' : bnLine,
              ),
              _divider(p),
              _DetailRow(label: 'Address', value: addr.isEmpty ? '—' : addr),
              _divider(p),
              _DetailRow(label: 'Email', value: email.isEmpty ? '—' : email),
              _divider(p),
              _DetailRow(label: 'Phone', value: phone.isEmpty ? '—' : phone),
            ],
          ),
        ),
      ],
    );
  }

  Widget _divider(AppPalette p) => Divider(height: 1, color: p.border);

  static String _initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((s) => s.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first[0] + parts[1][0]).toUpperCase();
  }
}

class _DetailRow extends StatelessWidget {
  final String label, value;
  const _DetailRow({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    final p = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Row(
        children: [
          SizedBox(
            width: 160,
            child: Text(
              label,
              style: AppTypography.body(p.textSecondary).copyWith(fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTypography.title(p.ink).copyWith(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

class _AppearanceSection extends ConsumerWidget {
  const _AppearanceSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = AppColors.of(context);
    final themeMode = ref.watch(themeProvider);
    final layout = ref.watch(layoutModeProvider);

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        Text('THEME', style: AppTypography.label(p.textTertiary)),
        const SizedBox(height: 10),
        DesktopPanel(
          child: Align(
            alignment: Alignment.centerLeft,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: SegmentedButton<AppThemeMode>(
                segments: AppThemeMode.values
                    .map(
                      (m) => ButtonSegment<AppThemeMode>(
                        value: m,
                        label: Text(m.label),
                        icon: Icon(m.icon, size: 16),
                      ),
                    )
                    .toList(),
                selected: {themeMode},
                onSelectionChanged: (s) =>
                    ref.read(themeProvider.notifier).set(s.first),
              ),
            ),
          ),
        ),
        const SizedBox(height: 22),
        Text('LAYOUT', style: AppTypography.label(p.textTertiary)),
        const SizedBox(height: 10),
        DesktopPanel(
          child: SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: layout.isDesktop,
            onChanged: (v) => ref
                .read(layoutModeProvider.notifier)
                .set(v ? LayoutMode.desktop : LayoutMode.mobile),
            title: Text(
              'Desktop layout',
              style: AppTypography.title(p.ink).copyWith(fontSize: 15),
            ),
            subtitle: Text(
              'Sidebar + tables. Turn off to use the compact mobile layout.',
              style: AppTypography.bodyMuted(p.textSecondary),
            ),
          ),
        ),
      ],
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
