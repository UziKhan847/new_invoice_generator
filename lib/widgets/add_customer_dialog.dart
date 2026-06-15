import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:new_invoice_generator/models/address.dart';
import 'package:new_invoice_generator/models/customer.dart';
import 'package:new_invoice_generator/providers/customer.dart';
import 'package:new_invoice_generator/utils/validators.dart';
import 'package:new_invoice_generator/screens/widgets/address_form.dart';
import 'package:new_invoice_generator/screens/widgets/phone_field.dart';

/// Add or edit a customer. Pass [existing] to edit.
/// Presented as a scrollable bottom sheet.
class AddCustomerSheet extends ConsumerStatefulWidget {
  final Customer? existing;
  const AddCustomerSheet({super.key, this.existing});

  @override
  ConsumerState<AddCustomerSheet> createState() => _AddCustomerSheetState();
}

class _AddCustomerSheetState extends ConsumerState<AddCustomerSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _email;
  String _phone = '';
  late Address _address;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?.name ?? '');
    _email = TextEditingController(text: e?.email ?? '');
    _phone = e?.phone ?? '';
    _address = e?.address ?? const Address();
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final notifier = ref.read(customerProvider.notifier);
      if (widget.existing == null) {
        await notifier.addCustomer(
          Customer(
            id: '',
            name: _name.text.trim(),
            email: _email.text.trim(),
            phone: _phone,
            address: _address,
          ),
        );
      } else {
        await notifier.updateCustomer(
          widget.existing!.copyWith(
            name: _name.text.trim(),
            email: _email.text.trim(),
            phone: _phone,
            address: _address,
          ),
        );
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, bottom + 20),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                isEdit ? 'Edit Customer' : 'Add Customer',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Name *',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (v) => Validators.required(v, field: 'Name'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                validator: (v) => Validators.email(v, required: false),
              ),
              const SizedBox(height: 12),
              PhoneField(
                initial: _phone,
                label: 'Phone',
                onChanged: (v) => _phone = v,
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Address',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
              const SizedBox(height: 10),
              AddressForm(initial: _address, onChanged: (a) => _address = a),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _loading ? null : _save,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(isEdit ? 'Save Changes' : 'Add Customer'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Helper to show the sheet.
Future<void> showAddCustomerSheet(BuildContext context, {Customer? existing}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => AddCustomerSheet(existing: existing),
  );
}

// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:new_invoice_generator/models/customer.dart';
// import 'package:new_invoice_generator/providers/customer.dart';

// class AddCustomerDialog extends ConsumerStatefulWidget {
//   const AddCustomerDialog({super.key});

//   @override
//   ConsumerState<AddCustomerDialog> createState() => _AddCustomerDialogState();
// }

// class _AddCustomerDialogState extends ConsumerState<AddCustomerDialog> {
//   final _name = TextEditingController();
//   final _email = TextEditingController();
//   final _phone = TextEditingController();
//   final _address = TextEditingController();
//   bool _loading = false;

//   @override
//   void dispose() {
//     _name.dispose();
//     _email.dispose();
//     _phone.dispose();
//     _address.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return AlertDialog(
//       title: const Text('Add Customer'),
//       content: SingleChildScrollView(
//         child: Column(
//           mainAxisSize: .min,
//           children: [
//             TextField(
//               controller: _name,
//               decoration: const InputDecoration(labelText: 'Name'),
//             ),
//             const SizedBox(height: 8),
//             TextField(
//               controller: _email,
//               decoration: const InputDecoration(labelText: 'Email'),
//               keyboardType: .emailAddress,
//             ),
//             const SizedBox(height: 8),
//             TextField(
//               controller: _phone,
//               decoration: const InputDecoration(labelText: 'Phone'),
//               keyboardType: .phone,
//             ),
//             const SizedBox(height: 8),
//             TextField(
//               controller: _address,
//               decoration: const InputDecoration(labelText: 'Address'),
//             ),
//           ],
//         ),
//       ),
//       actions: [
//         TextButton(
//           onPressed: () => Navigator.pop(context),
//           child: const Text('Cancel'),
//         ),
//         ElevatedButton(
//           onPressed: _loading
//               ? null
//               : () async {
//                   if (_name.text.trim().isEmpty) return;
//                   setState(() => _loading = true);
//                   try {
//                     await ref
//                         .read(customerProvider.notifier)
//                         .addCustomer(
//                           Customer(
//                             id: '',
//                             name: _name.text.trim(),
//                             email: _email.text.trim(),
//                             address: _address.text.trim(),
//                             phone: _phone.text.trim(),
//                           ),
//                         );
//                     if (context.mounted) Navigator.pop(context);
//                   } catch (e) {
//                     if (!context.mounted) return;
//                     ScaffoldMessenger.of(
//                       context,
//                     ).showSnackBar(SnackBar(content: Text('Error: $e')));
//                   } finally {
//                     if (mounted) setState(() => _loading = false);
//                   }
//                 },
//           child: _loading
//               ? const SizedBox(
//                   height: 16,
//                   width: 16,
//                   child: CircularProgressIndicator(strokeWidth: 2),
//                 )
//               : const Text('Save'),
//         ),
//       ],
//     );
//   }
// }
