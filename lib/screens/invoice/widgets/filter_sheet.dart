import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:new_invoice_generator/models/invoice/filter.dart';
import 'package:new_invoice_generator/providers/customer.dart';
import 'package:new_invoice_generator/providers/employee.dart';
import 'package:new_invoice_generator/providers/invoice/filter.dart';
import 'package:new_invoice_generator/providers/service.dart';

class InvoiceFilterSheet extends ConsumerStatefulWidget {
  const InvoiceFilterSheet({super.key});

  @override
  ConsumerState<InvoiceFilterSheet> createState() => _InvoiceFilterSheetState();
}

class _InvoiceFilterSheetState extends ConsumerState<InvoiceFilterSheet> {
  late InvoiceFilter _local;

  @override
  void initState() {
    super.initState();
    _local = ref.read(invoiceFilterProvider);
  }

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(customerProvider);
    final employeesAsync = ref.watch(employeeProvider);
    final services = ref.watch(serviceProvider).asData?.value ?? [];
    final now = DateTime.now();

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Filter Invoices',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () => setState(() => _local = const InvoiceFilter()),
                child: const Text('Clear all'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Customer
          customersAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
            data: (customers) => DropdownButtonFormField<String>(
              initialValue: _local.customerId,
              decoration: const InputDecoration(
                labelText: 'Customer',
                isDense: true,
              ),
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('All customers'),
                ),
                ...customers.map(
                  (c) => DropdownMenuItem(value: c.id, child: Text(c.name)),
                ),
              ],
              onChanged: (v) {
                final name =
                    customers
                            .cast<dynamic>()
                            .firstWhere((c) => c.id == v, orElse: () => null)
                            ?.name
                        as String?;
                setState(
                  () => _local = _local.copyWith(
                    customerId: v,
                    customerName: name,
                    clearCustomer: v == null,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),

          // Sender
          employeesAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
            data: (employees) => DropdownButtonFormField<String>(
              initialValue: _local.senderEmployeeId,
              decoration: const InputDecoration(
                labelText: 'Sender',
                isDense: true,
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('All senders')),
                ...employees.map(
                  (e) => DropdownMenuItem(value: e.id, child: Text(e.name)),
                ),
              ],
              onChanged: (v) {
                final name =
                    employees
                            .cast<dynamic>()
                            .firstWhere((e) => e.id == v, orElse: () => null)
                            ?.name
                        as String?;
                setState(
                  () => _local = _local.copyWith(
                    senderEmployeeId: v,
                    senderName: name,
                    clearSender: v == null,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),

          // Service
          if (services.isNotEmpty)
            DropdownButtonFormField<String>(
              initialValue: _local.serviceId,
              decoration: const InputDecoration(
                labelText: 'Service',
                isDense: true,
              ),
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('All services'),
                ),
                ...services.map(
                  (s) => DropdownMenuItem(value: s.id, child: Text(s.name)),
                ),
              ],
              onChanged: (v) {
                final name =
                    services
                            .cast<dynamic>()
                            .firstWhere((s) => s.id == v, orElse: () => null)
                            ?.name
                        as String?;
                setState(
                  () => _local = _local.copyWith(
                    serviceId: v,
                    serviceName: name,
                    clearService: v == null,
                  ),
                );
              },
            ),
          const SizedBox(height: 12),

          // Month + Year
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  initialValue: _local.month,
                  decoration: const InputDecoration(
                    labelText: 'Month',
                    isDense: true,
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Any')),
                    ...List.generate(
                      12,
                      (i) => DropdownMenuItem(
                        value: i + 1,
                        child: Text(
                          const [
                            'Jan',
                            'Feb',
                            'Mar',
                            'Apr',
                            'May',
                            'Jun',
                            'Jul',
                            'Aug',
                            'Sep',
                            'Oct',
                            'Nov',
                            'Dec',
                          ][i],
                        ),
                      ),
                    ),
                  ],
                  onChanged: (v) => setState(
                    () => _local = _local.copyWith(
                      month: v,
                      clearMonth: v == null,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<int>(
                  initialValue: _local.year,
                  decoration: const InputDecoration(
                    labelText: 'Year',
                    isDense: true,
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Any')),
                    ...List.generate(
                      5,
                      (i) => DropdownMenuItem(
                        value: now.year - i,
                        child: Text('${now.year - i}'),
                      ),
                    ),
                  ],
                  onChanged: (v) => setState(
                    () =>
                        _local = _local.copyWith(year: v, clearYear: v == null),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Status
          DropdownButtonFormField<bool>(
            initialValue: _local.isPaid,
            decoration: const InputDecoration(
              labelText: 'Status',
              isDense: true,
            ),
            items: const [
              DropdownMenuItem(value: null, child: Text('All')),
              DropdownMenuItem(value: true, child: Text('Paid')),
              DropdownMenuItem(value: false, child: Text('Unpaid')),
            ],
            onChanged: (v) => setState(
              () => _local = _local.copyWith(isPaid: v, clearStatus: v == null),
            ),
          ),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              onPressed: () {
                ref.read(invoiceFilterProvider.notifier).update(_local);
                Navigator.pop(context);
              },
              child: const Text('Apply Filters'),
            ),
          ),
        ],
      ),
    );
  }
}
