import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:new_invoice_generator/app_theme.dart';
import 'package:new_invoice_generator/models/customer.dart';
import 'package:new_invoice_generator/providers/customer.dart';
import 'package:new_invoice_generator/providers/invoice/invoice.dart';
import 'package:new_invoice_generator/desktop/widgets.dart';
import 'package:new_invoice_generator/widgets/add_customer_dialog.dart';

/// Per-customer billing aggregates derived from invoices.
class _Aggregate {
  final int count;
  final double totalBilled;
  const _Aggregate(this.count, this.totalBilled);
}

class DesktopCustomers extends ConsumerStatefulWidget {
  const DesktopCustomers({super.key});

  @override
  ConsumerState<DesktopCustomers> createState() => _DesktopCustomersState();
}

class _DesktopCustomersState extends ConsumerState<DesktopCustomers> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final p = AppColors.of(context);
    final customersAsync = ref.watch(customerProvider);

    // Build aggregates from invoices, keyed by customerId.
    final invoices = ref.watch(invoiceProvider).asData?.value ?? [];
    final agg = <String, _Aggregate>{};
    for (final inv in invoices) {
      final id = inv.customerId;
      if (id == null) continue;
      final prev = agg[id] ?? const _Aggregate(0, 0);
      agg[id] = _Aggregate(prev.count + 1, prev.totalBilled + inv.total);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        customersAsync.when(
          loading: () => const DesktopTopBar(title: 'Customers'),
          error: (_, _) => const DesktopTopBar(title: 'Customers'),
          data: (list) => DesktopTopBar(
            title: 'Customers',
            subtitle: '${list.length} customer${list.length == 1 ? '' : 's'}',
            actions: [
              DesktopSearchField(
                hint: 'Search by name or email',
                onChanged: (v) => setState(() => _query = v),
              ),
              const SizedBox(width: 12),
              DesktopPrimaryButton(
                icon: Icons.add,
                label: 'Add Customer',
                onTap: () => showAddCustomerSheet(context),
              ),
            ],
          ),
        ),
        Expanded(
          child: customersAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (all) {
              final q = _query.toLowerCase();
              final customers = _query.isEmpty
                  ? all
                  : all.where((c) {
                      return c.name.toLowerCase().contains(q) ||
                          c.email.toLowerCase().contains(q);
                    }).toList();

              return Padding(
                padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
                child: DesktopPanel(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      // Header row
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 13,
                        ),
                        decoration: BoxDecoration(
                          color: p.surfaceAlt,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(AppRadii.card),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(flex: 5, child: _h(context, 'CUSTOMER')),
                            Expanded(flex: 3, child: _h(context, 'PHONE')),
                            Expanded(flex: 3, child: _h(context, 'TAGS')),
                            Expanded(
                              flex: 2,
                              child: _h(context, 'INVOICES', right: true),
                            ),
                            Expanded(
                              flex: 3,
                              child: _h(context, 'TOTAL BILLED', right: true),
                            ),
                            const SizedBox(width: 28),
                          ],
                        ),
                      ),
                      Expanded(
                        child: customers.isEmpty
                            ? Center(
                                child: Text(
                                  _query.isEmpty
                                      ? 'No customers yet'
                                      : 'No matches',
                                  style: AppTypography.bodyMuted(
                                    p.textTertiary,
                                  ),
                                ),
                              )
                            : ListView.separated(
                                itemCount: customers.length,
                                separatorBuilder: (_, _) =>
                                    Divider(height: 1, color: p.border),
                                itemBuilder: (context, i) {
                                  final c = customers[i];
                                  return _CustomerRow(
                                    customer: c,
                                    aggregate:
                                        agg[c.id] ?? const _Aggregate(0, 0),
                                    onTap: () => showAddCustomerSheet(
                                      context,
                                      existing: c,
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _h(BuildContext context, String t, {bool right = false}) {
    final p = AppColors.of(context);
    return Text(
      t,
      textAlign: right ? TextAlign.right : TextAlign.left,
      style: AppTypography.label(p.textTertiary),
    );
  }
}

class _CustomerRow extends StatelessWidget {
  final Customer customer;
  final _Aggregate aggregate;
  final VoidCallback onTap;
  const _CustomerRow({
    required this.customer,
    required this.aggregate,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = AppColors.of(context);
    final c = customer;

    // Stable tinted avatar color from the name.
    final tones = [
      (p.primaryTint, p.primary),
      (p.successBg, p.successText),
      (p.purpleBg, p.purple),
      (p.warningBg, p.warningText),
    ];
    final tone = tones[c.name.hashCode.abs() % tones.length];

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: [
              // Customer (avatar + name + email)
              Expanded(
                flex: 5,
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: tone.$1,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        c.name.isNotEmpty ? c.name[0].toUpperCase() : '?',
                        style: AppTypography.title(
                          tone.$2,
                        ).copyWith(fontSize: 16),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            c.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.title(
                              p.ink,
                            ).copyWith(fontSize: 15),
                          ),
                          Text(
                            c.email.isNotEmpty ? c.email : 'No email on file',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.caption(
                              c.email.isNotEmpty
                                  ? p.textSecondary
                                  : p.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Phone
              Expanded(
                flex: 3,
                child: Text(
                  c.phone.isNotEmpty ? c.phone : '—',
                  style: AppTypography.body(
                    c.phone.isNotEmpty ? p.ink : p.textTertiary,
                  ).copyWith(fontSize: 13),
                ),
              ),
              // Tags
              Expanded(
                flex: 3,
                child: c.tags.isEmpty
                    ? Text(
                        '—',
                        style: AppTypography.body(
                          p.textTertiary,
                        ).copyWith(fontSize: 13),
                      )
                    : Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: c.tags
                            .take(3)
                            .map(
                              (t) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: p.primaryTint,
                                  borderRadius: BorderRadius.circular(
                                    AppRadii.pill,
                                  ),
                                ),
                                child: Text(
                                  t,
                                  style: AppTypography.caption(
                                    p.primary,
                                  ).copyWith(fontSize: 11),
                                ),
                              ),
                            )
                            .toList(),
                      ),
              ),
              // Invoice count
              Expanded(
                flex: 2,
                child: Text(
                  '${aggregate.count}',
                  textAlign: TextAlign.right,
                  style: AppTypography.title(p.ink).copyWith(fontSize: 14),
                ),
              ),
              // Total billed
              Expanded(
                flex: 3,
                child: Text(
                  '\$${aggregate.totalBilled.toStringAsFixed(2)}',
                  textAlign: TextAlign.right,
                  style: AppTypography.title(p.ink).copyWith(fontSize: 14),
                ),
              ),
              SizedBox(
                width: 28,
                child: Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: p.textTertiary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
