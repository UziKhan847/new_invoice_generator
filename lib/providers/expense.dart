import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:new_invoice_generator/models/expense.dart';
import 'package:new_invoice_generator/providers/company.dart';
import 'package:new_invoice_generator/repositories/expense.dart';

final expenseProvider = AsyncNotifierProvider<ExpenseNotifier, List<Expense>>(
  ExpenseNotifier.new,
);

class ExpenseNotifier extends AsyncNotifier<List<Expense>> {
  final _repo = ExpenseRepository();

  @override
  Future<List<Expense>> build() async {
    final company = await ref.read(companyProvider.future);
    return _repo.fetchExpenses(company['id'] as String);
  }

  Future<void> add(Expense expense) async {
    final company = await ref.read(companyProvider.future);
    await _repo.addExpense(company['id'] as String, expense);
    ref.invalidateSelf();
    await future;
  }

  Future<void> updateExpense(Expense expense) async {
    await _repo.updateExpense(expense);
    ref.invalidateSelf();
    await future;
  }

  Future<void> delete(String id) async {
    await _repo.deleteExpense(id);
    ref.invalidateSelf();
    await future;
  }
}
