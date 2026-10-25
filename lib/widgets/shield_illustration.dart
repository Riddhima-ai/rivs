import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class ShieldIllustration extends StatelessWidget {
  const ShieldIllustration({super.key, this.height = 150});

  static const assetPath = 'assets/images/privacy_girl.png';
  final double height;

  @override
  Widget build(BuildContext context) {
    final fittedHeight = height.clamp(64, 104).toDouble();
    return SizedBox(
      width: double.infinity,
      height: fittedHeight,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: AppTheme.card.withValues(alpha: 0.08),
          ),
          child: Image.asset(
            assetPath,
            fit: BoxFit.contain,
            alignment: Alignment.center,
            errorBuilder: (context, error, stackTrace) {
              return const Center(
                child: Icon(
                  Icons.image_not_supported_outlined,
                  color: AppTheme.secondaryText,
                  size: 28,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
