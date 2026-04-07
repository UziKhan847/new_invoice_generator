import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:new_invoice_generator/models/invoice.dart';
import 'package:new_invoice_generator/models/invoice_filter.dart';
import 'package:new_invoice_generator/providers/invoice.dart';

class InvoiceFilterNotifier extends Notifier<InvoiceFilter> {
  @override
  InvoiceFilter build() => const InvoiceFilter();

  void update(InvoiceFilter f) => state = f;
  void clear() => state = const InvoiceFilter();
}

final invoiceFilterProvider =
    NotifierProvider<InvoiceFilterNotifier, InvoiceFilter>(
  InvoiceFilterNotifier.new,
);

/// Derived provider: filtered + sorted invoice list
final filteredInvoicesProvider = Provider<AsyncValue<List<Invoice>>>((ref) {
  final invoicesAsync = ref.watch(invoiceProvider);
  final filter = ref.watch(invoiceFilterProvider);

  return invoicesAsync.whenData((invoices) {
    // Sort newest first, then filter
    final sorted = [...invoices]
      ..sort((a, b) => b.issueDate.compareTo(a.issueDate));
    var result = sorted.where((inv) {
      if (filter.customerId != null && inv.customerId != filter.customerId) {
        return false;
      }
      if (filter.senderEmployeeId != null &&
          inv.senderEmployeeId != filter.senderEmployeeId) {
        return false;
      }
      if (filter.serviceName != null) {
        final hasService = inv.items.any((item) =>
            item.description.toLowerCase().contains(filter.serviceName!.toLowerCase()));
        if (!hasService) return false;
      }
      if (filter.month != null && inv.issueDate.month != filter.month) {
        return false;
      }
      if (filter.year != null && inv.issueDate.year != filter.year) {
        return false;
      }
      if (filter.isPaid != null && inv.isPaid != filter.isPaid) {
        return false;
      }
      return true;
    }).toList();

    return result;
  });
});