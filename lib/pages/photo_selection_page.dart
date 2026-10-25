import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../app_state.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/gradient_button.dart';
import '../widgets/image_preview_card.dart';
import '../widgets/page_header.dart';
import '../widgets/progress_stepper.dart';
import '../widgets/shield_illustration.dart';
import 'protection_results_page.dart';

class PhotoSelectionPage extends StatefulWidget {
  const PhotoSelectionPage({required this.appState, super.key});

  final AppState appState;

  @override
  State<PhotoSelectionPage> createState() => _PhotoSelectionPageState();
}

class _PhotoSelectionPageState extends State<PhotoSelectionPage> {
  static const _maxImageBytes = 10 * 1024 * 1024;
  final ImagePicker _picker = ImagePicker();
  final ApiService _api = ApiService();

  Uint8List? _imageBytes;
  String? _filename;
  String? _error;
  bool _isLoading = false;

  @override
  void dispose() {
    _api.close();
    super.dispose();
  }

  Future<void> _choosePhoto() async {
    if (_isLoading) return;
    setState(() => _error = null);
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
        maxWidth: 2400,
        maxHeight: 2400,
      );
      if (!mounted || picked == null) return;
      final length = await picked.length();
      if (length <= 0) {
        setState(
          () => _error = 'That image is empty. Please select another photo.',
        );
        return;
      }
      if (length > _maxImageBytes) {
        setState(
          () => _error =
              'This image is larger than 10 MB. Choose a smaller photo.',
        );
        return;
      }
      final bytes = await picked.readAsBytes();
      if (!mounted) return;
      if (bytes.isEmpty) {
        setState(
          () =>
              _error = 'The image could not be read. Please try another photo.',
        );
        return;
      }
      setState(() {
        _imageBytes = bytes;
        _filename = picked.name.isNotEmpty
            ? picked.name
            : picked.path.split(RegExp(r'[/\\]')).last;
      });
    } on PlatformException {
      if (mounted) {
        setState(
          () => _error =
              'Unable to open your gallery. Please check device permissions.',
        );
      }
    } on Exception {
      if (mounted) {
        setState(
          () => _error =
              'We could not read that image. Please choose another file.',
        );
      }
    }
  }

  Future<void> _processPhoto() async {
    final bytes = _imageBytes;
    if (_isLoading || bytes == null || bytes.isEmpty) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response = await _api.shieldImage(
        imageBytes: bytes,
        filename: _filename ?? 'portrait.jpg',
      );
      if (!mounted) return;
      widget.appState.recordProtection(
        hash: response.dhash,
        originalImage: bytes,
        processedImage: response.imageBytes,
      );
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ProtectionResultsPage(
            appState: widget.appState,
            originalImage: bytes,
            processedImage: response.imageBytes,
            hash: response.dhash,
          ),
        ),
      );
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } on Exception {
      if (mounted) {
        setState(
          () => _error = 'The photo could not be processed. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              constraints.maxWidth > 600 ? 30 : 20,
              14,
              constraints.maxWidth > 600 ? 30 : 20,
              24,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const PageHeader(
                      title: 'Protect a Photo',
                      subtitle: 'Choose an image to process.',
                    ),
                    const SizedBox(height: 14),
                    const ProgressStepper(activeStep: 0),
                    const SizedBox(height: 12),
                    if (_imageBytes == null)
                      GlassCard(
                        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                        borderColor: AppTheme.mauve.withValues(alpha: 0.38),
                        child: Column(
                          children: [
                            const ShieldIllustration(height: 96),
                            const SizedBox(height: 5),
                            const Text(
                              'Choose a portrait to get started.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Georgia',
                                fontSize: 17,
                              ),
                            ),
                            const SizedBox(height: 5),
                            const Text(
                              'Select an image from your gallery.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppTheme.secondaryText,
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(height: 13),
                            GradientButton(
                              label: 'Select Photo',
                              icon: Icons.photo_outlined,
                              isLoading: _isLoading,
                              onPressed: _isLoading ? null : _choosePhoto,
                            ),
                            const SizedBox(height: 9),
                            const Text(
                              'Supports JPG, PNG, WebP · Max 10 MB',
                              style: TextStyle(
                                color: AppTheme.secondaryText,
                                fontSize: 9,
                              ),
                            ),
                          ],
                        ),
                      )
                    else ...[
                      ImagePreviewCard(
                        label: 'SELECTED PHOTO',
                        imageBytes: _imageBytes!,
                        filename: _filename,
                        height: 260,
                      ),
                      const SizedBox(height: 14),
                      GradientButton(
                        label: 'Change Photo',
                        icon: Icons.swap_horiz_rounded,
                        secondary: true,
                        onPressed: _isLoading ? null : _choosePhoto,
                      ),
                    ],
                    if (_error != null) ...[
                      const SizedBox(height: 11),
                      _ErrorMessage(message: _error!),
                    ],
                    const SizedBox(height: 12),
                    GradientButton(
                      label: 'Apply Adversarial Shield',
                      icon: Icons.shield_outlined,
                      isLoading: _isLoading,
                      onPressed: _imageBytes == null || _isLoading
                          ? null
                          : _processPhoto,
                    ),
                    const SizedBox(height: 12),
                    const _TipsCard(),
                    const SizedBox(height: 10),
                    const _SafetyNote(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorMessage extends StatelessWidget {
  const _ErrorMessage({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(14),
      borderColor: AppTheme.pink.withValues(alpha: 0.35),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppTheme.pink,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: AppTheme.primaryText, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _SafetyNote extends StatelessWidget {
  const _SafetyNote();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        'Your photo is sent to the configured backend for experimental processing. Image protection does not guarantee prevention of misuse.',
        style: TextStyle(
          color: AppTheme.secondaryText,
          fontSize: 10,
          height: 1.45,
        ),
      ),
    );
  }
}

class _TipsCard extends StatelessWidget {
  const _TipsCard();

  @override
  Widget build(BuildContext context) {
    const tips = [
      'Use a clear portrait image',
      'Good lighting improves protection',
      'Higher resolution gives better results',
    ];
    return GlassCard(
      padding: const EdgeInsets.all(13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.lightbulb_outline_rounded,
                color: AppTheme.pink,
                size: 17,
              ),
              SizedBox(width: 7),
              Expanded(
                child: Text(
                  'Tips for best results',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          for (final tip in tips) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: AppTheme.pink,
                    size: 15,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      tip,
                      style: const TextStyle(
                        color: AppTheme.secondaryText,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
