import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:new_invoice_generator/providers/invoice/invoice.dart';

class AnalyticsData {
  final double totalRevenue;
  final double monthlyRevenue;
  final double yearlyRevenue;
  final double unpaidTotal;

  AnalyticsData({
    required this.totalRevenue,
    required this.monthlyRevenue,
    required this.yearlyRevenue,
    required this.unpaidTotal,
  });

  factory AnalyticsData.empty() => AnalyticsData(
        totalRevenue: 0,
        monthlyRevenue: 0,
        yearlyRevenue: 0,
        unpaidTotal: 0,
      );
}

class AnalyticsNotifier extends AsyncNotifier<AnalyticsData> {
  @override
  Future<AnalyticsData> build() async {
    final invoicesAsync = ref.watch(invoiceProvider);

    return invoicesAsync.when(
      loading: () => AnalyticsData.empty(),
      error: (_, _) => AnalyticsData.empty(),
      data: (invoices) {
        final now = DateTime.now();
        double total = 0;
        double monthly = 0;
        double yearly = 0;
        double unpaid = 0;

        for (final inv in invoices) {
          if (inv.isPaid) {
            total += inv.total;
            if (inv.issueDate.month == now.month &&
                inv.issueDate.year == now.year) {
              monthly += inv.total;
            }
            if (inv.issueDate.year == now.year) {
              yearly += inv.total;
            }
          } else {
            unpaid += inv.total;
          }
        }

        return AnalyticsData(
          totalRevenue: total,
          monthlyRevenue: monthly,
          yearlyRevenue: yearly,
          unpaidTotal: unpaid,
        );
      },
    );
  }
}

final analyticsProvider =
    AsyncNotifierProvider<AnalyticsNotifier, AnalyticsData>(
  AnalyticsNotifier.new,
);