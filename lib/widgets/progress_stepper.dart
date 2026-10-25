import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'glass_card.dart';

class ProgressStepper extends StatelessWidget {
  const ProgressStepper({required this.activeStep, super.key});

  final int activeStep;

  @override
  Widget build(BuildContext context) {
    const labels = ['Select', 'Process', 'Results'];
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        children: [
          for (var index = 0; index < labels.length; index++) ...[
            Expanded(
              child: Column(
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: index == activeStep
                          ? AppTheme.pink
                          : AppTheme.card,
                      border: Border.all(
                        color: index <= activeStep
                            ? AppTheme.pink
                            : AppTheme.secondaryCard,
                      ),
                    ),
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: index == activeStep
                            ? AppTheme.card
                            : AppTheme.secondaryText,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    labels[index],
                    style: TextStyle(
                      color: index == activeStep
                          ? AppTheme.primaryText
                          : AppTheme.secondaryText,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            if (index < labels.length - 1)
              Expanded(
                child: Container(
                  height: 1,
                  margin: const EdgeInsets.only(bottom: 16),
                  color: AppTheme.secondaryCard.withValues(alpha: 0.8),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
