import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:new_invoice_generator/models/invoice/event.dart';
import 'package:new_invoice_generator/repositories/invoice_event.dart';

/// Loads the activity log for a single invoice.
/// Riverpod 3 family: the Notifier extends the plain [AsyncNotifier], captures
/// the family argument via its constructor, and [build] takes no parameters.
class InvoiceEventsNotifier extends AsyncNotifier<List<InvoiceEvent>> {
  InvoiceEventsNotifier(this.invoiceId);
  final String invoiceId;

  final _repo = InvoiceEventRepository();

  @override
  Future<List<InvoiceEvent>> build() async {
    if (invoiceId.isEmpty) return [];
    return _repo.fetchForInvoice(invoiceId);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repo.fetchForInvoice(invoiceId));
  }
}

final invoiceEventsProvider = AsyncNotifierProvider.family<
    InvoiceEventsNotifier, List<InvoiceEvent>, String>(
  InvoiceEventsNotifier.new,
);