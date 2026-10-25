import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class GradientButton extends StatelessWidget {
  const GradientButton({
    required this.label,
    required this.onPressed,
    super.key,
    this.icon,
    this.isLoading = false,
    this.secondary = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool secondary;

  @override
  Widget build(BuildContext context) {
    final content = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading)
          const SizedBox.square(
            dimension: 19,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppTheme.card,
            ),
          )
        else if (icon != null) ...[
          Icon(icon, size: 20),
          const SizedBox(width: 10),
        ],
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: secondary ? AppTheme.primaryText : AppTheme.card,
            ),
          ),
        ),
      ],
    );

    return SizedBox(
      width: double.infinity,
      height: 50,
      child: secondary
          ? OutlinedButton(
              onPressed: onPressed,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primaryText,
                side: BorderSide(color: AppTheme.mauve.withValues(alpha: 0.8)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: content,
            )
          : DecoratedBox(
              decoration: BoxDecoration(
                color: onPressed == null
                    ? AppTheme.mauve.withValues(alpha: 0.5)
                    : AppTheme.blush,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.mauve.withValues(alpha: 0.17),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: onPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  disabledBackgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: AppTheme.card,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: content,
              ),
            ),
    );
  }
}
