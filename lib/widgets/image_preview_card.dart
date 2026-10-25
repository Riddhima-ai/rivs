import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'glass_card.dart';

class ImagePreviewCard extends StatelessWidget {
  const ImagePreviewCard({
    required this.label,
    required this.imageBytes,
    super.key,
    this.filename,
    this.height = 220,
  });

  final String label;
  final Uint8List imageBytes;
  final String? filename;
  final double height;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: AppTheme.blush,
                    letterSpacing: 1.1,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (filename != null)
                Flexible(
                  child: Text(
                    filename!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppTheme.secondaryText,
                      fontSize: 11,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Container(
              height: height,
              width: double.infinity,
              color: AppTheme.secondaryBackground,
              child: Image.memory(
                imageBytes,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const Center(
                  child: Icon(
                    Icons.broken_image_outlined,
                    size: 40,
                    color: AppTheme.secondaryText,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
