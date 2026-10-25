import 'package:flutter/foundation.dart';

class AppState extends ChangeNotifier {
  String? latestHash;
  Uint8List? latestOriginalImage;
  Uint8List? latestProcessedImage;
  int processedImages = 0;
  int potentialMatches = 0;

  void recordProtection({
    required String hash,
    required Uint8List originalImage,
    required Uint8List processedImage,
  }) {
    latestHash = hash;
    latestOriginalImage = originalImage;
    latestProcessedImage = processedImage;
    processedImages++;
    notifyListeners();
  }

  void recordMatches(int count) {
    potentialMatches += count;
    notifyListeners();
  }
}
