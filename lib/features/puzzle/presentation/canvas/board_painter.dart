import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:jigsaw_pro/core/theme/app_theme.dart';
import 'package:jigsaw_pro/features/puzzle/domain/entities/puzzle_models.dart';
import 'package:jigsaw_pro/features/puzzle/presentation/canvas/piece_image_pre_renderer.dart';

class BoardPainter extends CustomPainter {
  final Map<String, PieceModel> pieces;
  final Map<int, GroupModel> groups;
  final Map<String, PreRenderedPiece> preRenderedPieces;
  final int? activeGroupId;
  final Offset activeDragDelta;
  final Size boardSize;
  final ui.Image? fullImage;
  final bool showGhost;
  final bool edgesOnly;
  final String? hintPieceKey;
  final BoardBackgroundStyle backgroundStyle;

  BoardPainter({
    required this.pieces,
    required this.groups,
    required this.preRenderedPieces,
    required this.activeGroupId,
    required this.activeDragDelta,
    required this.boardSize,
    this.fullImage,
    required this.showGhost,
    required this.edgesOnly,
    this.hintPieceKey,
    required this.backgroundStyle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw subtle board boundary / felt surface
    final boardRect = Rect.fromLTWH(0, 0, boardSize.width, boardSize.height);
    final boardBorderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final boardBgPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.25)
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(boardRect, const Radius.circular(8)),
      boardBgPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(boardRect, const Radius.circular(8)),
      boardBorderPaint,
    );

    // 2. Draw ghost / preview image if toggled on
    if (showGhost && fullImage != null) {
      final ghostPaint = Paint()
        ..color = const Color(0x38FFFFFF)
        ..filterQuality = FilterQuality.medium;
      final srcRect = Rect.fromLTWH(0, 0, fullImage!.width.toDouble(), fullImage!.height.toDouble());
      canvas.drawImageRect(fullImage!, srcRect, boardRect, ghostPaint);
    }

    // 3. Draw Hint Target Slot if active
    if (hintPieceKey != null && pieces.containsKey(hintPieceKey)) {
      final hintPiece = pieces[hintPieceKey]!;
      final prePiece = preRenderedPieces[hintPieceKey];
      if (prePiece != null) {
        final hintSlotPos = hintPiece.correctPos(
          boardSize.width / (pieces.values.map((p) => p.col).reduce((a, b) => a > b ? a : b) + 1),
          boardSize.height / (pieces.values.map((p) => p.row).reduce((a, b) => a > b ? a : b) + 1),
        );

        canvas.save();
        canvas.translate(hintSlotPos.dx - prePiece.margin, hintSlotPos.dy - prePiece.margin);
        final hintSlotPaint = Paint()
          ..color = AppTheme.accentAmber.withValues(alpha: 0.85)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.5;
        canvas.drawPath(prePiece.path, hintSlotPaint);
        canvas.restore();
      }
    }

    // 4. Sort groups by z-index (locked at bottom z=0, active drag group at top)
    final sortedGroupIds = groups.keys.toList()
      ..sort((a, b) {
        if (a == activeGroupId) return 1;
        if (b == activeGroupId) return -1;
        final za = groups[a]?.z ?? 0;
        final zb = groups[b]?.z ?? 0;
        return za.compareTo(zb);
      });

    // 5. Draw pieces group by group
    for (final groupId in sortedGroupIds) {
      final isGroupActive = groupId == activeGroupId;
      final groupDelta = isGroupActive ? activeDragDelta : Offset.zero;
      final groupPieces = pieces.entries.where((e) => e.value.groupId == groupId);

      for (final entry in groupPieces) {
        final key = entry.key;
        final piece = entry.value;
        final preRendered = preRenderedPieces[key];
        if (preRendered == null) continue;

        final isLocked = groupId == 0;
        final isBorder = _isBorderPiece(piece);

        // Edges-only filter: Dim non-border unlocked pieces
        var opacity = 1.0;
        if (edgesOnly && !isLocked && !isBorder) {
          opacity = 0.22;
        }

        final piecePos = piece.pos + groupDelta;
        final drawPos = Offset(piecePos.dx - preRendered.margin, piecePos.dy - preRendered.margin);
        final imgW = preRendered.image.width.toDouble();
        final imgH = preRendered.image.height.toDouble();
        final dstW = imgW / preRendered.scale;
        final dstH = imgH / preRendered.scale;

        final srcRect = Rect.fromLTWH(0, 0, imgW, imgH);
        final dstRect = Rect.fromLTWH(drawPos.dx, drawPos.dy, dstW, dstH);

        // Shadow for active dragging group
        if (isGroupActive) {
          final shadowPaint = Paint()
            ..color = Colors.black.withValues(alpha: 0.35)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
          canvas.save();
          canvas.translate(drawPos.dx + 4, drawPos.dy + 6);
          canvas.drawPath(preRendered.path, shadowPaint);
          canvas.restore();
        }

        final piecePaint = Paint()
          ..filterQuality = FilterQuality.medium
          ..color = Color.fromRGBO(255, 255, 255, opacity);

        canvas.drawImageRect(preRendered.image, srcRect, dstRect, piecePaint);

        // Amber glow on the piece if it is the hint piece
        if (key == hintPieceKey) {
          final hintGlowPaint = Paint()
            ..color = AppTheme.accentAmber
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3.5;
          canvas.save();
          canvas.translate(drawPos.dx, drawPos.dy);
          canvas.drawPath(preRendered.path, hintGlowPaint);
          canvas.restore();
        }
      }
    }
  }

  bool _isBorderPiece(PieceModel piece) {
    final maxR = pieces.values.map((p) => p.row).reduce((a, b) => a > b ? a : b);
    final maxC = pieces.values.map((p) => p.col).reduce((a, b) => a > b ? a : b);
    return piece.row == 0 || piece.row == maxR || piece.col == 0 || piece.col == maxC;
  }

  @override
  bool shouldRepaint(covariant BoardPainter oldDelegate) {
    return true; // Driven by ValueNotifier & reactive GetX state
  }
}
