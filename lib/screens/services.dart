import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:new_invoice_generator/app_theme.dart';
import 'package:new_invoice_generator/models/service.dart';
import 'package:new_invoice_generator/providers/service.dart';
import 'package:new_invoice_generator/screens/home/widgets/ui_kit.dart';

class ServicesScreen extends ConsumerWidget {
  const ServicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final servicesAsync = ref.watch(serviceProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Services')),
      body: servicesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: \$e')),
        data: (services) {
          final p = AppColors.of(context);
          if (services.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.sell_outlined,
                    size: 64,
                    color: p.textTertiary.withAlpha(120),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No services yet',
                    style: AppTypography.body(p.textSecondary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap + to add a service',
                    style: AppTypography.caption(p.textTertiary),
                  ),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: EdgeInsets.fromLTRB(
              16,
              12,
              16,
              MediaQuery.paddingOf(context).bottom + 90,
            ),
            itemCount: services.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final s = services[i];
              return AppCard(
                padding: const EdgeInsets.all(14),
                onTap: () => showDialog(
                  context: context,
                  builder: (_) => _ServiceDialog(service: s),
                ),
                child: Row(
                  children: [
                    AppIconTile(
                      icon: Icons.sell_outlined,
                      bg: p.primaryTint,
                      fg: p.primary,
                      size: 40,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.title(
                              p.ink,
                            ).copyWith(fontSize: 15),
                          ),
                          const SizedBox(height: 5),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: s.rateType == 'fixed'
                                  ? p.surfaceAlt
                                  : p.primaryTint,
                              borderRadius: BorderRadius.circular(
                                AppRadii.pill,
                              ),
                            ),
                            child: Text(
                              s.rateType == 'fixed' ? 'Fixed' : s.rateLabel,
                              style: AppTypography.caption(
                                s.rateType == 'fixed'
                                    ? p.textSecondary
                                    : p.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '\$${s.unitPrice.toStringAsFixed(2)}',
                      style: AppTypography.amount(p.ink).copyWith(fontSize: 18),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_outline, color: p.dangerText),
                      onPressed: () => ref
                          .read(serviceProvider.notifier)
                          .deleteService(s.id),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'services_fab',
        onPressed: () => showDialog(
          context: context,
          builder: (_) => const _ServiceDialog(),
        ),
        backgroundColor: AppColors.of(context).primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _ServiceDialog extends ConsumerStatefulWidget {
  final Service? service;
  const _ServiceDialog({this.service});

  @override
  ConsumerState<_ServiceDialog> createState() => _ServiceDialogState();
}

class _ServiceDialogState extends ConsumerState<_ServiceDialog> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _priceCtrl;
  late String _rateType;

  static const _rateOptions = [
    ('fixed', 'Fixed'),
    ('hourly', 'Hourly'),
    ('daily', 'Daily'),
    ('weekly', 'Weekly'),
    ('4_weekly', 'Every 4 Weeks'),
    ('monthly', 'Monthly'),
    ('yearly', 'Yearly'),
  ];

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.service?.name ?? '');
    _descCtrl = TextEditingController(text: widget.service?.description ?? '');
    _priceCtrl = TextEditingController(
      text: widget.service?.unitPrice.toStringAsFixed(2) ?? '',
    );
    _rateType = widget.service?.rateType ?? 'fixed';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.service != null;
    return AlertDialog(
      title: Text(isEdit ? 'Edit Service' : 'Add Service'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _FieldLabel('Service name'),
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(hintText: 'e.g. Quran 375'),
            ),
            const SizedBox(height: 14),
            const _FieldLabel('Description (optional)'),
            TextField(
              controller: _descCtrl,
              decoration: const InputDecoration(
                hintText: 'Shown on the invoice',
              ),
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _FieldLabel('Price'),
                      TextField(
                        controller: _priceCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(hintText: '\$0.00'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _FieldLabel('Rate'),
                      DropdownButtonFormField<String>(
                        initialValue: _rateType,
                        items: _rateOptions
                            .map(
                              (o) => DropdownMenuItem(
                                value: o.$1,
                                child: Text(o.$2),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => _rateType = v!),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_nameCtrl.text.trim().isEmpty || _priceCtrl.text.isEmpty) {
              return;
            }
            final s = Service(
              // For new services, id is ignored — Supabase generates UUID via toInsertMap
              id: widget.service?.id ?? '',
              name: _nameCtrl.text.trim(),
              description: _descCtrl.text.trim().isEmpty
                  ? null
                  : _descCtrl.text.trim(),
              unitPrice: double.tryParse(_priceCtrl.text) ?? 0,
              rateType: _rateType,
            );
            if (isEdit) {
              ref.read(serviceProvider.notifier).updateService(s);
            } else {
              ref.read(serviceProvider.notifier).addService(s);
            }
            Navigator.pop(context);
          },
          child: Text(isEdit ? 'Update' : 'Save'),
        ),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, left: 2),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
