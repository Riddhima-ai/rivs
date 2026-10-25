import 'dart:convert';
import 'dart:typed_data';

class ShieldResponse {
  const ShieldResponse({required this.dhash, required this.imageBytes});

  final String dhash;
  final Uint8List imageBytes;

  factory ShieldResponse.fromJson(Map<String, dynamic> json) {
    final hash = json['dhash'] ?? json['hash'];
    final encodedImage =
        json['poisoned_image'] ??
        json['processed_image'] ??
        json['image_base64'] ??
        json['processed_image_base64'] ??
        json['image'];

    if (hash is! String || !RegExp(r'^[0-9a-fA-F]{16}$').hasMatch(hash)) {
      throw const FormatException(
        'The backend response must include a valid 64-bit hexadecimal dhash.',
      );
    }
    if (encodedImage is! String || encodedImage.trim().isEmpty) {
      throw const FormatException(
        'The backend response is missing its processed image.',
      );
    }

    final base64Value = encodedImage.contains(',')
        ? encodedImage.substring(encodedImage.indexOf(',') + 1)
        : encodedImage;
    late final Uint8List bytes;
    try {
      bytes = base64Decode(base64Value);
    } on FormatException {
      throw const FormatException(
        'The backend returned invalid Base64 image data.',
      );
    }
    if (bytes.isEmpty) {
      throw const FormatException(
        'The backend returned an empty processed image.',
      );
    }
    return ShieldResponse(dhash: hash.toLowerCase(), imageBytes: bytes);
  }
}
