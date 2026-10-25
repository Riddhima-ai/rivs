import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../models/shield_response.dart';
import '../models/threat_match.dart';

class ApiException implements Exception {
  const ApiException(this.message);
  final String message;

  @override
  String toString() => message;
}

class ApiService {
  ApiService({http.Client? client, String? baseUrl})
    : _client = client ?? http.Client(),
      _ownsClient = client == null,
      _baseUri = Uri.parse(baseUrl ?? defaultBaseUrl);

  static String get defaultBaseUrl {
    const override = String.fromEnvironment('API_BASE_URL');
    if (override.isNotEmpty) return override;

    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return 'http://127.0.0.1:8000';
    }
    return 'http://10.0.2.2:8000';
  }

  final http.Client _client;
  final bool _ownsClient;
  final Uri _baseUri;
  static const _timeout = Duration(seconds: 60);

  Future<ShieldResponse> shieldImage({
    required List<int> imageBytes,
    required String filename,
  }) async {
    final uri = _endpoint('/shield');
    final request = http.MultipartRequest('POST', uri)
      ..files.add(
        http.MultipartFile.fromBytes(
          'file',
          imageBytes,
          filename: filename,
          contentType: _mediaType(filename),
        ),
      );
    try {
      final streamed = await _client.send(request).timeout(_timeout);
      final response = await http.Response.fromStream(
        streamed,
      ).timeout(_timeout);
      final body = _decodeObject(response);
      return ShieldResponse.fromJson(body);
    } on ApiException {
      rethrow;
    } on FormatException catch (error) {
      throw ApiException(error.message);
    } on Exception catch (error) {
      throw ApiException(_networkMessage(error));
    }
  }

  Future<List<ThreatMatch>> scanHash(String hash) async {
    if (!RegExp(r'^[0-9a-fA-F]{16}$').hasMatch(hash)) {
      throw const ApiException(
        'The image fingerprint is not a valid 64-bit hash.',
      );
    }
    final uri = _endpoint('/scan', queryParameters: {'dhash': hash});
    try {
      final response = await _client.post(uri).timeout(_timeout);
      final body = _decodeObject(response);
      final rawMatches = body['matches'] ?? body['threats'];
      if (rawMatches is! List) {
        throw const ApiException(
          'The scan response is missing its matches list.',
        );
      }
      try {
        return rawMatches
            .map((item) {
              if (item is! Map<String, dynamic>) {
                throw const FormatException('A scan result is malformed.');
              }
              return ThreatMatch.fromJson(item);
            })
            .toList(growable: false);
      } on FormatException catch (error) {
        throw ApiException(error.message);
      }
    } on ApiException {
      rethrow;
    } on FormatException catch (error) {
      throw ApiException(error.message);
    } on Exception catch (error) {
      throw ApiException(_networkMessage(error));
    }
  }

  Future<Map<String, dynamic>> protectImage({
    required List<int> imageBytes,
    required String filename,
  }) async => _uploadJson('/protect', imageBytes, filename);

  Future<Map<String, dynamic>> scanImage({
    required List<int> imageBytes,
    required String filename,
    int threshold = 8,
  }) async {
    if (threshold < 0 || threshold > 64) {
      throw const ApiException(
        'The perceptual threshold must be from 0 to 64.',
      );
    }
    return _uploadJson(
      '/scan',
      imageBytes,
      filename,
      queryParameters: {'threshold': '$threshold'},
    );
  }

  Future<Map<String, dynamic>> _uploadJson(
    String path,
    List<int> imageBytes,
    String filename, {
    Map<String, String>? queryParameters,
  }) async {
    if (imageBytes.isEmpty) {
      throw const ApiException('Choose a non-empty image first.');
    }
    final request =
        http.MultipartRequest(
            'POST',
            _endpoint(path, queryParameters: queryParameters),
          )
          ..files.add(
            http.MultipartFile.fromBytes(
              'file',
              imageBytes,
              filename: filename,
              contentType: _mediaType(filename),
            ),
          );
    try {
      final streamed = await _client.send(request).timeout(_timeout);
      final response = await http.Response.fromStream(
        streamed,
      ).timeout(_timeout);
      return _decodeObject(response);
    } on ApiException {
      rethrow;
    } on Exception catch (error) {
      throw ApiException(_networkMessage(error));
    }
  }

  Uri _endpoint(String path, {Map<String, String>? queryParameters}) {
    final base = _baseUri;
    if ((base.scheme != 'http' && base.scheme != 'https') ||
        !base.hasAuthority ||
        base.host.isEmpty) {
      throw const ApiException(
        'The backend URL must be a valid HTTP or HTTPS address.',
      );
    }
    return base.replace(
      path: '${base.path.replaceFirst(RegExp(r'/$'), '')}$path',
      queryParameters: queryParameters,
    );
  }

  Map<String, dynamic> _decodeObject(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        'The server returned HTTP ${response.statusCode}. Please try again.',
      );
    }
    final dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } on FormatException {
      throw const ApiException('The server returned an unreadable response.');
    }
    if (decoded is! Map<String, dynamic>) {
      throw const ApiException('The server response has an unexpected format.');
    }
    return decoded;
  }

  String _networkMessage(Exception error) {
    if (error is http.ClientException) {
      return 'Could not reach the protection server. Check that it is running and the URL is correct.';
    }
    if (error is TimeoutException) {
      return 'The request timed out. Check your connection and try again.';
    }
    return 'Something went wrong while contacting the server. Please try again.';
  }

  MediaType _mediaType(String filename) {
    final extension = filename.split('.').last.toLowerCase();
    return switch (extension) {
      'png' => MediaType('image', 'png'),
      'webp' => MediaType('image', 'webp'),
      _ => MediaType('image', 'jpeg'),
    };
  }

  void close() {
    if (_ownsClient) _client.close();
  }
}
