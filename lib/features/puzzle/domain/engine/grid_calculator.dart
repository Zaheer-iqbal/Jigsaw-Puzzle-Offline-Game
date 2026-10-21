import 'dart:math';

class GridDimensions {
  final int targetCount;
  final int cols;
  final int rows;
  final int actualCount;

  const GridDimensions({
    required this.targetCount,
    required this.cols,
    required this.rows,
    required this.actualCount,
  });
}

class GridCalculator {
  GridCalculator._();

  /// Calculates the best rows and columns for target piece count [n] given picture [aspectRatio] (width / height).
  static GridDimensions calculate({
    required int n,
    required double aspectRatio,
  }) {
    if (aspectRatio <= 0) aspectRatio = 1.0;

    var cols = max(2, (sqrt(n * aspectRatio)).round());
    var rows = max(2, (n / cols).round());

    // Fine-tune to ensure actual count is as close to target as possible
    var actual = cols * rows;

    // Check adjacent row/col combinations for closer match if needed
    final opt1 = cols * max(2, (n / cols).floor());
    final opt2 = cols * max(2, (n / cols).ceil());
    if ((opt1 - n).abs() < (actual - n).abs() && opt1 >= 4) {
      rows = max(2, (n / cols).floor());
      actual = cols * rows;
    } else if ((opt2 - n).abs() < (actual - n).abs() && opt2 >= 4) {
      rows = max(2, (n / cols).ceil());
      actual = cols * rows;
    }

    return GridDimensions(
      targetCount: n,
      cols: cols,
      rows: rows,
      actualCount: cols * rows,
    );
  }

  static double calculateMargin(double pieceW, double pieceH) {
    return min(pieceW, pieceH) * 0.3;
  }
}
