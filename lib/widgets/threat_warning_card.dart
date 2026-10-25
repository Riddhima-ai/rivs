import 'package:flutter/material.dart';

import '../models/threat_match.dart';
import '../theme/app_theme.dart';
import 'glass_card.dart';
import 'status_badge.dart';

class ThreatWarningCard extends StatelessWidget {
  const ThreatWarningCard({required this.match, super.key});

  final ThreatMatch match;

  @override
  Widget build(BuildContext context) {
    final scoreColor = match.similarity >= 85
        ? AppTheme.pink
        : match.similarity >= 65
        ? AppTheme.amber
        : AppTheme.mauve;
    return GlassCard(
      padding: const EdgeInsets.all(13),
      borderColor: scoreColor.withValues(alpha: 0.25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppTheme.secondaryCard.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.language_rounded,
                  color: AppTheme.blush,
                  size: 18,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  match.platform,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              StatusBadge(
                label: '${match.similarity.toStringAsFixed(1)}%',
                color: scoreColor,
              ),
            ],
          ),
          const SizedBox(height: 9),
          Text(
            match.url,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppTheme.secondaryText,
              fontSize: 10,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 9),
          Wrap(
            spacing: 7,
            runSpacing: 5,
            children: [
              const StatusBadge(label: 'POTENTIAL MATCH', color: AppTheme.pink),
              StatusBadge(
                label: match.isSimulated == true ? 'SIMULATED' : 'UNVERIFIED',
                color: AppTheme.secondaryText,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
