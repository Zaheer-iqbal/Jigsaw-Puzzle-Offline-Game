import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A 3D tactile claymorphic container widget for casual games.
/// Provides puffy depth, soft multi-layered shadows, and top-edge light highlights.
class ClayContainer extends StatelessWidget {
  final Widget? child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color color;
  final Color? bevelColor;
  final Gradient? gradient;
  final BorderRadius borderRadius;
  final double depth;
  final BoxBorder? border;

  const ClayContainer({
    super.key,
    this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.color = Colors.white,
    this.bevelColor,
    this.gradient,
    this.borderRadius = const BorderRadius.all(Radius.circular(22)),
    this.depth = 5.0,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    // Generate bevel tone if not provided
    final effectiveBevel = bevelColor ??
        Color.alphaBlend(
          Colors.black.withValues(alpha: 0.28),
          color,
        );

    return Container(
      width: width,
      height: height,
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: gradient == null ? color : null,
        gradient: gradient ??
            LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.alphaBlend(Colors.white.withValues(alpha: 0.15), color),
                color,
                Color.alphaBlend(Colors.black.withValues(alpha: 0.08), color),
              ],
            ),
        borderRadius: borderRadius,
        border: border ??
            Border.all(
              color: Colors.white.withValues(alpha: 0.25),
              width: 1.2,
            ),
        boxShadow: [
          // 1. Solid 3D Clay bottom bevel edge
          if (depth > 0)
            BoxShadow(
              color: effectiveBevel,
              offset: Offset(0, depth),
              blurRadius: 0,
            ),
          // 2. Soft atmospheric drop shadow (floating elevation)
          if (depth > 0)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.22),
              offset: Offset(0, depth + 3),
              blurRadius: depth * 2.2,
            ),
          // 3. Top subtle ambient glow
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.12),
            offset: const Offset(0, -1),
            blurRadius: 2,
          ),
        ],
      ),
      child: child,
    );
  }
}

/// A tactile 3D Claymorphic Button that physically presses down when touched.
class ClayButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final Color color;
  final Color? bevelColor;
  final Gradient? gradient;
  final BorderRadius borderRadius;
  final double depth;

  const ClayButton({
    super.key,
    required this.child,
    this.onTap,
    this.width,
    this.height,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
    this.margin,
    this.color = const Color(0xFFFFB300),
    this.bevelColor,
    this.gradient,
    this.borderRadius = const BorderRadius.all(Radius.circular(24)),
    this.depth = 4.5,
  });

  @override
  State<ClayButton> createState() => _ClayButtonState();
}

class _ClayButtonState extends State<ClayButton> {
  bool _isPressed = false;

  void _handleTapDown(TapDownDetails _) {
    if (widget.onTap == null) return;
    HapticFeedback.lightImpact();
    setState(() => _isPressed = true);
  }

  void _handleTapUp(TapUpDetails _) {
    if (_isPressed) setState(() => _isPressed = false);
  }

  void _handleTapCancel() {
    if (_isPressed) setState(() => _isPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    final effectiveDepth = _isPressed ? 1.0 : widget.depth;
    final effectiveBevel = widget.bevelColor ??
        Color.alphaBlend(
          Colors.black.withValues(alpha: 0.32),
          widget.color,
        );

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 70),
        curve: Curves.easeOutQuad,
        width: widget.width,
        height: widget.height,
        margin: widget.margin,
        padding: widget.padding,
        transform: Matrix4.translationValues(
          0,
          _isPressed ? (widget.depth - 1.0) : 0,
          0,
        ),
        decoration: BoxDecoration(
          color: widget.gradient == null ? widget.color : null,
          gradient: widget.gradient ??
              LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color.alphaBlend(Colors.white.withValues(alpha: 0.28), widget.color),
                  widget.color,
                  Color.alphaBlend(Colors.black.withValues(alpha: 0.12), widget.color),
                ],
              ),
          borderRadius: widget.borderRadius,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.35),
            width: 1.2,
          ),
          boxShadow: [
            // 3D Bevel edge
            BoxShadow(
              color: effectiveBevel,
              offset: Offset(0, effectiveDepth),
              blurRadius: 0,
            ),
            // Floating Drop Shadow
            BoxShadow(
              color: Colors.black.withValues(alpha: _isPressed ? 0.10 : 0.24),
              offset: Offset(0, effectiveDepth + (_isPressed ? 1 : 3)),
              blurRadius: effectiveDepth * 1.8,
            ),
            // Top soft highlight glow
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.20),
              offset: const Offset(0, -1),
              blurRadius: 1.5,
            ),
          ],
        ),
        child: widget.child,
      ),
    );
  }
}
