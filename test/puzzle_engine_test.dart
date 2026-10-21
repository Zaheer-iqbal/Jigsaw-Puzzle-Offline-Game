import 'package:flutter_test/flutter_test.dart';
import 'package:jigsaw_pro/features/puzzle/domain/entities/puzzle_models.dart';
import 'package:jigsaw_pro/features/puzzle/domain/engine/edge_generator.dart';
import 'package:jigsaw_pro/features/puzzle/domain/engine/grid_calculator.dart';
import 'package:jigsaw_pro/features/puzzle/domain/engine/snap_merge_engine.dart';

void main() {
  group('GridCalculator Tests', () {
    test('Calculates reasonable rows and columns across aspect ratios', () {
      final dims1 = GridCalculator.calculate(n: 12, aspectRatio: 4 / 3);
      expect(dims1.cols, greaterThanOrEqualTo(2));
      expect(dims1.rows, greaterThanOrEqualTo(2));
      expect(dims1.actualCount, closeTo(12, 3));

      final dims2 = GridCalculator.calculate(n: 100, aspectRatio: 16 / 9);
      expect(dims2.cols, greaterThan(dims2.rows));
      expect(dims2.actualCount, closeTo(100, 10));

      final dims3 = GridCalculator.calculate(n: 400, aspectRatio: 1.0);
      expect(dims3.cols, 20);
      expect(dims3.rows, 20);
      expect(dims3.actualCount, 400);
    });
  });

  group('EdgeGenerator Invariant Tests', () {
    test('Touching edges sum to zero and outer borders are flat', () {
      for (final seed in [42, 999, 1337]) {
        const rows = 6;
        const cols = 8;
        final generator = EdgeGenerator(rows: rows, cols: cols, seed: seed);

        for (var r = 0; r < rows; r++) {
          for (var c = 0; c < cols; c++) {
            final edges = generator.edgesFor(r, c);

            // Border edges must be 0
            if (r == 0) expect(edges.top, 0);
            if (r == rows - 1) expect(edges.bottom, 0);
            if (c == 0) expect(edges.left, 0);
            if (c == cols - 1) expect(edges.right, 0);

            // Internal edges must be +1 or -1
            if (r > 0) expect(edges.top.abs(), 1);
            if (r < rows - 1) expect(edges.bottom.abs(), 1);
            if (c > 0) expect(edges.left.abs(), 1);
            if (c < cols - 1) expect(edges.right.abs(), 1);

            // Invariant: touching neighbors sum to zero
            if (c < cols - 1) {
              final rightNeighbor = generator.edgesFor(r, c + 1);
              expect(edges.right + rightNeighbor.left, 0);
            }
            if (r < rows - 1) {
              final bottomNeighbor = generator.edgesFor(r + 1, c);
              expect(edges.bottom + bottomNeighbor.top, 0);
            }
          }
        }
      }
    });
  });

  group('SnapMergeEngine Tests', () {
    test('Snaps piece to board when within 28% threshold', () {
      const rows = 2;
      const cols = 2;
      const pieceW = 100.0;
      const pieceH = 100.0;
      final engine = SnapMergeEngine(
        rows: rows,
        cols: cols,
        pieceW: pieceW,
        pieceH: pieceH,
      );

      // Threshold is 28.0 px
      expect(engine.threshold, closeTo(28.0, 0.0001));

      // Piece (0, 0) placed at (10, 10) -> distance is ~14.14 < 28 -> should snap & lock
      final piece0 = PieceModel(
        row: 0,
        col: 0,
        pos: const Offset(10, 10),
        groupId: 1,
      );
      final piece1 = PieceModel(
        row: 0,
        col: 1,
        pos: const Offset(500, 500),
        groupId: 2,
      );
      final piece2 = PieceModel(
        row: 1,
        col: 0,
        pos: const Offset(600, 600),
        groupId: 3,
      );
      final piece3 = PieceModel(
        row: 1,
        col: 1,
        pos: const Offset(700, 700),
        groupId: 4,
      );

      final piecesMap = {
        '0_0': piece0,
        '0_1': piece1,
        '1_0': piece2,
        '1_1': piece3,
      };

      final groupsMap = {
        1: GroupModel(id: 1),
        2: GroupModel(id: 2),
        3: GroupModel(id: 3),
        4: GroupModel(id: 4),
      };

      final result = engine.processDrop(
        activeGroupId: 1,
        piecesMap: piecesMap,
        groupsMap: groupsMap,
      );

      expect(result.didSnap, isTrue);
      expect(result.didLockToBoard, isTrue);
      expect(piece0.pos, Offset.zero); // exact zero drift
      expect(piece0.groupId, SnapMergeEngine.boardGroupId);
      expect(result.isPuzzleComplete, isFalse);
    });

    test('Ignores drop beyond threshold', () {
      final engine = SnapMergeEngine(
        rows: 2,
        cols: 2,
        pieceW: 100.0,
        pieceH: 100.0,
      );

      final piece0 = PieceModel(
        row: 0,
        col: 0,
        pos: const Offset(80, 80), // dist = ~113 > 28 -> no snap
        groupId: 1,
      );

      final piecesMap = {'0_0': piece0};
      final groupsMap = {1: GroupModel(id: 1)};

      final result = engine.processDrop(
        activeGroupId: 1,
        piecesMap: piecesMap,
        groupsMap: groupsMap,
      );

      expect(result.didSnap, isFalse);
      expect(result.didLockToBoard, isFalse);
      expect(piece0.pos, const Offset(80, 80));
    });

    test('Merges adjacent neighbor pieces into a single group', () {
      final engine = SnapMergeEngine(
        rows: 2,
        cols: 2,
        pieceW: 100.0,
        pieceH: 100.0,
      );

      // Piece (0, 0) at (200, 200) -> offset = (200, 200)
      // Piece (0, 1) correct position is (100, 0).
      // If Piece (0, 1) is dropped at (305, 200), its offset is (305 - 100, 200 - 0) = (205, 200).
      // Distance between offsets = (205 - 200, 200 - 200) = 5 < 28 -> should merge!
      final piece0 = PieceModel(
        row: 0,
        col: 0,
        pos: const Offset(200, 200),
        groupId: 1,
      );
      final piece1 = PieceModel(
        row: 0,
        col: 1,
        pos: const Offset(305, 200),
        groupId: 2,
      );

      final piecesMap = {'0_0': piece0, '0_1': piece1};
      final groupsMap = {
        1: GroupModel(id: 1),
        2: GroupModel(id: 2),
      };

      final result = engine.processDrop(
        activeGroupId: 2,
        piecesMap: piecesMap,
        groupsMap: groupsMap,
      );

      expect(result.didSnap, isTrue);
      expect(result.didLockToBoard, isFalse); // floating group, not board
      expect(piece0.groupId, piece1.groupId);
      // Offset difference resolved
      expect((piece1.pos - piece0.pos).dx, closeTo(100.0, 0.001));
    });
  });
}
