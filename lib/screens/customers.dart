import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:new_invoice_generator/providers/customer.dart';
import 'package:new_invoice_generator/widgets/add_customer_dialog.dart';

class CustomersScreen extends ConsumerWidget {
  const CustomersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Fixed: customerProvider is now async
    final customersAsync = ref.watch(customerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Customers')),
      body: customersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (customers) {
          if (customers.isEmpty) {
            return const Center(child: Text('No customers yet'));
          }
          return ListView.builder(
            itemCount: customers.length,
            itemBuilder: (context, i) {
              final c = customers[i];
              return ListTile(
                leading: CircleAvatar(child: Text(c.name[0].toUpperCase())),
                title: Text(c.name),
                subtitle: Text(c.email),
                trailing: IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () {
                    ref
                        .read(customerProvider.notifier)
                        .deleteCustomer(c.id);
                  },
                ),
              );
            },
          );
        },
      ),
      // Fixed: wired up AddCustomerDialog
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (_) => const AddCustomerDialog(),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}