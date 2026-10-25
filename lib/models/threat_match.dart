class ThreatMatch {
  const ThreatMatch({
    required this.platform,
    required this.url,
    required this.similarity,
    this.isSimulated,
  });

  final String platform;
  final String url;
  final double similarity;
  final bool? isSimulated;

  factory ThreatMatch.fromJson(Map<String, dynamic> json) {
    final platform = json['platform'];
    final url = json['url'];
    final rawSimilarity = json['similarity'];
    final rawSimulated = json['is_simulated'] ?? json['simulated'];
    final similarity = rawSimilarity is num
        ? rawSimilarity.toDouble()
        : rawSimilarity is String
        ? double.tryParse(rawSimilarity)
        : null;
    if (platform is! String || platform.trim().isEmpty) {
      throw const FormatException('A scan match is missing its platform name.');
    }
    if (url is! String || url.trim().isEmpty) {
      throw const FormatException('A scan match is missing its URL.');
    }
    if (similarity == null ||
        !similarity.isFinite ||
        similarity < 0 ||
        similarity > 100) {
      throw const FormatException(
        'A scan match has an invalid similarity score.',
      );
    }
    if (rawSimulated != null && rawSimulated is! bool) {
      throw const FormatException(
        'A scan match has an invalid simulated-status value.',
      );
    }
    return ThreatMatch(
      platform: platform.trim(),
      url: url.trim(),
      similarity: similarity,
      isSimulated: rawSimulated is bool ? rawSimulated : null,
    );
  }
}
