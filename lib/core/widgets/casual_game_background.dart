import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jigsaw_pro/features/settings/presentation/controllers/settings_controller.dart';

/// Reusable Casual Game Background with decorative floating cloud pills and customizable screen themes.
/// Shared across HomePage, GalleryPage, SplashPage, ShopPage, SettingsPage, WinPage, etc.
class CasualGameBackground extends StatelessWidget {
  final Widget child;

  const CasualGameBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    if (Get.isRegistered<SettingsController>()) {
      final settings = Get.find<SettingsController>();
      return Obx(() {
        final theme = settings.screenTheme.value;
        return Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: CasualCloudPillsPainter(themeKey: theme),
              ),
            ),
            child,
          ],
        );
      });
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Stack(
      children: [
        Positioned.fill(
          child: CustomPaint(
            painter: CasualCloudPillsPainter(themeKey: isDark ? 'midnightNavy' : 'azureSky'),
          ),
        ),
        child,
      ],
    );
  }
}

class CasualCloudPillsPainter extends CustomPainter {
  final String themeKey;

  const CasualCloudPillsPainter({this.themeKey = 'azureSky'});

  @override
  void paint(Canvas canvas, Size size) {
    // Determine gradient colors & cloud pill highlights based on themeKey
    List<Color> gradientColors;
    Color pillLight;
    Color pillDark;

    switch (themeKey) {
      case 'midnightNavy':
        gradientColors = const [
          Color(0xFF0F1A2A),
          Color(0xFF16263D),
          Color(0xFF09121E),
        ];
        pillLight = const Color(0xFF38BDF8).withValues(alpha: 0.08);
        pillDark = Colors.black.withValues(alpha: 0.30);
        break;

      case 'sunsetPurple':
        gradientColors = const [
          Color(0xFF4A148C),
          Color(0xFF7B1FA2),
          Color(0xFFAD1457),
        ];
        pillLight = Colors.white.withValues(alpha: 0.14);
        pillDark = const Color(0xFF311B92).withValues(alpha: 0.28);
        break;

      case 'emeraldForest':
        gradientColors = const [
          Color(0xFF004D40),
          Color(0xFF00695C),
          Color(0xFF00796B),
        ];
        pillLight = Colors.white.withValues(alpha: 0.14);
        pillDark = const Color(0xFF00332C).withValues(alpha: 0.28);
        break;

      case 'goldenAmber':
        gradientColors = const [
          Color(0xFFE65100),
          Color(0xFFF57C00),
          Color(0xFFFFB300),
        ];
        pillLight = Colors.white.withValues(alpha: 0.18);
        pillDark = const Color(0xFFBF360C).withValues(alpha: 0.22);
        break;

      case 'amoledDark':
        gradientColors = const [
          Color(0xFF0A0E14),
          Color(0xFF131922),
          Color(0xFF05080C),
        ];
        pillLight = const Color(0xFF64748B).withValues(alpha: 0.08);
        pillDark = Colors.black.withValues(alpha: 0.40);
        break;

      case 'azureSky':
      default:
        gradientColors = const [
          Color(0xFF29B6F6),
          Color(0xFF42A5F5),
          Color(0xFF5C6BC0),
        ];
        pillLight = Colors.white.withValues(alpha: 0.15);
        pillDark = const Color(0xFF1565C0).withValues(alpha: 0.14);
        break;
    }

    // 1. Fullscreen Canvas Gradient
    final bgPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(size.width / 2, 0),
        Offset(size.width / 2, size.height),
        gradientColors,
        const [0.0, 0.55, 1.0],
      );
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // 2. Decorative Floating Rounded Cloud Pills
    final paintLight = Paint()
      ..color = pillLight
      ..style = PaintingStyle.fill;

    final paintDark = Paint()
      ..color = pillDark
      ..style = PaintingStyle.fill;

    // Top-left floating pill
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(-30, size.height * 0.13, size.width * 0.48, 38),
        const Radius.circular(19),
      ),
      paintLight,
    );

    // Top-right floating pill
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.68, size.height * 0.08, size.width * 0.42, 52),
        const Radius.circular(26),
      ),
      paintLight,
    );

    // Mid-left pill
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(-20, size.height * 0.38, size.width * 0.35, 42),
        const Radius.circular(21),
      ),
      paintDark,
    );

    // Mid-right pill
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.62, size.height * 0.50, size.width * 0.45, 54),
        const Radius.circular(27),
      ),
      paintLight,
    );

    // Bottom subtle pill
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.08, size.height * 0.70, size.width * 0.52, 46),
        const Radius.circular(23),
      ),
      paintDark,
    );
  }

  @override
  bool shouldRepaint(covariant CasualCloudPillsPainter oldDelegate) => oldDelegate.themeKey != themeKey;
}
