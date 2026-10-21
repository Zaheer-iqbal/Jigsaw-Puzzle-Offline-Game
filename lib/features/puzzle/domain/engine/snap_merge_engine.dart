import 'dart:math';
import 'dart:ui';
import 'package:jigsaw_pro/core/config/app_config.dart';
import 'package:jigsaw_pro/features/puzzle/domain/entities/puzzle_models.dart';

class SnapResult {
  final bool didSnap;
  final bool didLockToBoard;
  final bool isPuzzleComplete;
  final int affectedGroupId;

  const SnapResult({
    required this.didSnap,
    required this.didLockToBoard,
    required this.isPuzzleComplete,
    required this.affectedGroupId,
  });
}

class SnapMergeEngine {
  final int rows;
  final int cols;
  final double pieceW;
  final double pieceH;
  final double threshold;

  static const int boardGroupId = 0;

  SnapMergeEngine({
    required this.rows,
    required this.cols,
    required this.pieceW,
    required this.pieceH,
  }) : threshold = min(pieceW, pieceH) * AppConfig.snapThresholdRatio;

  /// Executes the snap-and-merge algorithm on the dropped [activeGroupId].
  /// Returns a [SnapResult] containing whether snapping/locking occurred and if puzzle is solved.
  SnapResult processDrop({
    required int activeGroupId,
    required Map<String, PieceModel> piecesMap, // key: "r_c"
    required Map<int, GroupModel> groupsMap,
  }) {
    var didSnapOverall = false;
    var didLockOverall = false;
    var currentActiveId = activeGroupId;

    for (var iteration = 0; iteration < 30; iteration++) {
      final activePieces = piecesMap.values
          .where((p) => p.groupId == currentActiveId)
          .toList();

      if (activePieces.isEmpty) break;

      _CandidateMatch? bestMatch;

      for (final pieceA in activePieces) {
        final offsetA = pieceA.currentOffset(pieceW, pieceH);

        // Candidate 1: Check if Piece A can snap directly to its own board slot (target offset 0)
        final distToBoard = offsetA.distance;
        if (distToBoard < threshold) {
          if (bestMatch == null || distToBoard < bestMatch.dist) {
            bestMatch = _CandidateMatch(
              targetGroupId: boardGroupId,
              delta: -offsetA,
              dist: distToBoard,
              targetIsBoard: true,
            );
          }
        }

        // Candidates 2: Check 4 cardinal neighbors (up, down, left, right)
        final neighborCoords = [
          (pieceA.row - 1, pieceA.col), // Top
          (pieceA.row + 1, pieceA.col), // Bottom
          (pieceA.row, pieceA.col - 1), // Left
          (pieceA.row, pieceA.col + 1), // Right
        ];

        for (final (nr, nc) in neighborCoords) {
          if (nr < 0 || nr >= rows || nc < 0 || nc >= cols) continue;
          final neighborPiece = piecesMap['${nr}_$nc'];
          if (neighborPiece == null) continue;

          // Ignore neighbors that are already in the same group
          if (neighborPiece.groupId == currentActiveId) continue;

          final offsetB = neighborPiece.currentOffset(pieceW, pieceH);
          final distToNeighbor = (offsetA - offsetB).distance;

          if (distToNeighbor < threshold) {
            if (bestMatch == null || distToNeighbor < bestMatch.dist) {
              bestMatch = _CandidateMatch(
                targetGroupId: neighborPiece.groupId,
                delta: offsetB - offsetA,
                dist: distToNeighbor,
                targetIsBoard: neighborPiece.groupId == boardGroupId,
              );
            }
          }
        }
      }

      // No valid snap found within threshold
      if (bestMatch == null) break;

      didSnapOverall = true;

      // 1. Shift all pieces in active group by delta
      for (final piece in activePieces) {
        piece.pos += bestMatch.delta;
      }

      // 2. Merge active group into candidate group
      final targetGroupId = bestMatch.targetGroupId;

      if (bestMatch.targetIsBoard || targetGroupId == boardGroupId) {
        didLockOverall = true;
        // Lock all pieces to exact zero-drift board coordinates
        for (final piece in activePieces) {
          piece.pos = piece.correctPos(pieceW, pieceH);
          piece.groupId = boardGroupId;
        }

        // Ensure board group exists and is marked locked
        groupsMap[boardGroupId] ??= GroupModel(id: boardGroupId, locked: true, z: 0);
        groupsMap.remove(currentActiveId);
        currentActiveId = boardGroupId;
        break; // Board lock ends further merges
      } else {
        // Merge with another floating piece group
        for (final piece in activePieces) {
          piece.groupId = targetGroupId;
        }
        groupsMap.remove(currentActiveId);
        currentActiveId = targetGroupId;
      }
    }

    // Check if all pieces are now locked in board group
    final totalPieces = rows * cols;
    final lockedPiecesCount = piecesMap.values
        .where((p) => p.groupId == boardGroupId)
        .length;
    final isComplete = lockedPiecesCount == totalPieces;

    return SnapResult(
      didSnap: didSnapOverall,
      didLockToBoard: didLockOverall,
      isPuzzleComplete: isComplete,
      affectedGroupId: currentActiveId,
    );
  }
}

class _CandidateMatch {
  final int targetGroupId;
  final Offset delta;
  final double dist;
  final bool targetIsBoard;

  const _CandidateMatch({
    required this.targetGroupId,
    required this.delta,
    required this.dist,
    required this.targetIsBoard,
  });
}
