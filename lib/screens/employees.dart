import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:new_invoice_generator/models/employee.dart';
import 'package:new_invoice_generator/providers/employee.dart';

class EmployeesScreen extends ConsumerWidget {
  const EmployeesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final employeesAsync = ref.watch(employeeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Employees')),
      body: employeesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (employees) {
          if (employees.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: .center,
                children: [
                  const Icon(
                    Icons.badge_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No employees yet',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tap + to add one',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const .all(12),
            itemCount: employees.length,
            itemBuilder: (context, i) {
              final e = employees[i];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(child: Text(e.name[0].toUpperCase())),
                  title: Text(
                    e.name,
                    style: const TextStyle(fontWeight: .w600),
                  ),
                  subtitle: Text(
                    '${e.role}${e.email.isNotEmpty ? ' · ${e.email}' : ''}',
                  ),
                  trailing: Row(
                    mainAxisSize: .min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () => showDialog(
                          context: context,
                          builder: (_) => _EmployeeDialog(employee: e),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                        ),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text('Remove employee?'),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text('Cancel'),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                  ),
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text(
                                    'Remove',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            await ref
                                .read(employeeProvider.notifier)
                                .delete(e.id);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showDialog(
          context: context,
          builder: (_) => const _EmployeeDialog(),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _EmployeeDialog extends ConsumerStatefulWidget {
  final Employee? employee;
  const _EmployeeDialog({this.employee});

  @override
  ConsumerState<_EmployeeDialog> createState() => _EmployeeDialogState();
}

class _EmployeeDialogState extends ConsumerState<_EmployeeDialog> {
  late final TextEditingController _name;
  late final TextEditingController _role;
  late final TextEditingController _email;
  late final TextEditingController _phone;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.employee?.name ?? '');
    _role = TextEditingController(text: widget.employee?.role ?? '');
    _email = TextEditingController(text: widget.employee?.email ?? '');
    _phone = TextEditingController(text: widget.employee?.phone ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _role.dispose();
    _email.dispose();
    _phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.employee != null;
    return AlertDialog(
      title: Text(isEdit ? 'Edit Employee' : 'Add Employee'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: .min,
          children: [
            TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Full name'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _role,
              decoration: const InputDecoration(labelText: 'Role / title'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Phone (optional)'),
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
          onPressed: _loading
              ? null
              : () async {
                  if (_name.text.trim().isEmpty || _role.text.trim().isEmpty) {
                    return;
                  }
                  setState(() => _loading = true);
                  try {
                    final e = Employee(
                      id: widget.employee?.id ?? '',
                      name: _name.text.trim(),
                      role: _role.text.trim(),
                      email: _email.text.trim(),
                      phone: _phone.text.trim().isEmpty
                          ? null
                          : _phone.text.trim(),
                    );
                    if (isEdit) {
                      await ref.read(employeeProvider.notifier).save(e);
                    } else {
                      await ref.read(employeeProvider.notifier).add(e);
                    }
                    if (context.mounted) Navigator.pop(context);
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('Error: $e')));
                  } finally {
                    if (mounted) setState(() => _loading = false);
                  }
                },
          child: _loading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(isEdit ? 'Update' : 'Save'),
        ),
      ],
    );
  }
}
