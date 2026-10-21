import 'package:flutter/material.dart';

enum DeviceScreenType { mobile, tablet, desktop }

class Responsive extends StatelessWidget {
  final Widget Function(BuildContext context, BoxConstraints constraints) portrait;
  final Widget Function(BuildContext context, BoxConstraints constraints)? landscape;

  const Responsive({
    super.key,
    required this.portrait,
    this.landscape,
  });

  static bool isLandscape(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.landscape;
  }

  static bool isPortrait(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.portrait;
  }

  static bool isTablet(BuildContext context) {
    final shortestSide = MediaQuery.of(context).size.shortestSide;
    return shortestSide >= 600;
  }

  static DeviceScreenType getDeviceType(BuildContext context) {
    final shortest = MediaQuery.of(context).size.shortestSide;
    if (shortest >= 900) return DeviceScreenType.desktop;
    if (shortest >= 600) return DeviceScreenType.tablet;
    return DeviceScreenType.mobile;
  }

  /// Calculates safe game board dimensions given available viewport space and target aspect ratio.
  static Size computeBoardSize({
    required double availableWidth,
    required double availableHeight,
    required double imageAspectRatio, // width / height
    double paddingRatio = 0.92,
  }) {
    final maxWidth = availableWidth * paddingRatio;
    final maxHeight = availableHeight * paddingRatio;

    var width = maxWidth;
    var height = width / imageAspectRatio;

    if (height > maxHeight) {
      height = maxHeight;
      width = height * imageAspectRatio;
    }

    return Size(width, height);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final orientation = MediaQuery.of(context).orientation;
        if (orientation == Orientation.landscape && landscape != null) {
          return landscape!(context, constraints);
        }
        return portrait(context, constraints);
      },
    );
  }
}
