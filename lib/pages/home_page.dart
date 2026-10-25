import 'package:flutter/material.dart';

import '../app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header.dart';
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
            final desktop =
                constraints.maxWidth >= 900 && constraints.maxHeight >= 650;
            final horizontalPadding = switch (constraints.maxWidth) {
              > 700 => 24.0,
              _ => 16.0,
            };

            final compact = constraints.maxHeight < 650;
            final illustrationHeight = desktop
                ? (constraints.maxHeight * 0.2).clamp(140.0, 180.0).toDouble()
                : compact
                ? 95.0
                : 130.0;
            return Padding(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                desktop
                    ? 12
                    : compact
                    ? 8
                    : 10,
                horizontalPadding,
                desktop
                    ? 12
                    : compact
                    ? 8
                    : 12,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 540),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisAlignment: desktop
                        ? MainAxisAlignment.spaceBetween
                        : MainAxisAlignment.start,
                    children: [
                      const AppHeader(),
                      SizedBox(height: compact ? 4 : 7),
                      ShieldIllustration(
                        height: illustrationHeight,
                        maxWidth: desktop
                            ? 144
                            : compact
                            ? 76
                            : 104,
                      ),
                      SizedBox(height: compact ? 2 : 4),
                      _ActionsAndStats(
                        appState: appState,
                        onProtect: () => _openPhoto(context),
                        onScan: () => _openScan(context),
                        compact: compact,
                      ),
                      SizedBox(height: compact ? 7 : 10),
                      const _SectionHeading(title: 'How it works'),
                      SizedBox(height: compact ? 5 : 7),
                      const _HowItWorks(),
                      SizedBox(height: compact ? 6 : 8),
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
    final imageBytes = appState.latestOriginalImage;
    if (hash == null || imageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Choose and process a photo to create a fingerprint.'),
        ),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => FootprintScanPage(
          hash: hash,
          imageBytes: imageBytes,
          filename: 'protected-photo.png',
          appState: appState,
        ),
      ),
    );
  }
}

class _ActionsAndStats extends StatelessWidget {
  const _ActionsAndStats({
    required this.appState,
    required this.onProtect,
    required this.onScan,
    required this.compact,
  });

  final AppState appState;
  final VoidCallback onProtect;
  final VoidCallback onScan;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'YOUR PRIVACY TOOLKIT',
          style: TextStyle(
            color: AppTheme.mauve,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.4,
          ),
        ),
        SizedBox(height: compact ? 4 : 6),
        GradientButton(
          label: 'Protect My Photo',
          icon: Icons.photo_outlined,
          onPressed: onProtect,
        ),
        SizedBox(height: compact ? 4 : 6),
        GradientButton(
          label: 'Scan Digital Footprint',
          icon: Icons.search_rounded,
          secondary: true,
          onPressed: onScan,
        ),
        SizedBox(height: compact ? 6 : 8),
        AnimatedBuilder(
          animation: appState,
          builder: (context, _) => Column(
            children: [
              _StatCard(
                icon: Icons.image_outlined,
                label: 'Photos Processed',
                value: appState.processedImages,
              ),
              const SizedBox(height: 5),
              _StatCard(
                icon: Icons.fingerprint_rounded,
                label: 'Potential Matches',
                value: appState.potentialMatches,
              ),
            ],
          ),
        ),
      ],
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
    return Container(
      constraints: const BoxConstraints(minHeight: 52),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.mauve.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.mauve, size: 19),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$value',
                  style: const TextStyle(
                    color: AppTheme.primaryText,
                    fontSize: 17,
                    height: 1,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.secondaryText,
                    fontSize: 9,
                    height: 1.15,
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

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontFamily: 'Georgia',
        color: AppTheme.primaryText,
        fontSize: 18,
        fontWeight: FontWeight.w500,
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
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.secondaryBackground,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppTheme.mauve.withValues(alpha: 0.16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        steps[index].$1,
                        style: const TextStyle(
                          color: AppTheme.mauve,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Icon(steps[index].$2, color: AppTheme.mauve, size: 14),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    steps[index].$3,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.card.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.mauve.withValues(alpha: 0.16)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: AppTheme.mauve, size: 16),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Protection is experimental. Scan results use a prototype database and do not prove unauthorized image use.',
              style: TextStyle(
                color: AppTheme.secondaryText,
                fontSize: 10,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
