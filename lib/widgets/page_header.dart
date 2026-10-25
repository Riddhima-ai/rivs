import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class PageHeader extends StatelessWidget {
  const PageHeader({
    required this.title,
    required this.subtitle,
    super.key,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          tooltip: 'Go back',
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_rounded),
          style: IconButton.styleFrom(
            backgroundColor: AppTheme.card,
            foregroundColor: AppTheme.primaryText,
            minimumSize: const Size(42, 42),
            shape: const CircleBorder(),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 19,
                  fontFamily: 'Georgia',
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppTheme.secondaryText,
                  fontSize: 13,
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: 7), trailing!],
            ],
          ),
        ),
      ],
    );
  }
}
