import 'package:new_invoice_generator/models/monthly_bar.dart';

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

