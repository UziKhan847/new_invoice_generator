import 'package:flutter/material.dart';
import 'package:new_invoice_generator/app_theme.dart';
import 'package:new_invoice_generator/main.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isSignIn = true;

  @override
  Widget build(BuildContext context) {
    final p = AppColors.of(context);
    // Desktop split layout when wide enough.
    final wide = MediaQuery.sizeOf(context).width >= 900;

    final formCard = _AuthCard(
      isSignIn: _isSignIn,
      onSwitch: (v) => setState(() => _isSignIn = v),
      showHeading: wide,
    );

    if (wide) {
      return Scaffold(
        backgroundColor: p.surface,
        body: Row(
          children: [
            // Brand panel
            Expanded(child: _BrandPanel()),
            // Form
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(40),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: formCard,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Mobile: centered brand mark + form
    return Scaffold(
      backgroundColor: p.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    color: p.primary,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: const Icon(
                    Icons.receipt_long_rounded,
                    size: 42,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Invoice App',
                  style: AppTypography.display(p.ink).copyWith(fontSize: 30),
                ),
                const SizedBox(height: 6),
                Text(
                  'Sign in to your workspace',
                  style: AppTypography.body(p.textSecondary),
                ),
                const SizedBox(height: 32),
                formCard,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Branded left panel for the desktop split layout.
class _BrandPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final p = AppColors.of(context);
    return Container(
      color: p.primary,
      padding: const EdgeInsets.all(48),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(
            top: -60,
            right: -40,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(20),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            left: -30,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(15),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(45),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const Icon(
                      Icons.receipt_long_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Text(
                    'Invoice App',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              const Text(
                'Invoicing, taxes,\nand clients — in\none workspace.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  height: 1.2,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Create invoices, track HST/GST, and export CRA-ready '
                'reports without leaving the app.',
                style: TextStyle(
                  color: Colors.white.withAlpha(210),
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
              const Spacer(),
              _feature(context, 'Stripe & e-transfer payments'),
              const SizedBox(height: 14),
              _feature(context, 'Recurring & duplicated invoices'),
              const SizedBox(height: 14),
              _feature(context, 'One-tap CRA tax reports'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _feature(BuildContext context, String label) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(45),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check, color: Colors.white, size: 15),
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(color: Colors.white.withAlpha(235), fontSize: 15),
        ),
      ],
    );
  }
}

/// The shared card: segmented tabs + the active form.
class _AuthCard extends StatelessWidget {
  final bool isSignIn;
  final ValueChanged<bool> onSwitch;
  final bool showHeading;
  const _AuthCard({
    required this.isSignIn,
    required this.onSwitch,
    required this.showHeading,
  });

  @override
  Widget build(BuildContext context) {
    final p = AppColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showHeading) ...[
          Text(
            'Welcome back',
            style: AppTypography.display(p.ink).copyWith(fontSize: 30),
          ),
          const SizedBox(height: 4),
          Text(
            'Sign in to your workspace to continue.',
            style: AppTypography.body(p.textSecondary),
          ),
          const SizedBox(height: 22),
        ],
        // Segmented tabs
        Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: p.surfaceAlt,
            borderRadius: BorderRadius.circular(13),
          ),
          child: Row(
            children: [
              _seg(context, 'Sign In', isSignIn, () => onSwitch(true)),
              _seg(context, 'Create Account', !isSignIn, () => onSwitch(false)),
            ],
          ),
        ),
        const SizedBox(height: 22),
        isSignIn
            ? _SignInForm(onCreateAccount: () => onSwitch(false))
            : const _RegisterForm(),
      ],
    );
  }

  Widget _seg(
    BuildContext context,
    String label,
    bool active,
    VoidCallback onTap,
  ) {
    final p = AppColors.of(context);
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: active ? p.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: active ? Colors.white : p.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Sign In ──────────────────────────────────────────────────────────────────
class _SignInForm extends StatefulWidget {
  final VoidCallback onCreateAccount;
  const _SignInForm({required this.onCreateAccount});

  @override
  State<_SignInForm> createState() => _SignInFormState();
}

class _SignInFormState extends State<_SignInForm> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await supabase.auth.signInWithPassword(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
      );
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _forgotPassword() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      setState(
        () => _error = 'Enter your email first, then tap Forgot password.',
      );
      return;
    }
    try {
      await supabase.auth.resetPasswordForEmail(email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Password reset link sent to $email')),
      );
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = AppColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Field(
          controller: _emailCtrl,
          hint: 'you@company.com',
          label: 'Email',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),
        _Field(
          controller: _passwordCtrl,
          hint: 'Password',
          label: 'Password',
          icon: Icons.lock_outline,
          obscure: _obscurePassword,
          trailingLabel: GestureDetector(
            onTap: _forgotPassword,
            child: Text(
              'Forgot password?',
              style: AppTypography.body(
                p.primary,
              ).copyWith(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
          suffix: IconButton(
            icon: Icon(
              _obscurePassword
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
            ),
            onPressed: () =>
                setState(() => _obscurePassword = !_obscurePassword),
          ),
          onSubmitted: (_) => _signIn(),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(
            _error!,
            style: const TextStyle(color: Colors.red, fontSize: 13),
          ),
        ],
        const SizedBox(height: 22),
        FilledButton(
          onPressed: _loading ? null : _signIn,
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          child: _loading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text(
                  'Sign In',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
        ),
        const SizedBox(height: 14),
        Center(
          child: GestureDetector(
            onTap: widget.onCreateAccount,
            child: RichText(
              text: TextSpan(
                style: AppTypography.body(p.textSecondary),
                children: [
                  const TextSpan(text: 'New here? '),
                  TextSpan(
                    text: 'Create an account',
                    style: AppTypography.body(
                      p.primary,
                    ).copyWith(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Create Account ───────────────────────────────────────────────────────────
class _RegisterForm extends StatefulWidget {
  const _RegisterForm();

  @override
  State<_RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<_RegisterForm> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _loading = false;
  String? _error;
  bool _success = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (_passwordCtrl.text != _confirmCtrl.text) {
      setState(() => _error = 'Passwords do not match');
      return;
    }
    if (_passwordCtrl.text.length < 6) {
      setState(() => _error = 'Password must be at least 6 characters');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await supabase.auth.signUp(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
      );
      if (mounted) setState(() => _success = true);
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = AppColors.of(context);
    if (_success) {
      return Column(
        children: [
          const Icon(
            Icons.mark_email_read_outlined,
            size: 48,
            color: Colors.green,
          ),
          const SizedBox(height: 16),
          Text(
            'Account created!',
            style: AppTypography.title(p.ink).copyWith(fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            'Check your email to confirm your account, then sign in.',
            textAlign: TextAlign.center,
            style: AppTypography.bodyMuted(p.textSecondary),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Field(
          controller: _emailCtrl,
          hint: 'you@company.com',
          label: 'Email',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 14),
        _Field(
          controller: _passwordCtrl,
          hint: 'Password',
          label: 'Password',
          icon: Icons.lock_outline,
          obscure: _obscurePassword,
          suffix: IconButton(
            icon: Icon(
              _obscurePassword
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
            ),
            onPressed: () =>
                setState(() => _obscurePassword = !_obscurePassword),
          ),
        ),
        const SizedBox(height: 14),
        _Field(
          controller: _confirmCtrl,
          hint: 'Confirm password',
          label: 'Confirm password',
          icon: Icons.lock_outline,
          obscure: _obscureConfirm,
          suffix: IconButton(
            icon: Icon(
              _obscureConfirm
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
            ),
            onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
          ),
          onSubmitted: (_) => _register(),
        ),
        if (_error != null) ...[
          const SizedBox(height: 10),
          Text(
            _error!,
            style: const TextStyle(color: Colors.red, fontSize: 13),
          ),
        ],
        const SizedBox(height: 20),
        FilledButton(
          onPressed: _loading ? null : _register,
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          child: _loading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text(
                  'Create Account',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
        ),
      ],
    );
  }
}

/// A labeled field with an optional trailing label (e.g. "Forgot password?").
class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final String label;
  final IconData icon;
  final bool obscure;
  final Widget? suffix;
  final Widget? trailingLabel;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onSubmitted;
  const _Field({
    required this.controller,
    required this.hint,
    required this.label,
    required this.icon,
    this.obscure = false,
    this.suffix,
    this.trailingLabel,
    this.keyboardType,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    final p = AppColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppTypography.label(p.textSecondary)),
            ?trailingLabel,
          ],
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          onSubmitted: onSubmitted,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, size: 20),
            suffixIcon: suffix,
          ),
        ),
      ],
    );
  }
}
