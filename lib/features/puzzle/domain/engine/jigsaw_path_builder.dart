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
      p0.dx + ux * (0.36 * len),
      p0.dy + uy * (0.36 * len),
    );

    final tabEnd = Offset(
      p0.dx + ux * (0.64 * len),
      p0.dy + uy * (0.64 * len),
    );

    // Control points at 20% and 80% along edge length, with 1.33x overhang height
    final effectiveHeight = tabHeight * AppConfig.tabOverhangRatio;
    final cp1 = Offset(
      p0.dx + ux * (0.20 * len) + nx * effectiveHeight,
      p0.dy + uy * (0.20 * len) + ny * effectiveHeight,
    );

    final cp2 = Offset(
      p0.dx + ux * (0.80 * len) + nx * effectiveHeight,
      p0.dy + uy * (0.80 * len) + ny * effectiveHeight,
    );

    // Straight segment to neck base
    path.lineTo(tabStart.dx, tabStart.dy);

    // Rounded bulb knob with overhang
    path.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, tabEnd.dx, tabEnd.dy);

    // Straight segment to corner
    path.lineTo(p1.dx, p1.dy);
  }
}
