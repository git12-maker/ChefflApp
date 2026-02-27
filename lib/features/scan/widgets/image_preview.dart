import 'dart:io';
import 'package:flutter/material.dart';

class ImagePreview extends StatelessWidget {
  const ImagePreview({
    super.key,
    required this.imageFile,
    this.onRetake,
  });

  final File imageFile;
  final VoidCallback? onRetake;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Image.file(
            imageFile,
            width: double.infinity,
            height: 300,
            fit: BoxFit.cover,
          ),
        ),
        if (onRetake != null)
          Positioned(
            top: 12,
            right: 12,
            child: Material(
              color: Colors.black.withOpacity(0.5),
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                onTap: onRetake,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  child: const Icon(
                    Icons.close_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
