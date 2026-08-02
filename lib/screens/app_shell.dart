import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:new_invoice_generator/desktop/shell.dart';
import 'package:new_invoice_generator/providers/layout_mode.dart';
import 'package:new_invoice_generator/screens/customers.dart';
import 'package:new_invoice_generator/screens/dashboard.dart';
import 'package:new_invoice_generator/screens/home/home.dart';
import 'package:new_invoice_generator/screens/invoice/list.dart';
import 'package:new_invoice_generator/screens/more/more.dart';

/// Top-level shell: renders the desktop sidebar layout or the mobile
/// bottom-nav layout based on [layoutModeProvider].
class AppShell extends ConsumerWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(layoutModeProvider);
    // Safety net: never render the desktop layout on a device too small for it
    // (a phone), even if a desktop override is stored — otherwise the user can
    // get trapped in an unusable portrait sidebar with no way to revert.
    final allowed = deviceAllowsDesktop(context);
    final useDesktop = mode.isDesktop && allowed;
    return useDesktop ? const DesktopShell() : const MobileShell();
  }
}

class MobileShell extends StatefulWidget {
  const MobileShell({super.key});

  @override
  State<MobileShell> createState() => _MobileShellState();
}

class _MobileShellState extends State<MobileShell> {
  int _selected = 0;

  static const List<Widget> _pages = [
    HomeScreen(),
    InvoiceListScreen(),
    CustomersScreen(),
    DashboardScreen(),
    MoreScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selected, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selected,
        onDestinationSelected: (i) => setState(() => _selected = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Invoices',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Customers',
          ),
          NavigationDestination(
            icon: Icon(Icons.show_chart_outlined),
            selectedIcon: Icon(Icons.show_chart),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.more_horiz_outlined),
            selectedIcon: Icon(Icons.more_horiz),
            label: 'More',
          ),
        ],
      ),
    );
  }
}
