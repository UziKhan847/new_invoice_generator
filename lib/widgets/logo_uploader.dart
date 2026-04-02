import 'package:flutter/material.dart';

class LogoUploader extends StatelessWidget {
  final String? imageUrl;
  final VoidCallback? onUpload;
  const LogoUploader({super.key, this.imageUrl, this.onUpload});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onUpload,
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey),
        ),
        child: imageUrl == null
            ? const Center(child: Icon(Icons.upload))
            : Image.network(imageUrl!, fit: BoxFit.cover),
      ),
    );
  }
}