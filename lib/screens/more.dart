import 'dart:io';
import 'dart:typed_data';
import 'package:custom_image_crop/custom_image_crop.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:new_invoice_generator/main.dart';
import 'package:new_invoice_generator/providers/company.dart';
import 'package:new_invoice_generator/providers/theme.dart';
import 'package:new_invoice_generator/screens/company_profile.dart';
import 'package:new_invoice_generator/screens/employees.dart';
import 'package:new_invoice_generator/screens/recurring_invoices.dart';
import 'package:new_invoice_generator/screens/services.dart';
import 'package:new_invoice_generator/services/storage.dart';

class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final companyAsync = ref.watch(companyProvider);
    final isDark = ref.watch(themeProvider) == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('More')),
      body: ListView(
        padding: const .all(16),
        children: [
          // Company card with logo upload
          companyAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
            data: (company) => Card(
              child: Padding(
                padding: const .all(16),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () async {
                        // Step 1: choose source
                        final source = await showModalBottomSheet<ImageSource>(
                          context: context,
                          builder: (_) => SafeArea(
                            child: Column(
                              mainAxisSize: .min,
                              children: [
                                ListTile(
                                  leading: const Icon(Icons.photo_library),
                                  title: const Text('Choose from gallery'),
                                  onTap: () => Navigator.pop(
                                    context,
                                    ImageSource.gallery,
                                  ),
                                ),
                                ListTile(
                                  leading: const Icon(Icons.camera_alt),
                                  title: const Text('Take a photo'),
                                  onTap: () => Navigator.pop(
                                    context,
                                    ImageSource.camera,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                        if (source == null) return;

                        // Step 2: pick image
                        final ImagePicker picker = ImagePicker();
                        final XFile? picked = await picker.pickImage(
                          source: source,
                          imageQuality: 90,
                          maxWidth: 1000,
                          maxHeight: 1000,
                        );
                        if (picked == null) return;

                        // Step 3: crop with pure-Flutter cropper (no native setup needed)
                        if (!context.mounted) return;
                        final croppedBytes = await Navigator.push<Uint8List?>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => _CropScreen(imagePath: picked.path),
                          ),
                        );
                        if (croppedBytes == null) return;

                        // Step 4: save cropped bytes to temp file and upload
                        try {
                          final dir = await getTemporaryDirectory();
                          final tmpFile = File('${dir.path}/logo_crop.png');
                          await tmpFile.writeAsBytes(croppedBytes);

                          final storageSvc = StorageService();
                          final signedUrl = await storageSvc.uploadLogo(
                            tmpFile,
                            company['id'] as String,
                          );
                          // Extract storage path from the signed URL isn't reliable
                          // — we stored it in the service, read it from the path directly
                          final uid = supabase.auth.currentUser!.id;
                          final storagePath = '$uid/logos/${company['id']}.png';
                          await ref
                              .read(companyProvider.notifier)
                              .updateLogo(signedUrl, storagePath);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Logo updated!')),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Upload failed: $e')),
                            );
                          }
                        }
                      },
                      child: Stack(
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: .all(color: cs.outline.withAlpha(80)),
                              color: cs.surfaceContainerHighest,
                            ),
                            child: company['logo_url'] != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(11),
                                    child: Image.network(
                                      company['logo_url'] as String,
                                      key: ValueKey(company['logo_url']),
                                      fit: BoxFit.cover,
                                      loadingBuilder: (_, child, progress) =>
                                          progress == null
                                          ? child
                                          : const Center(
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            ),
                                      errorBuilder: (_, _, _) => Icon(
                                        Icons.business,
                                        size: 36,
                                        color: cs.onSurfaceVariant,
                                      ),
                                    ),
                                  )
                                : Icon(
                                    Icons.business,
                                    size: 36,
                                    color: cs.onSurfaceVariant,
                                  ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const .all(3),
                              decoration: BoxDecoration(
                                color: cs.primary,
                                shape: .circle,
                              ),
                              child: Icon(
                                Icons.camera_alt,
                                size: 12,
                                color: cs.onPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: .start,
                        children: [
                          Text(
                            company['name'] as String? ?? 'My Company',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: .bold,
                            ),
                          ),
                          if (company['email'] != null)
                            Text(
                              company['email'] as String,
                              style: theme.textTheme.bodySmall,
                            ),
                          const SizedBox(height: 4),
                          Text(
                            'Tap logo to change',
                            style: TextStyle(
                              fontSize: 11,
                              color: cs.onSurface.withAlpha(100),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          _SectionHeader(title: 'Settings'),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Dark Mode'),
                  secondary: Icon(isDark ? Icons.dark_mode : Icons.light_mode),
                  value: isDark,
                  onChanged: (_) => ref.read(themeProvider.notifier).toggle(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          _SectionHeader(title: 'Business'),
          Card(
            child: Column(
              children: [
                _NavTile(
                  icon: Icons.business_outlined,
                  label: 'Company Profile',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CompanyProfileScreen(),
                    ),
                  ),
                ),
                const Divider(height: 0, indent: 56),
                _NavTile(
                  icon: Icons.design_services_outlined,
                  label: 'Services',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ServicesScreen()),
                  ),
                ),
                const Divider(height: 0, indent: 56),
                _NavTile(
                  icon: Icons.badge_outlined,
                  label: 'Employees',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const EmployeesScreen()),
                  ),
                ),
                const Divider(height: 0, indent: 56),
                _NavTile(
                  icon: Icons.repeat,
                  label: 'Recurring Invoices',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const RecurringInvoicesScreen(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          _SectionHeader(title: 'Account'),
          Card(
            child: _NavTile(
              icon: Icons.logout,
              label: 'Log out',
              onTap: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Log out?'),
                    content: const Text(
                      'You will be returned to the login screen.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text(
                          'Log out',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await supabase.auth.signOut();
                  // _AuthGate stream will redirect to LoginScreen automatically
                }
              },
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const .only(left: 4, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: .bold,
          letterSpacing: 1.2,
          color: Theme.of(context).colorScheme.onSurface.withAlpha(120),
        ),
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _NavTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

// ── Pure-Flutter crop screen (custom_image_crop — no native setup needed) ────
class _CropScreen extends StatefulWidget {
  final String imagePath;
  const _CropScreen({required this.imagePath});

  @override
  State<_CropScreen> createState() => _CropScreenState();
}

class _CropScreenState extends State<_CropScreen> {
  final _cropController = CustomImageCropController();

  @override
  void dispose() {
    _cropController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Crop Logo'),
        actions: [
          TextButton(
            onPressed: () async {
              final result = await _cropController.onCropImage();
              if (result != null && context.mounted) {
                Navigator.pop(context, result.bytes);
              }
            },
            child: const Text(
              'Done',
              style: TextStyle(color: Colors.white, fontWeight: .bold),
            ),
          ),
        ],
      ),
      body: CustomImageCrop(
        cropController: _cropController,
        image: FileImage(File(widget.imagePath)),
        shape: CustomCropShape.Square,
        canRotate: true,
        canMove: true,
        canScale: true,
        overlayColor: Colors.black.withAlpha(140),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const .symmetric(horizontal: 32, vertical: 12),
          child: Row(
            mainAxisAlignment: .spaceEvenly,
            children: [
              IconButton(
                icon: const Icon(Icons.rotate_left, color: Colors.white),
                onPressed: () => _cropController.addTransition(
                  CropImageData(angle: -45 * 3.14159 / 180),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.rotate_right, color: Colors.white),
                onPressed: () => _cropController.addTransition(
                  CropImageData(angle: 45 * 3.14159 / 180),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.zoom_in, color: Colors.white),
                onPressed: () =>
                    _cropController.addTransition(CropImageData(scale: 1.15)),
              ),
              IconButton(
                icon: const Icon(Icons.zoom_out, color: Colors.white),
                onPressed: () => _cropController.addTransition(
                  CropImageData(scale: 1 / 1.15),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
