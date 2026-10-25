import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/gradient_button.dart';
import '../widgets/image_preview_card.dart';
import '../widgets/page_header.dart';
import '../widgets/status_badge.dart';
import 'footprint_scan_page.dart';
import 'photo_selection_page.dart';

class ProtectionResultsPage extends StatelessWidget {
  const ProtectionResultsPage({
    required this.appState,
    required this.originalImage,
    required this.processedImage,
    required this.hash,
    super.key,
  });

  final AppState appState;
  final Uint8List originalImage;
  final Uint8List processedImage;
  final String hash;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 390;
            final padding = constraints.maxWidth > 700 ? 40.0 : 22.0;
            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(padding, 16, padding, 30),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const PageHeader(
                        title: 'Protection Results',
                        subtitle: 'Review your processed image.',
                        trailing: StatusBadge(
                          label: 'EXPERIMENTAL',
                          color: AppTheme.pink,
                        ),
                      ),
                      const SizedBox(height: 14),
                      if (wide)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: ImagePreviewCard(
                                label: 'Original Image',
                                imageBytes: originalImage,
                                height: constraints.maxWidth > 700 ? 260 : 170,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: ImagePreviewCard(
                                label: 'Processed Image',
                                imageBytes: processedImage,
                                height: constraints.maxWidth > 700 ? 260 : 170,
                              ),
                            ),
                          ],
                        )
                      else ...[
                        ImagePreviewCard(
                          label: 'Original Image',
                          imageBytes: originalImage,
                        ),
                        const SizedBox(height: 13),
                        ImagePreviewCard(
                          label: 'Processed Image',
                          imageBytes: processedImage,
                        ),
                      ],
                      const SizedBox(height: 20),
                      _FingerprintCard(hash: hash),
                      const SizedBox(height: 12),
                      const _SuccessCard(),
                      const SizedBox(height: 12),
                      GradientButton(
                        label: 'Scan Digital Footprint',
                        icon: Icons.search_rounded,
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => FootprintScanPage(
                              hash: hash,
                              imageBytes: originalImage,
                              filename: 'protected-photo.png',
                              appState: appState,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 11),
                      GradientButton(
                        label: 'Protect Another Photo',
                        icon: Icons.add_photo_alternate_outlined,
                        secondary: true,
                        onPressed: () =>
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute<void>(
                                builder: (_) =>
                                    PhotoSelectionPage(appState: appState),
                              ),
                              (route) => route.isFirst,
                            ),
                      ),
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
}

class _SuccessCard extends StatelessWidget {
  const _SuccessCard();

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(13),
      borderColor: AppTheme.mauve.withValues(alpha: 0.4),
      gradient: const LinearGradient(
        colors: [AppTheme.blush, AppTheme.softBlush],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.shield_rounded, color: AppTheme.card, size: 23),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Processing completed',
                      style: TextStyle(
                        color: AppTheme.card,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Your image was processed using the experimental adversarial technique.',
                      style: TextStyle(color: AppTheme.card, fontSize: 10),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FingerprintCard extends StatelessWidget {
  const _FingerprintCard({required this.hash});
  final String hash;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.fingerprint_rounded, color: AppTheme.mauve, size: 21),
              SizedBox(width: 9),
              Expanded(
                child: Text(
                  'Image Fingerprint (dHash)',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.background.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: SelectableText(
                    hash,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      color: AppTheme.blush,
                      fontSize: 16,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Copy image fingerprint',
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: hash));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Fingerprint copied to clipboard.'),
                        ),
                      );
                    }
                  },
                  icon: const Icon(
                    Icons.copy_rounded,
                    color: AppTheme.secondaryText,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'This perceptual fingerprint helps compare visually similar images. It is not a unique identity or proof of ownership.',
            style: TextStyle(
              color: AppTheme.secondaryText,
              fontSize: 12,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}
