import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// Reusable Casual Game Sky Background with decorative floating cloud pills.
/// Shared across HomePage, GalleryPage, SplashPage, ShopPage, SettingsPage, WinPage, etc.
class CasualGameBackground extends StatelessWidget {
  final Widget child;

  const CasualGameBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        Positioned.fill(
          child: CustomPaint(
            painter: CasualCloudPillsPainter(isDark: isDark),
          ),
        ),
        child,
      ],
    );
  }
}

class CasualCloudPillsPainter extends CustomPainter {
  final bool isDark;
  const CasualCloudPillsPainter({this.isDark = false});

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Light: Playful Azure Sky Gradient | Dark: Deep Obsidian & Midnight Navy Casual Night
    final bgPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(size.width / 2, 0),
        Offset(size.width / 2, size.height),
        isDark
            ? const [
                Color(0xFF0F1A2A), // Top deep midnight
                Color(0xFF16263D), // Mid dark navy
                Color(0xFF09121E), // Bottom obsidian
              ]
            : const [
                Color(0xFF29B6F6), // Top bright azure
                Color(0xFF42A5F5), // Mid vibrant sky blue
                Color(0xFF5C6BC0), // Soft indigo base
              ],
        const [0.0, 0.55, 1.0],
      );
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // 2. Decorative Floating Rounded Cloud Pills
    final pillPaintLight = Paint()
      ..color = (isDark ? const Color(0xFF38BDF8) : Colors.white)
          .withValues(alpha: isDark ? 0.08 : 0.15)
      ..style = PaintingStyle.fill;

    final pillPaintDark = Paint()
      ..color = (isDark ? Colors.black : const Color(0xFF1565C0))
          .withValues(alpha: isDark ? 0.30 : 0.14)
      ..style = PaintingStyle.fill;

    // Top-left floating pill
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(-30, size.height * 0.13, size.width * 0.48, 38),
        const Radius.circular(19),
      ),
      pillPaintLight,
    );

    // Top-right floating pill
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.68, size.height * 0.08, size.width * 0.42, 52),
        const Radius.circular(26),
      ),
      pillPaintLight,
    );

    // Mid-left pill
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(-20, size.height * 0.38, size.width * 0.35, 42),
        const Radius.circular(21),
      ),
      pillPaintDark,
    );

    // Mid-right pill
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.62, size.height * 0.50, size.width * 0.45, 54),
        const Radius.circular(27),
      ),
      pillPaintLight,
    );

    // Bottom subtle pill
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.08, size.height * 0.70, size.width * 0.52, 46),
        const Radius.circular(23),
      ),
      pillPaintDark,
    );
  }

  @override
  bool shouldRepaint(covariant CasualCloudPillsPainter oldDelegate) => oldDelegate.isDark != isDark;
}
