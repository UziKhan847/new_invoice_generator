import 'package:new_invoice_generator/main.dart';
import 'package:new_invoice_generator/models/expense.dart';

class ExpenseRepository {
  Future<List<Expense>> fetchExpenses(
    String companyId, {
    DateTime? from,
    DateTime? to,
  }) async {
    // Filters must be applied before .order() — order() returns a
    // PostgrestTransformBuilder which no longer has filter methods
    var query = supabase.from('expenses').select().eq('company_id', companyId);

    if (from != null) {
      query = query.gte('date', from.toIso8601String().split('T')[0]);
    }
    if (to != null) {
      query = query.lte('date', to.toIso8601String().split('T')[0]);
    }

    final response = await query.order('date', ascending: false);
    return response.map<Expense>((j) => Expense.fromJson(j)).toList();
  }

  Future<void> addExpense(String companyId, Expense expense) async {
    await supabase.from('expenses').insert(expense.toInsertMap(companyId));
  }

  Future<void> updateExpense(Expense expense) async {
    await supabase
        .from('expenses')
        .update({
          'description': expense.description,
          'category': expense.category,
          'date': expense.date.toIso8601String().split('T')[0],
          'amount': expense.amount,
          'tax_amount': expense.taxAmount,
          'vendor': expense.vendor,
          'notes': expense.notes,
        })
        .eq('id', expense.id!);
  }

  Future<void> deleteExpense(String id) async {
    await supabase.from('expenses').delete().eq('id', id);
  }
}
