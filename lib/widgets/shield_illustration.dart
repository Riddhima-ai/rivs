import 'package:flutter/material.dart';

class ShieldIllustration extends StatelessWidget {
  const ShieldIllustration({
    super.key,
    this.height = 150,
    this.maxWidth = 340,
  });

  static const assetPath = 'assets/images/privacy_girl.png';
  final double height;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth, maxHeight: height),
        child: AspectRatio(
          aspectRatio: 411 / 512,
          child: Image.asset(
            assetPath,
            fit: BoxFit.contain,
            alignment: Alignment.center,
          ),
        ),
      ),
    );
  }
}
