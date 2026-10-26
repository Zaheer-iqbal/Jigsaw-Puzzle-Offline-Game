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

    // Direct optimal presets for standard casual piece counts
    if (n == 12) {
      final cols = aspectRatio >= 1.0 ? 4 : 3;
      final rows = aspectRatio >= 1.0 ? 3 : 4;
      return GridDimensions(targetCount: 12, cols: cols, rows: rows, actualCount: 12);
    }
    if (n == 24) {
      final cols = aspectRatio >= 1.0 ? 6 : 4;
      final rows = aspectRatio >= 1.0 ? 4 : 6;
      return GridDimensions(targetCount: 24, cols: cols, rows: rows, actualCount: 24);
    }
    if (n == 48) {
      final cols = aspectRatio >= 1.0 ? 8 : 6;
      final rows = aspectRatio >= 1.0 ? 6 : 8;
      return GridDimensions(targetCount: 48, cols: cols, rows: rows, actualCount: 48);
    }
    if (n == 100) {
      final cols = aspectRatio >= 1.2 ? 12 : 10;
      final rows = aspectRatio >= 1.2 ? 8 : 10;
      return GridDimensions(targetCount: 100, cols: cols, rows: rows, actualCount: cols * rows);
    }
    if (n == 200) {
      final cols = aspectRatio >= 1.2 ? 16 : (aspectRatio <= 0.8 ? 12 : 14);
      final rows = aspectRatio >= 1.2 ? 12 : (aspectRatio <= 0.8 ? 16 : 14);
      return GridDimensions(targetCount: 200, cols: cols, rows: rows, actualCount: cols * rows);
    }
    if (n == 400) {
      final cols = aspectRatio >= 1.2 ? 24 : 20;
      final rows = aspectRatio >= 1.2 ? 16 : 20;
      return GridDimensions(targetCount: 400, cols: cols, rows: rows, actualCount: cols * rows);
    }

    // General fallback for custom piece counts
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
