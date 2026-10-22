import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jigsaw_pro/core/theme/app_theme.dart';
import 'package:jigsaw_pro/features/puzzle/presentation/canvas/board_painter.dart';

void main() {
  testWidgets('BoardPainter paints all background styles without runtime argument errors', (tester) async {
    for (final style in BoardBackgroundStyle.values) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: CustomPaint(
                size: const Size(332.0, 221.5),
                painter: BoardPainter(
                  pieces: const {},
                  lockedPieceKeys: const {},
                  preRenderedPieces: const {},
                  boardSize: const Size(332.0, 221.5),
                  backgroundStyle: style,
                  showGhost: false,
                  rows: 4,
                  cols: 6,
                ),
              ),
            ),
          ),
        ),
      );
      expect(find.byType(CustomPaint), findsWidgets);
    }
  });
}
