import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:new_invoice_generator/models/expense.dart';
import 'package:new_invoice_generator/providers/expense.dart';

class ExpensesScreen extends ConsumerWidget {
  const ExpensesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(expenseProvider);
    final cs = Theme.of(context).colorScheme;
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      appBar: AppBar(title: const Text('Expenses')),
      body: expensesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (expenses) {
          if (expenses.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_outlined,
                      size: 64, color: cs.onSurface.withAlpha(60)),
                  const SizedBox(height: 16),
                  Text('No expenses yet',
                      style:
                          TextStyle(color: cs.onSurface.withAlpha(120))),
                ],
              ),
            );
          }

          // Group by month
          final grouped = <String, List<Expense>>{};
          for (final e in expenses) {
            final key =
                '${e.date.year}-${e.date.month.toString().padLeft(2, '0')}';
            grouped.putIfAbsent(key, () => []).add(e);
          }
          final sortedKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));
          final monthNames = ['Jan','Feb','Mar','Apr','May','Jun',
                              'Jul','Aug','Sep','Oct','Nov','Dec'];

          return ListView.builder(
            padding: EdgeInsets.fromLTRB(12, 12, 12, bottom + 80),
            itemCount: sortedKeys.length,
            itemBuilder: (context, i) {
              final key = sortedKeys[i];
              final parts = key.split('-');
              final label =
                  '${monthNames[int.parse(parts[1]) - 1]} ${parts[0]}';
              final monthExpenses = grouped[key]!;
              final monthTotal =
                  monthExpenses.fold(0.0, (s, e) => s + e.amount);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 12, 4, 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(label,
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: cs.onSurface.withAlpha(160))),
                        Text('\$${monthTotal.toStringAsFixed(2)}',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: cs.onSurface.withAlpha(160))),
                      ],
                    ),
                  ),
                  ...monthExpenses.map((exp) => _ExpenseTile(expense: exp)),
                ],
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'expenses_fab',
        onPressed: () => _showAddEdit(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddEdit(BuildContext context, WidgetRef ref,
      [Expense? existing]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _ExpenseForm(existing: existing),
    );
  }
}

// ── Individual expense tile ───────────────────────────────────────────────────
class _ExpenseTile extends ConsumerWidget {
  final Expense expense;
  const _ExpenseTile({required this.expense});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final categoryColor = _categoryColor(expense.category);

    return Dismissible(
      key: ValueKey(expense.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Delete expense?'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
      onDismissed: (_) =>
          ref.read(expenseProvider.notifier).delete(expense.id!),
      background: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
            color: Colors.red, borderRadius: BorderRadius.circular(12)),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      child: GestureDetector(
        onTap: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(24))),
          builder: (_) => _ExpenseForm(existing: expense),
        ),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: BoxDecoration(
            color: cs.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: cs.outlineVariant.withAlpha(60)),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: categoryColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                    _categoryIcon(expense.category),
                    color: categoryColor,
                    size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(expense.description,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14),
                              overflow: TextOverflow.ellipsis),
                        ),
                        Text('\$${expense.amount.toStringAsFixed(2)}',
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 14)),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(expense.category,
                            style: TextStyle(
                                fontSize: 12,
                                color: cs.onSurface.withAlpha(150))),
                        if (expense.taxAmount > 0)
                          Text(
                              'Tax: \$${expense.taxAmount.toStringAsFixed(2)}',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: cs.onSurface.withAlpha(130))),
                      ],
                    ),
                    if (expense.vendor != null)
                      Text(expense.vendor!,
                          style: TextStyle(
                              fontSize: 11,
                              color: cs.onSurface.withAlpha(120))),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _categoryColor(String cat) {
    switch (cat) {
      case 'Supplies & Materials': return Colors.orange;
      case 'Software & Subscriptions': return Colors.blue;
      case 'Marketing & Advertising': return Colors.purple;
      case 'Travel & Transportation': return Colors.teal;
      case 'Meals & Entertainment': return Colors.pink;
      case 'Professional Services': return Colors.indigo;
      case 'Rent & Utilities': return Colors.brown;
      case 'Equipment': return Colors.cyan;
      default: return Colors.blueGrey;
    }
  }

  IconData _categoryIcon(String cat) {
    switch (cat) {
      case 'Supplies & Materials': return Icons.inventory_2_outlined;
      case 'Software & Subscriptions': return Icons.computer_outlined;
      case 'Marketing & Advertising': return Icons.campaign_outlined;
      case 'Travel & Transportation': return Icons.directions_car_outlined;
      case 'Meals & Entertainment': return Icons.restaurant_outlined;
      case 'Professional Services': return Icons.business_center_outlined;
      case 'Rent & Utilities': return Icons.home_outlined;
      case 'Equipment': return Icons.build_outlined;
      default: return Icons.attach_money;
    }
  }
}

// ── Add / Edit expense form ───────────────────────────────────────────────────
class _ExpenseForm extends ConsumerStatefulWidget {
  final Expense? existing;
  const _ExpenseForm({this.existing});

  @override
  ConsumerState<_ExpenseForm> createState() => _ExpenseFormState();
}

class _ExpenseFormState extends ConsumerState<_ExpenseForm> {
  final _descCtrl   = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _taxCtrl    = TextEditingController();
  final _vendorCtrl = TextEditingController();
  final _notesCtrl  = TextEditingController();

  late DateTime _date;
  late String _category;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _descCtrl.text   = e?.description ?? '';
    _amountCtrl.text = e != null ? e.amount.toStringAsFixed(2) : '';
    _taxCtrl.text    = e != null && e.taxAmount > 0
        ? e.taxAmount.toStringAsFixed(2)
        : '';
    _vendorCtrl.text = e?.vendor ?? '';
    _notesCtrl.text  = e?.notes ?? '';
    _date            = e?.date ?? DateTime.now();
    _category        = e?.category ?? Expense.categories.first;
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    _amountCtrl.dispose();
    _taxCtrl.dispose();
    _vendorCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_descCtrl.text.trim().isEmpty) return;
    final amount = double.tryParse(_amountCtrl.text);
    if (amount == null || amount <= 0) return;
    final taxAmount = double.tryParse(_taxCtrl.text) ?? 0;

    final expense = Expense(
      id:          widget.existing?.id,
      description: _descCtrl.text.trim(),
      category:    _category,
      date:        _date,
      amount:      amount,
      taxAmount:   taxAmount,
      vendor:      _vendorCtrl.text.trim().isEmpty ? null : _vendorCtrl.text.trim(),
      notes:       _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
    );

    if (widget.existing == null) {
      await ref.read(expenseProvider.notifier).add(expense);
    } else {
      await ref.read(expenseProvider.notifier).updateExpense(expense);
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(isEdit ? 'Edit Expense' : 'Add Expense',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),

          TextField(
            controller: _descCtrl,
            decoration: const InputDecoration(labelText: 'Description *'),
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 10),

          DropdownButtonFormField<String>(
            initialValue: _category,
            decoration: const InputDecoration(labelText: 'Category'),
            items: Expense.categories
                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                .toList(),
            onChanged: (v) => setState(() => _category = v!),
          ),
          const SizedBox(height: 10),

          Row(children: [
            Expanded(
              child: TextField(
                controller: _amountCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration:
                    const InputDecoration(labelText: 'Amount (\$) *', prefixText: '\$'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _taxCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                    labelText: 'Tax paid (\$)',
                    prefixText: '\$',
                    hintText: '0.00'),
              ),
            ),
          ]),
          const SizedBox(height: 10),

          TextField(
            controller: _vendorCtrl,
            decoration: const InputDecoration(
                labelText: 'Vendor / Payee', hintText: 'Optional'),
          ),
          const SizedBox(height: 10),

          // Date picker
          InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _date,
                firstDate: DateTime(2020),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (picked != null) setState(() => _date = picked);
            },
            child: InputDecorator(
              decoration: const InputDecoration(
                  labelText: 'Date',
                  suffixIcon: Icon(Icons.calendar_today_outlined, size: 18)),
              child:
                  Text(_date.toLocal().toString().split(' ')[0]),
            ),
          ),
          const SizedBox(height: 10),

          TextField(
            controller: _notesCtrl,
            maxLines: 2,
            decoration: const InputDecoration(
                labelText: 'Notes', hintText: 'Optional'),
          ),
          const SizedBox(height: 20),

          ElevatedButton(
            onPressed: _save,
            style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(48)),
            child: Text(isEdit ? 'Save Changes' : 'Add Expense'),
          ),
        ],
      ),
    );
  }
}