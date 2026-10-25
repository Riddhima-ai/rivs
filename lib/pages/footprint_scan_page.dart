import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models/threat_match.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_state.dart';
import '../widgets/glass_card.dart';
import '../widgets/gradient_button.dart';
import '../widgets/page_header.dart';
import '../widgets/threat_warning_card.dart';
import 'photo_selection_page.dart';

class FootprintScanPage extends StatefulWidget {
  const FootprintScanPage({
    required this.hash,
    required this.appState,
    super.key,
  });

  final String hash;
  final AppState appState;

  @override
  State<FootprintScanPage> createState() => _FootprintScanPageState();
}

class _FootprintScanPageState extends State<FootprintScanPage> {
  final ApiService _api = ApiService();
  List<ThreatMatch>? _matches;
  String? _error;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _scan();
    });
  }

  @override
  void dispose() {
    _api.close();
    super.dispose();
  }

  Future<void> _scan() async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final matches = await _api.scanHash(widget.hash);
      if (!mounted) return;
      widget.appState.recordMatches(matches.length);
      setState(() {
        _matches = matches;
      });
    } on ApiException catch (error) {
      if (mounted) {
        setState(() {
          _error = error.message;
        });
      }
    } on Exception {
      if (mounted) {
        setState(() {
          _error =
              'The fingerprint scan could not be completed. Please try again.';
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _protectAnother() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (_) => PhotoSelectionPage(appState: widget.appState),
      ),
      (route) => route.isFirst,
    );
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
                      title: 'Digital Footprint',
                      subtitle: 'Search for similar image fingerprints.',
                    ),
                    const SizedBox(height: 14),
                    GlassCard(
                      padding: const EdgeInsets.all(15),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.fingerprint_rounded,
                            color: AppTheme.blush,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              widget.hash,
                              style: const TextStyle(
                                color: AppTheme.secondaryText,
                                fontFamily: 'monospace',
                                fontSize: 13,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 11),
                    if (_matches != null) ...[
                      _ScanSummary(count: _matches!.length),
                      const SizedBox(height: 11),
                    ],
                    if (_isLoading)
                      const _ScanningState()
                    else if (_error != null)
                      _ErrorState(
                        message: _error!,
                        onRetry: _scan,
                        isLoading: _isLoading,
                      )
                    else if (_matches != null && _matches!.isEmpty)
                      Column(
                        children: [
                          EmptyState(
                            icon: Icons.search_rounded,
                            title: 'No similar fingerprints found.',
                            message:
                                'This image was not matched in the configured prototype database.',
                            buttonLabel: 'Scan Again',
                            buttonIcon: Icons.refresh_rounded,
                            onPressed: _scan,
                            isLoading: _isLoading,
                          ),
                          const SizedBox(height: 12),
                          GradientButton(
                            label: 'Protect Another Photo',
                            icon: Icons.add_photo_alternate_outlined,
                            secondary: true,
                            onPressed: _protectAnother,
                          ),
                        ],
                      )
                    else if (_matches != null)
                      _MatchesList(matches: _matches!)
                    else
                      const SizedBox.shrink(),
                    if (_matches != null) ...[
                      const SizedBox(height: 11),
                      const _MeaningCard(),
                    ],
                    if (_matches != null && _matches!.isNotEmpty) ...[
                      const SizedBox(height: 19),
                      GradientButton(
                        label: 'Scan Again',
                        icon: Icons.refresh_rounded,
                        secondary: true,
                        onPressed: _isLoading ? null : _scan,
                      ),
                      const SizedBox(height: 11),
                      GradientButton(
                        label: 'Protect Another Photo',
                        icon: Icons.add_photo_alternate_outlined,
                        onPressed: _protectAnother,
                      ),
                    ],
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

class _ScanningState extends StatelessWidget {
  const _ScanningState();

  @override
  Widget build(BuildContext context) {
    return const GlassCard(
      child: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 28),
          child: Column(
            children: [
              SizedBox(
                width: 42,
                height: 42,
                child: CircularProgressIndicator(
                  color: AppTheme.mauve,
                  strokeWidth: 3,
                ),
              ),
              SizedBox(height: 17),
              Text('Searching prototype fingerprints…'),
              SizedBox(height: 6),
              Text(
                'This may take a moment.',
                style: TextStyle(color: AppTheme.secondaryText, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.message,
    required this.onRetry,
    required this.isLoading,
  });

  final String message;
  final VoidCallback onRetry;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderColor: AppTheme.pink.withValues(alpha: 0.3),
      child: Column(
        children: [
          const Icon(Icons.cloud_off_rounded, color: AppTheme.pink, size: 35),
          const SizedBox(height: 12),
          const Text(
            'Scan unavailable',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 7),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppTheme.secondaryText, height: 1.45),
          ),
          const SizedBox(height: 18),
          GradientButton(
            label: 'Retry Scan',
            icon: Icons.refresh_rounded,
            onPressed: isLoading ? null : onRetry,
            isLoading: isLoading,
          ),
        ],
      ),
    );
  }
}

class _MatchesList extends StatelessWidget {
  const _MatchesList({required this.matches});
  final List<ThreatMatch> matches;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final match in matches) ...[
          ThreatWarningCard(match: match),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _ScanSummary extends StatelessWidget {
  const _ScanSummary({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(13),
      child: Row(
        children: [
          const Icon(
            Icons.track_changes_rounded,
            color: AppTheme.pink,
            size: 25,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Scan Results',
                  style: TextStyle(fontFamily: 'Georgia', fontSize: 15),
                ),
                const SizedBox(height: 3),
                Text(
                  '$count potential ${count == 1 ? 'match' : 'matches'} in the prototype database.',
                  style: const TextStyle(
                    color: AppTheme.secondaryText,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '$count',
            style: const TextStyle(
              color: AppTheme.primaryText,
              fontSize: 24,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _MeaningCard extends StatelessWidget {
  const _MeaningCard();

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(13),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.help_outline_rounded, color: AppTheme.pink, size: 19),
          SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'What do these results mean?',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 5),
                Text(
                  'These are visually similar images found in the prototype database. A high similarity score does not confirm unauthorized use.',
                  style: TextStyle(
                    color: AppTheme.secondaryText,
                    fontSize: 10,
                    height: 1.4,
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
