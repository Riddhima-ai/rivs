import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'status_badge.dart';

class AppHeader extends StatelessWidget {
  const AppHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppTheme.secondaryCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.mauve.withValues(alpha: 0.45)),
          ),
          child: const Icon(
            Icons.shield_rounded,
            color: AppTheme.blush,
            size: 23,
          ),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'DEEPFAKE SHIELD',
                maxLines: 1,
                style: TextStyle(
                  fontSize: 13,
                  letterSpacing: 0.65,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'Your identity. Your control.',
                style: TextStyle(color: AppTheme.secondaryText, fontSize: 10),
              ),
            ],
          ),
        ),
        const StatusBadge(label: 'PRIVACY LAB', color: AppTheme.mauve),
      ],
    );
  }
}
