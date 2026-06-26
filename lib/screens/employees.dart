import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:new_invoice_generator/app_theme.dart';
import 'package:new_invoice_generator/screens/home/widgets/ui_kit.dart';
import 'package:new_invoice_generator/screens/widgets/phone_field.dart';
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
          final p = AppColors.of(context);
          if (employees.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.badge_outlined,
                    size: 64,
                    color: p.textTertiary.withAlpha(120),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No employees yet',
                    style: AppTypography.body(p.textSecondary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap + to add one',
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
            itemCount: employees.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final e = employees[i];
              // Stable tinted avatar color from the name
              final palettes = [
                (p.primaryTint, p.primary),
                (p.successBg, p.successText),
                (p.purpleBg, p.purple),
                (p.warningBg, p.warningText),
              ];
              final tone = palettes[e.name.hashCode.abs() % palettes.length];
              return AppCard(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: tone.$1,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        e.name.isNotEmpty ? e.name[0].toUpperCase() : '?',
                        style: AppTypography.title(
                          tone.$2,
                        ).copyWith(fontSize: 18),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  e.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.title(
                                    p.ink,
                                  ).copyWith(fontSize: 16),
                                ),
                              ),
                              if (e.role.isNotEmpty) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: p.primaryTint,
                                    borderRadius: BorderRadius.circular(
                                      AppRadii.pill,
                                    ),
                                  ),
                                  child: Text(
                                    e.role,
                                    style: AppTypography.caption(
                                      p.primary,
                                    ).copyWith(fontSize: 10.5),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          if (e.email.isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Text(
                              e.email,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.bodyMuted(p.textSecondary),
                            ),
                          ],
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.edit_outlined, color: p.textSecondary),
                      visualDensity: VisualDensity.compact,
                      onPressed: () => showDialog(
                        context: context,
                        builder: (_) => _EmployeeDialog(employee: e),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_outline, color: p.dangerText),
                      visualDensity: VisualDensity.compact,
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text('Remove employee?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
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
        backgroundColor: AppColors.of(context).primary,
        foregroundColor: Colors.white,
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
  String _phone = '';
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.employee?.name ?? '');
    _role = TextEditingController(text: widget.employee?.role ?? '');
    _email = TextEditingController(text: widget.employee?.email ?? '');
    _phone = widget.employee?.phone ?? '';
  }

  @override
  void dispose() {
    _name.dispose();
    _role.dispose();
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.employee != null;
    return AlertDialog(
      title: Text(isEdit ? 'Edit Employee' : 'Add Employee'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _FieldLabel('Full name'),
            TextField(
              controller: _name,
              decoration: const InputDecoration(hintText: 'e.g. John'),
            ),
            const SizedBox(height: 14),
            const _FieldLabel('Role / title'),
            TextField(
              controller: _role,
              decoration: const InputDecoration(hintText: 'e.g. Manager'),
            ),
            const SizedBox(height: 14),
            const _FieldLabel('Email'),
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(hintText: 'name@example.com'),
            ),
            const SizedBox(height: 14),
            const _FieldLabel('Phone (optional)'),
            PhoneField(
              initial: _phone,
              label: null,
              onChanged: (v) => _phone = v,
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
                      phone: _phone.isEmpty ? null : _phone,
                    );
                    if (isEdit) {
                      await ref.read(employeeProvider.notifier).save(e);
                    } else {
                      await ref.read(employeeProvider.notifier).add(e);
                    }
                    if (context.mounted) Navigator.pop(context);
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text('Error: $e')));
                    }
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
