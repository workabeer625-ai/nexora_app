import 'package:flutter/material.dart';

class AppBrandIcon extends StatelessWidget {
  const AppBrandIcon({super.key, this.size = 24, this.borderRadius});

  final double size;
  final BorderRadius? borderRadius;

  static const String assetPath = 'assets/images/logo2.png';

  double get _visualScale {
    if (size <= 20) {
      return 1.35;
    }
    if (size <= 32) {
      return 1.24;
    }
    if (size <= 56) {
      return 1.14;
    }
    return 1.08;
  }

  @override
  Widget build(BuildContext context) {
    final visualSize = size * _visualScale;

    return SizedBox(
      width: size,
      height: size,
      child: OverflowBox(
        alignment: Alignment.center,
        minWidth: size,
        minHeight: size,
        maxWidth: visualSize,
        maxHeight: visualSize,
        child: ClipRRect(
          borderRadius:
              borderRadius ?? BorderRadius.circular(visualSize * 0.28),
          child: Image.asset(
            assetPath,
            width: visualSize,
            height: visualSize,
            fit: BoxFit.cover,
            filterQuality: FilterQuality.high,
          ),
        ),
      ),
    );
  }
}
