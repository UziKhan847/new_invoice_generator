import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:new_invoice_generator/main.dart';
import 'package:new_invoice_generator/providers/company.dart';
import 'package:new_invoice_generator/widgets/primary_button.dart';

class CompanyProfileScreen extends ConsumerStatefulWidget {
  const CompanyProfileScreen({super.key});

  @override
  ConsumerState<CompanyProfileScreen> createState() =>
      _CompanyProfileScreenState();
}

class _CompanyProfileScreenState extends ConsumerState<CompanyProfileScreen> {
  final nameController = TextEditingController();
  final addressController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  bool _initialized = false; // Fixed: only initialize controllers once
  bool _saving = false;

  @override
  void dispose() {
    nameController.dispose();
    addressController.dispose();
    emailController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final companyAsync = ref.watch(companyProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Company Profile')),
      body: companyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (company) {
          // Fixed: only set controller text once, not on every rebuild
          if (!_initialized) {
            nameController.text = company['name'] ?? '';
            addressController.text = company['address'] ?? '';
            emailController.text = company['email'] ?? '';
            phoneController.text = company['phone'] ?? '';
            _initialized = true;
          }

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const SizedBox(height: 16),
                TextField(
                  controller: nameController,
                  decoration:
                      const InputDecoration(labelText: 'Company Name'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: addressController,
                  decoration: const InputDecoration(labelText: 'Address'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(labelText: 'Phone'),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 24),
                PrimaryButton(
                  text: _saving ? 'Saving...' : 'Save',
                  onPressed: _saving
                      ? () {}
                      : () async {
                          setState(() => _saving = true);
                          try {
                            await supabase
                                .from('companies')
                                .update({
                                  'name': nameController.text.trim(),
                                  'address': addressController.text.trim(),
                                  'email': emailController.text.trim(),
                                  'phone': phoneController.text.trim(),
                                })
                                .eq('id', company['id']);
                            // Refresh provider
                            ref.invalidate(companyProvider);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Company profile saved')),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error: $e')),
                              );
                            }
                          } finally {
                            if (mounted) setState(() => _saving = false);
                          }
                        },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}