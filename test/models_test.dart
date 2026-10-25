import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:rivs/models/shield_response.dart';
import 'package:rivs/models/threat_match.dart';

void main() {
  group('ShieldResponse', () {
    test('decodes a valid image and normalizes the hash', () {
      final response = ShieldResponse.fromJson({
        'dhash': '0123456789ABCDEF',
        'image_base64': base64Encode([1, 2, 3]),
      });

      expect(response.dhash, '0123456789abcdef');
      expect(response.imageBytes, [1, 2, 3]);
    });

    test('rejects invalid hashes and invalid Base64', () {
      expect(
        () => ShieldResponse.fromJson({
          'dhash': 'bad',
          'image_base64': base64Encode([1]),
        }),
        throwsFormatException,
      );
      expect(
        () => ShieldResponse.fromJson({
          'dhash': '0123456789abcdef',
          'image_base64': '%',
        }),
        throwsFormatException,
      );
    });
  });

  group('ThreatMatch', () {
    test('parses numeric similarity', () {
      final match = ThreatMatch.fromJson({
        'platform': 'Prototype',
        'url': 'https://example.invalid',
        'similarity': 92,
        'is_simulated': true,
      });

      expect(match.similarity, 92.0);
      expect(match.isSimulated, isTrue);
    });

    test('rejects similarity outside the percentage range', () {
      expect(
        () => ThreatMatch.fromJson({
          'platform': 'Prototype',
          'url': 'https://example.invalid',
          'similarity': 101,
        }),
        throwsFormatException,
      );
    });
  });
}
