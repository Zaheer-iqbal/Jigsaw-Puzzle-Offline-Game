import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:jigsaw_pro/core/theme/app_theme.dart';
import 'package:jigsaw_pro/features/puzzle/domain/entities/puzzle_models.dart';
import 'package:jigsaw_pro/features/puzzle/presentation/canvas/piece_image_pre_renderer.dart';

class BoardPainter extends CustomPainter {
  final Map<String, PieceModel> pieces;
  final Set<String> lockedPieceKeys;
  final Map<String, PreRenderedPiece> preRenderedPieces;
  final Size boardSize;
  final int rows;
  final int cols;
  final ui.Image? fullImage;
  final bool showGhost;
  final String? hintPieceKey;
  final BoardBackgroundStyle backgroundStyle;
  final double hintPulse;

  BoardPainter({
    required this.pieces,
    required this.lockedPieceKeys,
    required this.preRenderedPieces,
    required this.boardSize,
    required this.rows,
    required this.cols,
    this.fullImage,
    required this.showGhost,
    this.hintPieceKey,
    required this.backgroundStyle,
    this.hintPulse = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (boardSize.width <= 0 || boardSize.height <= 0) return;

    // Scale canvas so drawing matches on-screen widget size with zero overflow
    final scaleX = size.width / boardSize.width;
    final scaleY = size.height / boardSize.height;

    canvas.save();
    canvas.scale(scaleX, scaleY);

    final boardRect = Rect.fromLTWH(0, 0, boardSize.width, boardSize.height);
    const cornerRadius = Radius.circular(16);
    final boardRRect = RRect.fromRectAndRadius(boardRect, cornerRadius);

    final isLight = backgroundStyle == BoardBackgroundStyle.cleanLight;

    // 1. Deep realistic tabletop drop shadows
    final ambientShadowPaint = Paint()
      ..color = isLight ? Colors.black.withValues(alpha: 0.18) : Colors.black.withValues(alpha: 0.55)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 28);
    canvas.drawRRect(boardRRect.shift(const Offset(0, 16)), ambientShadowPaint);

    final contactShadowPaint = Paint()
      ..color = isLight ? Colors.black.withValues(alpha: 0.28) : Colors.black.withValues(alpha: 0.70)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawRRect(boardRRect.shift(const Offset(0, 5)), contactShadowPaint);

    // 2. Photorealistic wooden beveled frame
    const framePadding = 12.0;
    final frameRect = boardRect.inflate(framePadding);
    final frameRRect = RRect.fromRectAndRadius(frameRect, const Radius.circular(22));

    // Frame wood gradient
    final frameWoodPaint = Paint()
      ..shader = ui.Gradient.linear(
        frameRect.topLeft,
        frameRect.bottomRight,
        isLight
            ? const [
                Color(0xFFF3EFEA),
                Color(0xFFE4DFD8),
                Color(0xFFEDE8E2),
              ]
            : const [
                Color(0xFF2E211A),
                Color(0xFF1D140F),
                Color(0xFF281C15),
              ],
        const [0.0, 0.5, 1.0],
      )
      ..style = PaintingStyle.fill;
    canvas.drawRRect(frameRRect, frameWoodPaint);

    // Frame outer top-left highlight bevel (light source from top-left)
    final frameHighlightPaint = Paint()
      ..color = isLight ? Colors.white : Colors.white.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawRRect(frameRRect, frameHighlightPaint);

    // Frame outer bottom-right shadow bevel
    final frameShadowPaint = Paint()
      ..color = isLight ? Colors.black.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.60)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawRRect(frameRRect.deflate(0.5), frameShadowPaint);

    // Inner gold/brass inlay trim between wood frame and mat
    final goldInlayPaint = Paint()
      ..color = const Color(0xFFD4A346).withValues(alpha: isLight ? 0.75 : 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawRRect(boardRRect.inflate(1.2), goldInlayPaint);

    // 3. Vintage brass ornamental corner brackets
    _drawCornerBrackets(canvas, frameRect);

    // 4. Recessed velvet/felt puzzle mat surface
    final matPaint = Paint()
      ..shader = ui.Gradient.radial(
        Offset(boardSize.width * 0.5, boardSize.height * 0.4),
        boardSize.width * 0.8,
        [
          backgroundStyle.primaryColor,
          backgroundStyle.secondaryColor,
        ],
      )
      ..style = PaintingStyle.fill;
    canvas.drawRRect(boardRRect, matPaint);

    // Inner recessed edge shadow (sunken mat appearance)
    final innerShadowPaint = Paint()
      ..color = isLight ? Colors.black.withValues(alpha: 0.22) : Colors.black.withValues(alpha: 0.50)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    canvas.drawRRect(boardRRect.deflate(1.5), innerShadowPaint);

    // 5. Subtle piece matrix guide grooves
    if (rows > 0 && cols > 0) {
      final gridPaint = Paint()
        ..color = isLight ? Colors.black.withValues(alpha: 0.20) : Colors.white.withValues(alpha: 0.22)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2;

      final pieceW = boardSize.width / cols;
      final pieceH = boardSize.height / rows;

      for (var c = 1; c < cols; c++) {
        canvas.drawLine(Offset(c * pieceW, 0), Offset(c * pieceW, boardSize.height), gridPaint);
      }
      for (var r = 1; r < rows; r++) {
        canvas.drawLine(Offset(0, r * pieceH), Offset(boardSize.width, r * pieceH), gridPaint);
      }

      // Small subtle dot markers at grid intersections
      final dotPaint = Paint()
        ..color = isLight ? Colors.black.withValues(alpha: 0.28) : Colors.white.withValues(alpha: 0.30)
        ..style = PaintingStyle.fill;
      for (var r = 1; r < rows; r++) {
        for (var c = 1; c < cols; c++) {
          canvas.drawCircle(Offset(c * pieceW, r * pieceH), 2.0, dotPaint);
        }
      }
    }

    // 6. Preview / Watermark Artwork Guide
    // Always render a pleasant, subtle watermark guide so the board is NEVER an empty black box!
    // When showGhost is toggled ON (eye icon active), render at clear high opacity (0.65)!
    if (fullImage != null) {
      canvas.save();
      canvas.clipRRect(boardRRect);
      final watermarkOpacity = showGhost ? 0.65 : (isLight ? 0.24 : 0.18);
      final ghostPaint = Paint()
        ..color = Color.fromRGBO(255, 255, 255, watermarkOpacity)
        ..filterQuality = FilterQuality.high;
      final srcRect = Rect.fromLTWH(0, 0, fullImage!.width.toDouble(), fullImage!.height.toDouble());
      canvas.drawImageRect(fullImage!, srcRect, boardRect, ghostPaint);
      canvas.restore();
    }

    // 7. Animated hint target slot glow
    if (hintPieceKey != null && pieces.containsKey(hintPieceKey)) {
      final hintPiece = pieces[hintPieceKey]!;
      final prePiece = preRenderedPieces[hintPieceKey];
      if (prePiece != null && rows > 0 && cols > 0) {
        final pieceW = boardSize.width / cols;
        final pieceH = boardSize.height / rows;
        final hintSlotPos = hintPiece.correctPos(pieceW, pieceH);

        canvas.save();
        canvas.translate(hintSlotPos.dx - prePiece.margin, hintSlotPos.dy - prePiece.margin);

        // Pulsing golden aura
        final pulseAlpha = 0.35 + 0.35 * math.sin(hintPulse * math.pi);
        final glowPaint = Paint()
          ..color = AppTheme.accentAmber.withValues(alpha: pulseAlpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 10.0
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
        canvas.drawPath(prePiece.path, glowPaint);

        final linePaint = Paint()
          ..color = AppTheme.accentAmber
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.5;
        canvas.drawPath(prePiece.path, linePaint);

        canvas.restore();
      }
    }

    // 8. Draw all locked pieces on the board
    if (rows > 0 && cols > 0) {
      final pieceW = boardSize.width / cols;
      final pieceH = boardSize.height / rows;

      for (final key in lockedPieceKeys) {
        final piece = pieces[key];
        final preRendered = preRenderedPieces[key];
        if (piece == null || preRendered == null) continue;

        final piecePos = piece.correctPos(pieceW, pieceH);
        final drawPos = Offset(piecePos.dx - preRendered.margin, piecePos.dy - preRendered.margin);
        final imgW = preRendered.image.width.toDouble();
        final imgH = preRendered.image.height.toDouble();
        final dstW = imgW / preRendered.scale;
        final dstH = imgH / preRendered.scale;

        final srcRect = Rect.fromLTWH(0, 0, imgW, imgH);
        final dstRect = Rect.fromLTWH(drawPos.dx, drawPos.dy, dstW, dstH);

        final piecePaint = Paint()
          ..filterQuality = FilterQuality.high
          ..color = Colors.white;

        canvas.drawImageRect(preRendered.image, srcRect, dstRect, piecePaint);
      }
    }

    canvas.restore();
  }

  // Draw 4 luxury brass corner brackets on the outer frame
  void _drawCornerBrackets(Canvas canvas, Rect frameRect) {
    final bracketPaint = Paint()
      ..color = const Color(0xFFD4A346)
      ..style = PaintingStyle.fill;

    final bracketOutlinePaint = Paint()
      ..color = const Color(0xFF7A5818)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final rivetPaint = Paint()
      ..color = const Color(0xFF5A3E0C)
      ..style = PaintingStyle.fill;

    final rivetHighlight = Paint()
      ..color = Colors.white.withValues(alpha: 0.7)
      ..style = PaintingStyle.fill;

    const armLen = 26.0;
    const armThick = 6.0;

    void drawBracket(Offset corner, int dirX, int dirY) {
      final path = Path();
      path.moveTo(corner.dx, corner.dy);
      path.lineTo(corner.dx + dirX * armLen, corner.dy);
      path.lineTo(corner.dx + dirX * armLen, corner.dy + dirY * armThick);
      path.lineTo(corner.dx + dirX * armThick, corner.dy + dirY * armThick);
      path.lineTo(corner.dx + dirX * armThick, corner.dy + dirY * armLen);
      path.lineTo(corner.dx, corner.dy + dirY * armLen);
      path.close();

      canvas.drawPath(path, bracketPaint);
      canvas.drawPath(path, bracketOutlinePaint);

      // Rivets
      final r1 = Offset(corner.dx + dirX * (armLen * 0.65), corner.dy + dirY * (armThick * 0.5));
      final r2 = Offset(corner.dx + dirX * (armThick * 0.5), corner.dy + dirY * (armLen * 0.65));
      for (final r in [r1, r2]) {
        canvas.drawCircle(r, 2.0, rivetPaint);
        canvas.drawCircle(r.translate(-0.5, -0.5), 0.8, rivetHighlight);
      }
    }

    drawBracket(frameRect.topLeft, 1, 1);
    drawBracket(frameRect.topRight, -1, 1);
    drawBracket(frameRect.bottomLeft, 1, -1);
    drawBracket(frameRect.bottomRight, -1, -1);
  }

  @override
  bool shouldRepaint(covariant BoardPainter oldDelegate) {
    return true;
  }
}
