import 'dart:io';
import 'dart:typed_data';
import 'package:custom_image_crop/custom_image_crop.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:new_invoice_generator/main.dart';
import 'package:new_invoice_generator/providers/company.dart';
import 'package:new_invoice_generator/services/storage.dart';

class CompanyLogoCard extends ConsumerWidget {
  const CompanyLogoCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final companyAsync = ref.watch(companyProvider);

    return companyAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (company) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _LogoAvatar(company: company),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      company['name'] as String? ?? 'My Company',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
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
    );
  }
}

class _LogoAvatar extends ConsumerWidget {
  final Map<String, dynamic> company;
  const _LogoAvatar({required this.company});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () => _pickAndUpload(context, ref),
      child: Stack(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: cs.outline.withAlpha(80)),
              color: cs.surfaceContainerHighest,
            ),
            child: company['logo_url'] != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(11),
                    child: Image.network(
                      company['logo_url'] as String,
                      key: ValueKey(company['logo_url']),
                      fit: BoxFit.cover,
                      loadingBuilder: (_, child, progress) => progress == null
                          ? child
                          : const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                      errorBuilder: (_, _, _) => Icon(
                        Icons.business,
                        size: 36,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  )
                : Icon(Icons.business, size: 36, color: cs.onSurfaceVariant),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: cs.primary,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.camera_alt, size: 12, color: cs.onPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAndUpload(BuildContext context, WidgetRef ref) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;

    final XFile? picked = await ImagePicker().pickImage(
      source: source,
      imageQuality: 90,
      maxWidth: 1000,
      maxHeight: 1000,
    );
    if (picked == null) return;
    if (!context.mounted) return;

    final croppedBytes = await Navigator.push<Uint8List?>(
      context,
      MaterialPageRoute(builder: (_) => _CropScreen(imagePath: picked.path)),
    );
    if (croppedBytes == null) return;

    try {
      final dir = await getTemporaryDirectory();
      final tmpFile = File('${dir.path}/logo_crop.png');
      await tmpFile.writeAsBytes(croppedBytes);

      final signedUrl = await StorageService().uploadLogo(
        tmpFile,
        company['id'] as String,
      );
      final storagePath =
          '${supabase.auth.currentUser!.id}/logos/${company['id']}.png';

      await ref
          .read(companyProvider.notifier)
          .updateLogo(signedUrl, storagePath);
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Logo updated!')));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
    }
  }
}

// ── Crop screen ────────────────────────────────────────────────────────────
class _CropScreen extends StatefulWidget {
  final String imagePath;
  const _CropScreen({required this.imagePath});

  @override
  State<_CropScreen> createState() => _CropScreenState();
}

class _CropScreenState extends State<_CropScreen> {
  final _ctrl = CustomImageCropController();

  @override
  void dispose() {
    _ctrl.dispose();
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
              final result = await _ctrl.onCropImage();
              if (result != null && context.mounted) {
                Navigator.pop(context, result.bytes);
              }
            },
            child: const Text(
              'Done',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: CustomImageCrop(
        cropController: _ctrl,
        image: FileImage(File(widget.imagePath)),
        shape: CustomCropShape.Square,
        canRotate: true,
        canMove: true,
        canScale: true,
        overlayColor: Colors.black.withAlpha(140),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: const Icon(Icons.rotate_left, color: Colors.white),
                onPressed: () => _ctrl.addTransition(
                  CropImageData(angle: -45 * 3.14159 / 180),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.rotate_right, color: Colors.white),
                onPressed: () => _ctrl.addTransition(
                  CropImageData(angle: 45 * 3.14159 / 180),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.zoom_in, color: Colors.white),
                onPressed: () =>
                    _ctrl.addTransition(CropImageData(scale: 1.15)),
              ),
              IconButton(
                icon: const Icon(Icons.zoom_out, color: Colors.white),
                onPressed: () =>
                    _ctrl.addTransition(CropImageData(scale: 1 / 1.15)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
