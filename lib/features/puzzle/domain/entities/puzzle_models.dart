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

  factory PuzzleSessionSnapshot.fromJson(Map<dynamic, dynamic> json) {
    final rawPieces = json['pieces'] as List? ?? [];
    return PuzzleSessionSnapshot(
      pictureId: json['pictureId']?.toString() ?? '',
      pieceCount: (json['pieceCount'] as num?)?.toInt() ?? 48,
      seed: (json['seed'] as num?)?.toInt() ?? 0,
      rows: (json['rows'] as num?)?.toInt() ?? 6,
      cols: (json['cols'] as num?)?.toInt() ?? 8,
      pieces: rawPieces
          .map((item) => PieceSnapshotItem.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList(),
      lockedGroupIds: (json['lockedGroupIds'] as List?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          [],
      elapsedSeconds: (json['elapsedSeconds'] as num?)?.toInt() ?? 0,
      moves: (json['moves'] as num?)?.toInt() ?? 0,
      version: (json['version'] as num?)?.toInt() ?? 1,
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

  factory PieceSnapshotItem.fromJson(Map<dynamic, dynamic> json) {
    return PieceSnapshotItem(
      row: (json['r'] as num?)?.toInt() ?? 0,
      col: (json['c'] as num?)?.toInt() ?? 0,
      normX: (json['x'] as num?)?.toDouble() ?? 0.0,
      normY: (json['y'] as num?)?.toDouble() ?? 0.0,
      groupId: (json['g'] as num?)?.toInt() ?? 0,
    );
  }
}
