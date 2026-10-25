import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:rivs/services/api_service.dart';

void main() {
  group('ApiService', () {
    test(
      'uploads an image as multipart data and parses the response',
      () async {
        http.Request? capturedRequest;
        final client = MockClient((request) async {
          capturedRequest = request;
          return http.Response(
            jsonEncode({
              'dhash': '0123456789ABCDEF',
              'image_base64': base64Encode([1, 2, 3]),
            }),
            200,
          );
        });
        final api = ApiService(
          client: client,
          baseUrl: 'https://api.example/v1/',
        );

        final response = await api.shieldImage(
          imageBytes: [4, 5, 6],
          filename: 'portrait.png',
        );

        expect(capturedRequest, isNotNull);
        expect(capturedRequest!.method, 'POST');
        expect(
          capturedRequest!.url,
          Uri.parse('https://api.example/v1/shield'),
        );
        expect(
          capturedRequest!.headers['content-type'],
          startsWith('multipart/form-data; boundary='),
        );
        expect(
          capturedRequest!.body,
          contains('name="file"; filename="portrait.png"'),
        );
        expect(
          capturedRequest!.body.toLowerCase(),
          contains('content-type: image/png'),
        );
        expect(response.dhash, '0123456789abcdef');
        expect(response.imageBytes, [1, 2, 3]);
      },
    );

    test('posts the fingerprint to the configured scan endpoint', () async {
      final client = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/v1/scan');
        expect(request.url.queryParameters, {'dhash': '0123456789abcdef'});
        return http.Response('{"matches":[]}', 200);
      });
      final api = ApiService(
        client: client,
        baseUrl: 'https://api.example/v1/',
      );

      final matches = await api.scanHash('0123456789abcdef');

      expect(matches, isEmpty);
    });

    test('parses all matches and their optional simulation status', () async {
      final client = MockClient(
        (_) async => http.Response(
          jsonEncode({
            'matches': [
              {
                'platform': 'Prototype A',
                'url': 'https://example.invalid/a',
                'similarity': 92.18,
                'is_simulated': true,
              },
              {
                'platform': 'Prototype B',
                'url': 'https://example.invalid/b',
                'similarity': 81,
              },
            ],
          }),
          200,
        ),
      );
      final api = ApiService(client: client, baseUrl: 'https://api.example');

      final matches = await api.scanHash('0123456789abcdef');

      expect(matches, hasLength(2));
      expect(matches.first.similarity, 92.18);
      expect(matches.first.isSimulated, isTrue);
      expect(matches.last.isSimulated, isNull);
    });

    test('reports unsuccessful HTTP status codes', () async {
      final client = MockClient(
        (_) async => http.Response('{"detail":"unavailable"}', 503),
      );
      final api = ApiService(client: client, baseUrl: 'https://api.example');

      await expectLater(
        api.scanHash('0123456789abcdef'),
        throwsA(
          isA<ApiException>().having(
            (error) => error.message,
            'message',
            contains('HTTP 503'),
          ),
        ),
      );
    });
  });
}
