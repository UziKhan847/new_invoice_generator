import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:new_invoice_generator/models/province.dart';
import 'package:new_invoice_generator/providers/company.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _nameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  Province _province = Province.fromCode('ON');
  bool _loading = false;
  String? _error;
  int _step = 0; // 0 = welcome, 1 = company details, 2 = province

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    if (_nameCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Please enter your company name');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref
          .read(companyProvider.notifier)
          .completeOnboarding(
            name: _nameCtrl.text.trim(),
            province: _province.code,
            taxRate: _province.taxRate,
            taxLabel: _province.taxLabel,
            address: _addressCtrl.text.trim().isEmpty
                ? null
                : _addressCtrl.text.trim(),
            email: _emailCtrl.text.trim().isEmpty
                ? null
                : _emailCtrl.text.trim(),
            phone: _phoneCtrl.text.trim().isEmpty
                ? null
                : _phoneCtrl.text.trim(),
          );
      // AuthGate will rebuild and show AppShell once company.onboarded = true
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _step == 0
                ? _WelcomeStep(
                    key: const ValueKey(0),
                    onNext: () => setState(() => _step = 1),
                  )
                : _step == 1
                ? _CompanyStep(
                    key: const ValueKey(1),
                    nameCtrl: _nameCtrl,
                    addressCtrl: _addressCtrl,
                    emailCtrl: _emailCtrl,
                    phoneCtrl: _phoneCtrl,
                    error: _error,
                    onBack: () => setState(() => _step = 0),
                    onNext: () {
                      if (_nameCtrl.text.trim().isEmpty) {
                        setState(() => _error = 'Company name is required');
                        return;
                      }
                      setState(() {
                        _error = null;
                        _step = 2;
                      });
                    },
                  )
                : _ProvinceStep(
                    key: const ValueKey(2),
                    selected: _province,
                    loading: _loading,
                    error: _error,
                    onBack: () => setState(() => _step = 1),
                    onChanged: (p) => setState(() => _province = p),
                    onFinish: _finish,
                  ),
          ),
        ),
      ),
    );
  }
}

// ── Step 0: Welcome ───────────────────────────────────────────────────────────
class _WelcomeStep extends StatelessWidget {
  final VoidCallback onNext;
  const _WelcomeStep({super.key, required this.onNext});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.receipt_long_rounded, size: 80, color: cs.primary),
        const SizedBox(height: 24),
        Text(
          'Welcome!',
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Text(
          "Let's set up your account in just a few steps. "
          "We'll ask for your company details and province so we can "
          "calculate the correct tax rate automatically.",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            color: cs.onSurface.withAlpha(160),
            height: 1.5,
          ),
        ),
        const SizedBox(height: 40),
        ElevatedButton(
          onPressed: onNext,
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
          ),
          child: const Text(
            "Let's get started",
            style: TextStyle(fontSize: 16),
          ),
        ),
      ],
    );
  }
}

// ── Step 1: Company details ───────────────────────────────────────────────────
class _CompanyStep extends StatelessWidget {
  final TextEditingController nameCtrl;
  final TextEditingController addressCtrl;
  final TextEditingController emailCtrl;
  final TextEditingController phoneCtrl;
  final String? error;
  final VoidCallback onBack;
  final VoidCallback onNext;

  const _CompanyStep({
    super.key,
    required this.nameCtrl,
    required this.addressCtrl,
    required this.emailCtrl,
    required this.phoneCtrl,
    required this.error,
    required this.onBack,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 20),
        Text(
          'Your Company',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'This information will appear on your invoices.',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withAlpha(150),
          ),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: nameCtrl,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Company / Business Name *',
            prefixIcon: Icon(Icons.business_outlined),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: addressCtrl,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: 'Address (optional)',
            prefixIcon: Icon(Icons.location_on_outlined),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: emailCtrl,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Business Email (optional)',
            prefixIcon: Icon(Icons.email_outlined),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: phoneCtrl,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: 'Phone (optional)',
            prefixIcon: Icon(Icons.phone_outlined),
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 8),
          Text(error!, style: const TextStyle(color: Colors.red)),
        ],
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: onBack,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                child: const Text('Back'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: onNext,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                child: const Text('Next'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Step 2: Province / Tax ────────────────────────────────────────────────────
class _ProvinceStep extends StatelessWidget {
  final Province selected;
  final bool loading;
  final String? error;
  final VoidCallback onBack;
  final VoidCallback onFinish;
  final ValueChanged<Province> onChanged;

  const _ProvinceStep({
    super.key,
    required this.selected,
    required this.loading,
    required this.error,
    required this.onBack,
    required this.onFinish,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 20),
        Text(
          'Your Province',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'This sets the tax rate on your invoices. '
          'You can change it later in Company Profile.',
          style: TextStyle(color: cs.onSurface.withAlpha(150)),
        ),
        const SizedBox(height: 24),
        DropdownButtonFormField<String>(
          initialValue: selected.code,
          decoration: const InputDecoration(
            labelText: 'Province / Territory',
            prefixIcon: Icon(Icons.map_outlined),
          ),
          items: Province.all
              .map(
                (p) => DropdownMenuItem(
                  value: p.code,
                  child: Text('${p.name} — ${p.taxDisplay}'),
                ),
              )
              .toList(),
          onChanged: (code) {
            if (code != null) onChanged(Province.fromCode(code));
          },
        ),
        const SizedBox(height: 16),
        // Tax preview card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cs.primaryContainer.withAlpha(80),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: cs.primary.withAlpha(60)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: cs.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Tax Preview',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: cs.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text('A \$100.00 service will appear on invoices as:'),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [const Text('Subtotal:'), const Text('\$100.00')],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${selected.taxLabel} (${(selected.taxRate * 100).toStringAsFixed(selected.taxRate * 100 % 1 == 0 ? 0 : 3)}%):',
                  ),
                  Text('\$${(100 * selected.taxRate).toStringAsFixed(2)}'),
                ],
              ),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '\$${(100 + 100 * selected.taxRate).toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 8),
          Text(error!, style: const TextStyle(color: Colors.red)),
        ],
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: loading ? null : onBack,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                child: const Text('Back'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: loading ? null : onFinish,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                child: loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(
                        'Finish Setup',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
