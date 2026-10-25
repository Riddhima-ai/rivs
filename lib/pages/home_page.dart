import 'package:flutter/material.dart';

import '../app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header.dart';
import '../widgets/glass_card.dart';
import '../widgets/gradient_button.dart';
import '../widgets/shield_illustration.dart';
import 'footprint_scan_page.dart';
import 'photo_selection_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({required this.appState, super.key});

  final AppState appState;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final padding = constraints.maxWidth > 600 ? 32.0 : 20.0;
            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(padding, 14, padding, 24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const AppHeader(),
                      const SizedBox(height: 6),
                      const ShieldIllustration(height: 84),
                      const SizedBox(height: 2),
                      GlassCard(
                        padding: const EdgeInsets.fromLTRB(14, 10, 14, 16),
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [AppTheme.blush, AppTheme.softBlush],
                        ),
                        borderColor: AppTheme.mauve.withValues(alpha: 0.55),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text.rich(
                              const TextSpan(
                                style: TextStyle(
                                  fontFamily: 'Georgia',
                                  fontSize: 21,
                                  height: 1.13,
                                  color: AppTheme.card,
                                ),
                                children: [
                                  TextSpan(text: 'Take control of your\n'),
                                  TextSpan(
                                    text: 'online presence.',
                                    style: TextStyle(color: AppTheme.mauve),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 9),
                            const Text(
                              'Apply experimental image protection and check for visually similar image fingerprints in a prototype database.',
                              style: TextStyle(
                                color: AppTheme.card,
                                fontSize: 11,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      GradientButton(
                        label: 'Protect My Photo',
                        icon: Icons.photo_outlined,
                        onPressed: () => _openPhoto(context),
                      ),
                      const SizedBox(height: 8),
                      GradientButton(
                        label: 'Scan Digital Footprint',
                        icon: Icons.search_rounded,
                        secondary: true,
                        onPressed: () => _openScan(context),
                      ),
                      const SizedBox(height: 14),
                      AnimatedBuilder(
                        animation: appState,
                        builder: (context, _) => Row(
                          children: [
                            Expanded(
                              child: _StatCard(
                                icon: Icons.image_outlined,
                                label: 'Photos Processed',
                                value: appState.processedImages,
                              ),
                            ),
                            const SizedBox(width: 9),
                            Expanded(
                              child: _StatCard(
                                icon: Icons.track_changes_rounded,
                                label: 'Potential Matches',
                                value: appState.potentialMatches,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 15),
                      const Text(
                        'How it works',
                        style: TextStyle(
                          fontFamily: 'Georgia',
                          fontSize: 17,
                          color: AppTheme.primaryText,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const _HowItWorks(),
                      const SizedBox(height: 10),
                      const _Disclaimer(),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _openPhoto(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PhotoSelectionPage(appState: appState),
      ),
    );
  }

  void _openScan(BuildContext context) {
    final hash = appState.latestHash;
    if (hash == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Choose and process a photo to create a fingerprint.'),
        ),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => FootprintScanPage(hash: hash, appState: appState),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.pink, size: 19),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$value',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.secondaryText,
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HowItWorks extends StatelessWidget {
  const _HowItWorks();

  @override
  Widget build(BuildContext context) {
    const steps = [
      ('01', Icons.photo_outlined, 'Select a portrait'),
      ('02', Icons.auto_awesome_outlined, 'Apply protection'),
      ('03', Icons.search_rounded, 'Scan fingerprints'),
    ];
    return Row(
      children: [
        for (var index = 0; index < steps.length; index++) ...[
          Expanded(
            child: GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 9),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    steps[index].$1,
                    style: const TextStyle(
                      color: AppTheme.pink,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Icon(steps[index].$2, color: AppTheme.mauve, size: 17),
                  const SizedBox(height: 4),
                  Text(
                    steps[index].$3,
                    maxLines: 2,
                    style: const TextStyle(
                      color: AppTheme.secondaryText,
                      fontSize: 9,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (index != steps.length - 1) const SizedBox(width: 7),
        ],
      ],
    );
  }
}

class _Disclaimer extends StatelessWidget {
  const _Disclaimer();

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      borderColor: AppTheme.mauve.withValues(alpha: 0.22),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: AppTheme.pink, size: 16),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Protection is experimental. Scan results use a prototype database and do not prove unauthorized image use.',
              style: TextStyle(
                color: AppTheme.secondaryText,
                fontSize: 9,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
