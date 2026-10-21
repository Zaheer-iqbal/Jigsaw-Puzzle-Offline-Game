import 'dart:ui';

/// Represents a single piece in the puzzle grid.
class PieceModel {
  final int row;
  final int col;
  Offset pos; // cell top-left in board space
  int groupId;

  PieceModel({
    required this.row,
    required this.col,
    required this.pos,
    required this.groupId,
  });

  Offset correctPos(double pieceW, double pieceH) {
    return Offset(col * pieceW, row * pieceH);
  }

  Offset currentOffset(double pieceW, double pieceH) {
    return pos - correctPos(pieceW, pieceH);
  }

  PieceModel copyWith({
    int? row,
    int? col,
    Offset? pos,
    int? groupId,
  }) {
    return PieceModel(
      row: row ?? this.row,
      col: col ?? this.col,
      pos: pos ?? this.pos,
      groupId: groupId ?? this.groupId,
    );
  }
}

/// Represents a collection of snapped pieces moving as a single rigid group.
class GroupModel {
  final int id;
  bool locked;
  int z;

  GroupModel({
    required this.id,
    this.locked = false,
    this.z = 0,
  });

  GroupModel copyWith({
    int? id,
    bool? locked,
    int? z,
  }) {
    return GroupModel(
      id: id ?? this.id,
      locked: locked ?? this.locked,
      z: z ?? this.z,
    );
  }
}

/// Normalized snapshot of a puzzle session for persistent auto-save in Hive.
class PuzzleSessionSnapshot {
  static const int currentVersion = 1;

  final String pictureId;
  final int pieceCount;
  final int seed;
  final int rows;
  final int cols;
  final List<PieceSnapshotItem> pieces;
  final List<int> lockedGroupIds;
  final int elapsedSeconds;
  final int moves;
  final int version;

  PuzzleSessionSnapshot({
    required this.pictureId,
    required this.pieceCount,
    required this.seed,
    required this.rows,
    required this.cols,
    required this.pieces,
    required this.lockedGroupIds,
    required this.elapsedSeconds,
    required this.moves,
    this.version = currentVersion,
  });

  Map<String, dynamic> toJson() => {
    'pictureId': pictureId,
    'pieceCount': pieceCount,
    'seed': seed,
    'rows': rows,
    'cols': cols,
    'pieces': pieces.map((p) => p.toJson()).toList(),
    'lockedGroupIds': lockedGroupIds,
    'elapsedSeconds': elapsedSeconds,
    'moves': moves,
    'version': version,
  };

  factory PuzzleSessionSnapshot.fromJson(Map<String, dynamic> json) {
    return PuzzleSessionSnapshot(
      pictureId: json['pictureId'] as String,
      pieceCount: json['pieceCount'] as int,
      seed: json['seed'] as int,
      rows: json['rows'] as int,
      cols: json['cols'] as int,
      pieces: (json['pieces'] as List)
          .map((item) => PieceSnapshotItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      lockedGroupIds: List<int>.from(json['lockedGroupIds'] as List),
      elapsedSeconds: json['elapsedSeconds'] as int? ?? 0,
      moves: json['moves'] as int? ?? 0,
      version: json['version'] as int? ?? 1,
    );
  }
}

/// Stores piece position as normalized fraction of board dimensions (0.0 to 1.0)
/// to survive orientation changes, device rotations, and window resizing!
class PieceSnapshotItem {
  final int row;
  final int col;
  final double normX; // pos.dx / boardW
  final double normY; // pos.dy / boardH
  final int groupId;

  PieceSnapshotItem({
    required this.row,
    required this.col,
    required this.normX,
    required this.normY,
    required this.groupId,
  });

  Map<String, dynamic> toJson() => {
    'r': row,
    'c': col,
    'x': normX,
    'y': normY,
    'g': groupId,
  };

  factory PieceSnapshotItem.fromJson(Map<String, dynamic> json) {
    return PieceSnapshotItem(
      row: json['r'] as int,
      col: json['c'] as int,
      normX: (json['x'] as num).toDouble(),
      normY: (json['y'] as num).toDouble(),
      groupId: json['g'] as int,
    );
  }
}
