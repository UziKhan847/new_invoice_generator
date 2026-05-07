import 'package:new_invoice_generator/main.dart';

class AnalyticsRepository {
  /// Monthly revenue for the past N months — queries full DB via view
  Future<List<Map<String, dynamic>>> monthlyRevenue(
    String companyId, {
    int months = 12,
  }) async {
    final cutoff = DateTime.now().subtract(Duration(days: months * 31));
    final response = await supabase
        .from('monthly_revenue')
        .select()
        .eq('company_id', companyId)
        .gte('month', cutoff.toIso8601String().split('T')[0])
        .order('month', ascending: true);
    return List<Map<String, dynamic>>.from(response);
  }

  /// Paid vs unpaid totals — full table scan via view
  Future<Map<String, double>> paidVsUnpaid(String companyId) async {
    final response = await supabase
        .from('invoices')
        .select('total, is_paid')
        .eq('company_id', companyId)
        .eq('is_private', false);

    double paid = 0;
    double unpaid = 0;
    for (final row in response) {
      final amount = (row['total'] as num).toDouble();
      if (row['is_paid'] == true) {
        paid += amount;
      } else {
        unpaid += amount;
      }
    }
    return {'paid': paid, 'unpaid': unpaid};
  }

  /// Invoice count per month for line chart
  Future<List<Map<String, dynamic>>> invoiceCountByMonth(
    String companyId, {
    int months = 12,
  }) async {
    final cutoff = DateTime.now().subtract(Duration(days: months * 31));
    final response = await supabase
        .from('monthly_revenue')
        .select('month, invoice_count, paid_count, unpaid_count')
        .eq('company_id', companyId)
        .gte('month', cutoff.toIso8601String().split('T')[0])
        .order('month', ascending: true);
    return List<Map<String, dynamic>>.from(response);
  }

  /// Summary stats — all from DB
  Future<Map<String, dynamic>> summaryStats(String companyId) async {
    final now = DateTime.now();
    final monthStart = DateTime(
      now.year,
      now.month,
      1,
    ).toIso8601String().split('T')[0];
    final yearStart = DateTime(now.year, 1, 1).toIso8601String().split('T')[0];

    final all = await supabase
        .from('invoices')
        .select('total, is_paid, issue_date')
        .eq('company_id', companyId)
        .eq('is_private', false);

    double totalRevenue = 0;
    double monthRevenue = 0;
    double yearRevenue = 0;
    double unpaid = 0;
    int overdueCount = 0;
    final today = now.toIso8601String().split('T')[0];

    for (final row in all) {
      final amount = (row['total'] as num).toDouble();
      final isPaid = row['is_paid'] == true;
      final issueDate = row['issue_date'] as String? ?? '';

      if (isPaid) {
        totalRevenue += amount;
        if (issueDate.compareTo(monthStart) >= 0) monthRevenue += amount;
        if (issueDate.compareTo(yearStart) >= 0) yearRevenue += amount;
      } else {
        unpaid += amount;
        if (issueDate.compareTo(today) < 0) overdueCount++;
      }
    }

    return {
      'totalRevenue': totalRevenue,
      'monthRevenue': monthRevenue,
      'yearRevenue': yearRevenue,
      'unpaid': unpaid,
      'overdueCount': overdueCount,
      'totalInvoices': all.length,
    };
  }
}
