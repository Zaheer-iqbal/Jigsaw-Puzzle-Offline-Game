import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:jigsaw_pro/features/puzzle/domain/engine/edge_generator.dart';
import 'package:jigsaw_pro/features/puzzle/domain/engine/jigsaw_path_builder.dart';

class PreRenderedPiece {
  final ui.Image image;
  final Path path;
  final double scale;
  final double margin;

  const PreRenderedPiece({
    required this.image,
    required this.path,
    required this.scale,
    required this.margin,
  });

  void dispose() {
    image.dispose();
  }
}

class PieceImagePreRenderer {
  PieceImagePreRenderer._();

  /// Pre-renders every piece into an optimized cached [ui.Image] using [ui.PictureRecorder].
  /// Yields asynchronously to report progress and maintain UI responsiveness.
  static Future<Map<String, PreRenderedPiece>> preRenderAll({
    required ui.Image sourceImage,
    required int rows,
    required int cols,
    required double boardW,
    required double boardH,
    required EdgeGenerator edgeGenerator,
    required void Function(double progress) onProgress,
  }) async {
    final pieceW = boardW / cols;
    final pieceH = boardH / rows;
    final margin = edgeGenerator.flatEdges ? 0.0 : (pieceW < pieceH ? pieceW : pieceH) * 0.25;

    // Adjust scale based on piece count to balance crispness vs memory budget
    final totalPieces = rows * cols;
    final scale = totalPieces >= 400 ? 1.0 : (totalPieces >= 200 ? 1.25 : 1.5);

    // Source image scaling to board dimensions
    final srcRect = Rect.fromLTWH(0, 0, sourceImage.width.toDouble(), sourceImage.height.toDouble());
    final dstRect = Rect.fromLTWH(0, 0, boardW, boardH);

    final result = <String, PreRenderedPiece>{};
    var completed = 0;

    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = const Color(0x44FFFFFF);

    final darkOutlinePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = const Color(0x22000000);

    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        final edges = edgeGenerator.edgesFor(r, c);
        final path = JigsawPathBuilder.buildPiecePath(
          pieceW: pieceW,
          pieceH: pieceH,
          margin: margin,
          edges: edges,
        );

        final targetW = ((pieceW + 2 * margin) * scale).ceil();
        final targetH = ((pieceH + 2 * margin) * scale).ceil();

        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder);

        canvas.scale(scale, scale);
        canvas.clipPath(path);

        // Translate so board (c*pieceW, r*pieceH) maps to local (margin, margin)
        canvas.save();
        canvas.translate(margin - c * pieceW, margin - r * pieceH);
        canvas.drawImageRect(sourceImage, srcRect, dstRect, Paint()..filterQuality = FilterQuality.medium);
        canvas.restore();

        // Subtle bevel stroke
        canvas.drawPath(path, darkOutlinePaint);
        canvas.drawPath(path, strokePaint);

        final picture = recorder.endRecording();
        final image = await picture.toImage(targetW, targetH);
        picture.dispose();

        result['${r}_$c'] = PreRenderedPiece(
          image: image,
          path: path,
          scale: scale,
          margin: margin,
        );

        completed++;
        // Report progress
        onProgress(completed / totalPieces);

        // Yield to event loop every 8 pieces so UI frame updates seamlessly
        if (completed % 8 == 0) {
          await Future.delayed(Duration.zero);
        }
      }
    }

    return result;
  }
}
