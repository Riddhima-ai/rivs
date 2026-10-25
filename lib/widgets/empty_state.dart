import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'gradient_button.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.icon,
    required this.title,
    required this.message,
    required this.buttonLabel,
    required this.onPressed,
    super.key,
    this.buttonIcon = Icons.arrow_forward_rounded,
    this.isLoading = false,
  });

  final IconData icon;
  final String title;
  final String message;
  final String buttonLabel;
  final VoidCallback? onPressed;
  final IconData buttonIcon;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.card.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.mauve.withValues(alpha: 0.27)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.mauve.withValues(alpha: 0.14),
            ),
            child: Icon(icon, size: 34, color: AppTheme.blush),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppTheme.secondaryText, height: 1.45),
          ),
          const SizedBox(height: 22),
          GradientButton(
            label: buttonLabel,
            icon: isLoading ? null : buttonIcon,
            onPressed: onPressed,
            isLoading: isLoading,
          ),
        ],
      ),
    );
  }
}
