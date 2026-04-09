import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:new_invoice_generator/models/service.dart';
import 'package:new_invoice_generator/providers/service.dart';

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
        data: (services) => services.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.design_services_outlined, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text('No services yet', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  const Text('Tap + to add a service',
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
              itemCount: services.length,
              itemBuilder: (context, i) {
                final s = services[i];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          Theme.of(context).colorScheme.primaryContainer,
                      child: Icon(Icons.design_services,
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                          size: 18),
                    ),
                    title: Text(s.name,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: s.description != null && s.description!.isNotEmpty
                        ? Text(s.description!)
                        : null,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('\$${s.unitPrice.toStringAsFixed(2)}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 14)),
                            if (s.rateType != 'fixed')
                              Text(s.rateLabel,
                                  style: const TextStyle(
                                      fontSize: 11, color: Colors.grey)),
                          ],
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () => ref
                              .read(serviceProvider.notifier)
                              .deleteService(s.id),
                        ),
                      ],
                    ),
                    onTap: () => showDialog(
                      context: context,
                      builder: (_) => _ServiceDialog(service: s),
                    ),
                  ),
                );
              },
            ),
      ),  // end .when()
      floatingActionButton: FloatingActionButton(
        onPressed: () => showDialog(
          context: context,
          builder: (_) => const _ServiceDialog(),
        ),
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
    ('fixed',    'Fixed'),
    ('hourly',   'Hourly'),
    ('daily',    'Daily'),
    ('weekly',   'Weekly'),
    ('4_weekly', 'Every 4 Weeks'),
    ('monthly',  'Monthly'),
    ('yearly',   'Yearly'),
  ];

  @override
  void initState() {
    super.initState();
    _nameCtrl  = TextEditingController(text: widget.service?.name ?? '');
    _descCtrl  = TextEditingController(text: widget.service?.description ?? '');
    _priceCtrl = TextEditingController(
        text: widget.service?.unitPrice.toStringAsFixed(2) ?? '');
    _rateType  = widget.service?.rateType ?? 'fixed';
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _descCtrl.dispose(); _priceCtrl.dispose();
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
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Service name'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _descCtrl,
              decoration:
                  const InputDecoration(labelText: 'Description (optional)'),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _priceCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Price (\$)'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 3,
                  child: DropdownButtonFormField<String>(
                    initialValue: _rateType,
                    decoration: const InputDecoration(labelText: 'Rate'),
                    items: _rateOptions
                        .map((o) => DropdownMenuItem(
                            value: o.$1, child: Text(o.$2)))
                        .toList(),
                    onChanged: (v) => setState(() => _rateType = v!),
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
            child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            if (_nameCtrl.text.trim().isEmpty || _priceCtrl.text.isEmpty) return;
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