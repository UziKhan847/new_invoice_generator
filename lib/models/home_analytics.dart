import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:new_invoice_generator/models/monthly_bar.dart';
import 'package:new_invoice_generator/providers/company.dart';
import 'package:new_invoice_generator/providers/invoice/invoice.dart';
import 'package:new_invoice_generator/repositories/analytics.dart';

class HomeAnalytics {
  final double totalRevenue;
  final double monthRevenue;
  final double yearRevenue;
  final double unpaid;
  final int overdueCount;
  final int totalInvoices;
  final List<MonthlyBar> monthlyBars;
  final List<MonthlyBar> invoiceCountBars;
  final double paidAmount;
  final double unpaidAmount;

  HomeAnalytics({
    required this.totalRevenue,
    required this.monthRevenue,
    required this.yearRevenue,
    required this.unpaid,
    required this.overdueCount,
    required this.totalInvoices,
    required this.monthlyBars,
    required this.invoiceCountBars,
    required this.paidAmount,
    required this.unpaidAmount,
  });
}

class HomeAnalyticsNotifier extends AsyncNotifier<HomeAnalytics> {
  final _repo = AnalyticsRepository();

  @override
  Future<HomeAnalytics> build() async {
    // Watch invoiceProvider so analytics auto-rebuilds when invoices change
    ref.watch(invoiceProvider);
    final company = await ref.read(companyProvider.future);
    final companyId = company['id'] as String;

    final results = await Future.wait([
      _repo.summaryStats(companyId),
      _repo.monthlyRevenue(companyId),
      _repo.invoiceCountByMonth(companyId),
      _repo.paidVsUnpaid(companyId),
    ]);

    final stats = results[0] as Map<String, dynamic>;
    final monthly = results[1] as List<Map<String, dynamic>>;
    final counts = results[2] as List<Map<String, dynamic>>;
    final paidUnpaid = results[3] as Map<String, double>;

    final monthNames = [
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
    ];

    final bars = monthly.map((row) {
      final month = DateTime.parse(row['month']);
      return MonthlyBar(
        label: monthNames[month.month - 1],
        value: (row['paid_revenue'] as num?)?.toDouble() ?? 0,
        count: (row['invoice_count'] as num?)?.toInt() ?? 0,
      );
    }).toList();

    final countBars = counts.map((row) {
      final month = DateTime.parse(row['month']);
      return MonthlyBar(
        label: monthNames[month.month - 1],
        value: (row['invoice_count'] as num?)?.toDouble() ?? 0,
        count: (row['invoice_count'] as num?)?.toInt() ?? 0,
      );
    }).toList();

    return HomeAnalytics(
      totalRevenue: (stats['totalRevenue'] as num).toDouble(),
      monthRevenue: (stats['monthRevenue'] as num).toDouble(),
      yearRevenue: (stats['yearRevenue'] as num).toDouble(),
      unpaid: (stats['unpaid'] as num).toDouble(),
      overdueCount: stats['overdueCount'] as int,
      totalInvoices: stats['totalInvoices'] as int,
      monthlyBars: bars,
      invoiceCountBars: countBars,
      paidAmount: paidUnpaid['paid'] ?? 0,
      unpaidAmount: paidUnpaid['unpaid'] ?? 0,
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => build());
  }
}

final homeAnalyticsProvider =
    AsyncNotifierProvider<HomeAnalyticsNotifier, HomeAnalytics>(
      HomeAnalyticsNotifier.new,
    );
