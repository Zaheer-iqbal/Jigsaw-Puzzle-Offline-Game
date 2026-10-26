import 'dart:ui';
import 'package:jigsaw_pro/core/config/app_config.dart';
import 'package:jigsaw_pro/features/puzzle/domain/engine/edge_generator.dart';

class JigsawPathBuilder {
  JigsawPathBuilder._();

  /// Builds the closed Path for a jigsaw piece in local coordinates,
  /// where the piece's cell body starts at (margin, margin).
  static Path buildPiecePath({
    required double pieceW,
    required double pieceH,
    required double margin,
    required PieceEdges edges,
  }) {
    final path = Path();
    final tabHeight = margin * AppConfig.tabHeightRatio;

    // Corner points in local coordinates
    final topLeft = Offset(margin, margin);
    final topRight = Offset(margin + pieceW, margin);
    final bottomRight = Offset(margin + pieceW, margin + pieceH);
    final bottomLeft = Offset(margin, margin + pieceH);

    path.moveTo(topLeft.dx, topLeft.dy);

    // 1. Top Edge (Left to Right)
    _drawJigsawEdge(path, topLeft, topRight, edges.top, tabHeight);

    // 2. Right Edge (Top to Bottom)
    _drawJigsawEdge(path, topRight, bottomRight, edges.right, tabHeight);

    // 3. Bottom Edge (Right to Left)
    _drawJigsawEdge(path, bottomRight, bottomLeft, edges.bottom, tabHeight);

    // 4. Left Edge (Bottom to Top)
    _drawJigsawEdge(path, bottomLeft, topLeft, edges.left, tabHeight);

    path.close();
    return path;
  }

  static void _drawJigsawEdge(
    Path path,
    Offset p0,
    Offset p1,
    int edgeValue, // 1 = tab, -1 = blank, 0 = flat
    double tabHeight,
  ) {
    if (edgeValue == 0) {
      path.lineTo(p1.dx, p1.dy);
      return;
    }

    final dx = p1.dx - p0.dx;
    final dy = p1.dy - p0.dy;
    final len = Offset(dx, dy).distance;
    if (len == 0) return;

    final ux = dx / len;
    final uy = dy / len;

    // Outward normal (pointing right of direction of travel)
    // Scaled by edgeValue (+1 for outward tab, -1 for inward blank)
    final nx = uy * edgeValue;
    final ny = -ux * edgeValue;

    final tabStart = Offset(
      p0.dx + ux * (0.38 * len),
      p0.dy + uy * (0.38 * len),
    );

    final tabEnd = Offset(
      p0.dx + ux * (0.62 * len),
      p0.dy + uy * (0.62 * len),
    );

    // Smooth gentle curve without balloon overhang
    final cp1 = Offset(
      p0.dx + ux * (0.40 * len) + nx * tabHeight,
      p0.dy + uy * (0.40 * len) + ny * tabHeight,
    );

    final cp2 = Offset(
      p0.dx + ux * (0.60 * len) + nx * tabHeight,
      p0.dy + uy * (0.60 * len) + ny * tabHeight,
    );

    // Straight segment to neck base
    path.lineTo(tabStart.dx, tabStart.dy);

    // Smooth rounded knob
    path.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, tabEnd.dx, tabEnd.dy);

    // Straight segment to corner
    path.lineTo(p1.dx, p1.dy);
  }
}
