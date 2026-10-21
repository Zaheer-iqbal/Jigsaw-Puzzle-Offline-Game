import 'dart:math';

/// Representation of edges for a single piece.
/// Clockwise order: top, right, bottom, left.
/// Values: 1 = Tab (outward), -1 = Blank (inward), 0 = Flat border.
class PieceEdges {
  final int top;
  final int right;
  final int bottom;
  final int left;

  const PieceEdges({
    required this.top,
    required this.right,
    required this.bottom,
    required this.left,
  });

  List<int> toList() => [top, right, bottom, left];

  bool get isBorder => top == 0 || right == 0 || bottom == 0 || left == 0;
}

class EdgeGenerator {
  final int rows;
  final int cols;
  final int seed;

  late final List<List<int>> _right;
  late final List<List<int>> _bottom;

  EdgeGenerator({
    required this.rows,
    required this.cols,
    required this.seed,
  }) {
    _generate();
  }

  void _generate() {
    final rnd = Random(seed);

    _right = List.generate(
      rows,
      (r) => List.generate(
        cols,
        (c) => c == cols - 1 ? 0 : (rnd.nextBool() ? 1 : -1),
      ),
    );

    _bottom = List.generate(
      rows,
      (r) => List.generate(
        cols,
        (c) => r == rows - 1 ? 0 : (rnd.nextBool() ? 1 : -1),
      ),
    );
  }

  PieceEdges edgesFor(int r, int c) {
    final top = r == 0 ? 0 : -_bottom[r - 1][c];
    final right = _right[r][c];
    final bottom = _bottom[r][c];
    final left = c == 0 ? 0 : -_right[r][c - 1];

    return PieceEdges(
      top: top,
      right: right,
      bottom: bottom,
      left: left,
    );
  }
}
