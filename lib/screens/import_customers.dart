import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:new_invoice_generator/providers/customer.dart';
import 'package:new_invoice_generator/services/customer_import.dart';

class ImportCustomersScreen extends ConsumerStatefulWidget {
  const ImportCustomersScreen({super.key});

  @override
  ConsumerState<ImportCustomersScreen> createState() =>
      _ImportCustomersScreenState();
}

class _ImportCustomersScreenState extends ConsumerState<ImportCustomersScreen> {
  List<ParsedCustomer> _parsed = [];
  bool _loading = false;
  bool _importing = false;
  String? _error;
  String? _fileName;

  Future<void> _pickFile() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
      );
      if (result == null || result.files.isEmpty) {
        setState(() => _loading = false);
        return;
      }
      final file = result.files.first;
      // v12: read bytes on demand instead of the deprecated `bytes`/`withData`
      final Uint8List bytes = await file.readAsBytes();
      if (bytes.isEmpty) {
        setState(() {
          _error = 'Could not read the file.';
          _loading = false;
        });
        return;
      }
      final parsed = CustomerImportService.parseXlsx(bytes);
      setState(() {
        _parsed = parsed;
        _fileName = file.name;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to read spreadsheet: $e';
        _loading = false;
      });
    }
  }

  Future<void> _import() async {
    final selected = _parsed
        .where((p) => p.selected)
        .map((p) => p.customer)
        .toList();
    if (selected.isEmpty) return;
    setState(() => _importing = true);
    try {
      final count = await ref.read(customerProvider.notifier).addMany(selected);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(
            SnackBar(
              content: Text('Imported $count customer${count == 1 ? '' : 's'}'),
            ),
          );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _importing = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Import failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final selectedCount = _parsed.where((p) => p.selected).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Import Customers'),
        actions: [
          if (_parsed.isNotEmpty)
            TextButton(
              onPressed: () => setState(() {
                final allSelected = _parsed.every((p) => p.selected);
                for (final p in _parsed) {
                  p.selected = !allSelected;
                }
              }),
              child: Text(
                _parsed.every((p) => p.selected)
                    ? 'Deselect all'
                    : 'Select all',
              ),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _parsed.isEmpty
          ? _EmptyState(error: _error, onPick: _pickFile)
          : Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  color: cs.surfaceContainerHigh,
                  child: Text(
                    '${_parsed.length} found in "${_fileName ?? ''}". '
                    'Review and tap Import.',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: _parsed.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 6),
                    itemBuilder: (context, i) {
                      final p = _parsed[i];
                      final c = p.customer;
                      return Card(
                        child: CheckboxListTile(
                          value: p.selected,
                          onChanged: (v) =>
                              setState(() => p.selected = v ?? false),
                          title: Text(
                            c.name,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (c.email.isNotEmpty) Text(c.email),
                              if (c.phone.isNotEmpty)
                                Text(
                                  c.phone,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              if (c.address.isNotEmpty)
                                Text(
                                  c.address.singleLine,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: cs.onSurface.withAlpha(140),
                                  ),
                                ),
                              for (final w in p.warnings)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.warning_amber_rounded,
                                        size: 12,
                                        color: Colors.orange,
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          w,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: Colors.orange,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          isThreeLine: true,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
      bottomNavigationBar: _parsed.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: FilledButton.icon(
                  onPressed: (selectedCount == 0 || _importing)
                      ? null
                      : _import,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                  ),
                  icon: _importing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.download_done),
                  label: Text(
                    _importing
                        ? 'Importing…'
                        : 'Import $selectedCount customer${selectedCount == 1 ? '' : 's'}',
                  ),
                ),
              ),
            ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String? error;
  final VoidCallback onPick;
  const _EmptyState({required this.error, required this.onPick});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.upload_file_outlined,
              size: 64,
              color: cs.onSurface.withAlpha(70),
            ),
            const SizedBox(height: 16),
            const Text(
              'Import from spreadsheet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Select an .xlsx export (e.g. from Cognito Forms). '
              'Columns are matched by name, and provinces, countries, and '
              'phone numbers are cleaned up automatically.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: cs.onSurface.withAlpha(150),
              ),
            ),
            if (error != null) ...[
              const SizedBox(height: 16),
              Text(
                error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red, fontSize: 13),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onPick,
              icon: const Icon(Icons.folder_open),
              label: const Text('Choose .xlsx file'),
            ),
          ],
        ),
      ),
    );
  }
}
