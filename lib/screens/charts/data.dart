import 'package:new_invoice_generator/models/invoice.dart';
import 'package:new_invoice_generator/models/monthly_bar.dart';

const _monthNames = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// Immutable result of aggregating invoices for chart display.
class ChartData {
  final List<MonthlyBar> revenueBars;
  final List<MonthlyBar> countBars;
  final double paid;
  final double unpaid;
  final double totalRevenue;
  final int totalCount;

  const ChartData({
    required this.revenueBars,
    required this.countBars,
    required this.paid,
    required this.unpaid,
    required this.totalRevenue,
    required this.totalCount,
  });

  static ChartData fromInvoices({
    required List<Invoice> invoices,
    int? filterYear,
    String? filterCustomerId,
    String? filterSenderId,
  }) {
    final filtered = invoices.where((inv) {
      if (filterYear != null && inv.issueDate.year != filterYear) return false;
      if (filterCustomerId != null && inv.customerId != filterCustomerId) {
        return false;
      }
      if (filterSenderId != null && inv.senderEmployeeId != filterSenderId) {
        return false;
      }
      return true;
    }).toList();

    final Map<String, double> revenueByMonth = {};
    final Map<String, int> countByMonth = {};
    double paid = 0, unpaid = 0, totalRevenue = 0;

    for (final inv in filtered) {
      final key =
          '${inv.issueDate.year}-${inv.issueDate.month.toString().padLeft(2, '0')}';
      if (inv.isPaid) {
        revenueByMonth[key] = (revenueByMonth[key] ?? 0) + inv.total;
        paid += inv.total;
        totalRevenue += inv.total;
      } else {
        unpaid += inv.total;
      }
      countByMonth[key] = (countByMonth[key] ?? 0) + 1;
    }

    final sortedKeys =
        {...revenueByMonth.keys, ...countByMonth.keys}.toList()..sort();

    MonthlyBar bar(String k, {required bool isRevenue}) {
      final parts = k.split('-');
      final monthIdx = int.parse(parts[1]) - 1;
      final label = filterYear != null
          ? _monthNames[monthIdx]
          : '${_monthNames[monthIdx]} ${parts[0]}';
      return MonthlyBar(
        label: label,
        value: isRevenue
            ? (revenueByMonth[k] ?? 0)
            : (countByMonth[k] ?? 0).toDouble(),
        count: countByMonth[k] ?? 0,
      );
    }

    return ChartData(
      revenueBars: sortedKeys.map((k) => bar(k, isRevenue: true)).toList(),
      countBars: sortedKeys.map((k) => bar(k, isRevenue: false)).toList(),
      paid: paid,
      unpaid: unpaid,
      totalRevenue: totalRevenue,
      totalCount: filtered.length,
    );
  }

  String titleFor(int index) {
    switch (index) {
      case 0:  return 'Monthly Revenue';
      case 1:  return 'Paid vs Unpaid';
      default: return 'Invoice Count';
    }
  }

  String subtitleFor(int index) {
    switch (index) {
      case 0:
        return 'Total paid: \$${totalRevenue.toStringAsFixed(2)}';
      case 1:
        final total = paid + unpaid;
        final pct =
            total == 0 ? '0' : (paid / total * 100).toStringAsFixed(1);
        return '$pct% collected  ·  \$${unpaid.toStringAsFixed(2)} outstanding';
      default:
        return '$totalCount invoice${totalCount == 1 ? '' : 's'}';
    }
  }
}