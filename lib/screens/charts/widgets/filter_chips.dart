import 'package:flutter/material.dart';

class ChartFilterChips extends StatelessWidget {
  final int? filterYear;
  final String? filterCustomerName;
  final String? filterSenderName;
  final VoidCallback onRemoveYear;
  final VoidCallback onRemoveCustomer;
  final VoidCallback onRemoveSender;

  const ChartFilterChips({
    super.key,
    required this.filterYear,
    required this.filterCustomerName,
    required this.filterSenderName,
    required this.onRemoveYear,
    required this.onRemoveCustomer,
    required this.onRemoveSender,
  });

  bool get hasActiveFilter =>
      filterYear != null ||
      filterCustomerName != null ||
      filterSenderName != null;

  @override
  Widget build(BuildContext context) {
    if (!hasActiveFilter) return const SizedBox.shrink();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Row(
        children: [
          if (filterYear != null)
            _Chip(label: '$filterYear', onRemove: onRemoveYear),
          if (filterCustomerName != null)
            _Chip(label: filterCustomerName!, onRemove: onRemoveCustomer),
          if (filterSenderName != null)
            _Chip(label: filterSenderName!, onRemove: onRemoveSender),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;
  const _Chip({required this.label, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Chip(
        label: Text(label, style: const TextStyle(fontSize: 12)),
        deleteIcon: const Icon(Icons.close, size: 14),
        onDeleted: onRemove,
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}