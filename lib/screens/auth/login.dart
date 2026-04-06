import 'package:flutter/material.dart';
import 'package:new_invoice_generator/screens/auth/widgets/register_form.dart';
import 'package:new_invoice_generator/screens/auth/widgets/sign_in_form.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const .all(24),
            child: Column(
              mainAxisAlignment: .center,
              children: [
                // Logo / title
                Icon(Icons.receipt_long_rounded, size: 64, color: cs.primary),
                const SizedBox(height: 12),
                Text(
                  'Invoice App',
                  style: Theme.of(
                    context,
                  ).textTheme.headlineSmall?.copyWith(fontWeight: .bold),
                ),
                const SizedBox(height: 32),

                // Tab bar
                Container(
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest,
                    borderRadius: .circular(12),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      color: cs.primary,
                      borderRadius: .circular(10),
                    ),
                    indicatorSize: .tab,
                    labelColor: cs.onPrimary,
                    unselectedLabelColor: cs.onSurface,
                    dividerColor: Colors.transparent,
                    tabs: const [
                      Tab(text: 'Sign In'),
                      Tab(text: 'Create Account'),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Tab content
                SizedBox(
                  height: 340,
                  child: TabBarView(
                    controller: _tabController,
                    children: const [SignInForm(), RegisterForm()],
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