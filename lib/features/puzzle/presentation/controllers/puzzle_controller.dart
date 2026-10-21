import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:jigsaw_pro/core/audio/audio_service.dart';
import 'package:jigsaw_pro/core/config/app_config.dart';
import 'package:jigsaw_pro/core/haptics/haptic_service.dart';
import 'package:jigsaw_pro/core/storage/hive_storage.dart';
import 'package:jigsaw_pro/features/economy/presentation/controllers/economy_controller.dart';
import 'package:jigsaw_pro/features/monetization/presentation/controllers/monetization_controller.dart';
import 'package:jigsaw_pro/features/puzzle/domain/entities/puzzle_models.dart';
import 'package:jigsaw_pro/features/puzzle/domain/engine/edge_generator.dart';
import 'package:jigsaw_pro/features/puzzle/domain/engine/grid_calculator.dart';
import 'package:jigsaw_pro/features/puzzle/domain/engine/snap_merge_engine.dart';
import 'package:jigsaw_pro/features/puzzle/presentation/canvas/piece_image_pre_renderer.dart';

enum PuzzleState { initial, preparing, playing, completed, error }

class PuzzleController extends GetxController with WidgetsBindingObserver {
  final HiveStorage _storage;
  final AudioService _audio;
  final HapticService _haptics;
  final EconomyController _economy;
  final MonetizationController _monetization;

  PuzzleController(
    this._storage,
    this._audio,
    this._haptics,
    this._economy,
    this._monetization,
  );

  final Rx<PuzzleState> state = PuzzleState.initial.obs;
  final RxDouble prepareProgress = 0.0.obs;

  // Puzzle metadata
  late String pictureId;
  late String picturePath;
  late String pictureTitle;
  late int targetPieceCount;
  late int actualPieceCount;
  late int rows;
  late int cols;
  late int seed;
  late double boardW;
  late double boardH;
  late double pieceW;
  late double pieceH;
  late double margin;

  ui.Image? decodedSourceImage;
  Map<String, PreRenderedPiece> preRenderedPieces = {};

  // Live piece & group states
  final Map<String, PieceModel> pieces = {};
  final Map<int, GroupModel> groups = {};

  // Interactive controls & tools
  final RxBool showGhost = false.obs;
  final RxBool edgesOnly = false.obs;
  final Rx<String?> hintPieceKey = Rx<String?>(null);

  // Stats
  final RxInt moves = 0.obs;
  final RxInt elapsedSeconds = 0.obs;
  final RxInt lockedPiecesCount = 0.obs;
  Timer? _timer;
  Timer? _hintTimer;

  int _nextZ = 1;
  late SnapMergeEngine _snapEngine;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void onClose() {
    _timer?.cancel();
    _hintTimer?.cancel();
    _storage.flushSessionSync();
    _disposeImages();
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _saveCurrentSessionImmediate();
    }
  }

  void _disposeImages() {
    for (final p in preRenderedPieces.values) {
      p.dispose();
    }
    preRenderedPieces.clear();
    decodedSourceImage?.dispose();
    decodedSourceImage = null;
  }

  /// Initializes a new puzzle session or resumes an existing one
  Future<void> startPuzzle({
    required String id,
    required String assetPath,
    required String title,
    required int pieceCount,
    required Size boardRenderSize,
    bool isResume = false,
  }) async {
    state.value = PuzzleState.preparing;
    prepareProgress.value = 0.05;

    pictureId = id;
    picturePath = assetPath;
    pictureTitle = title;
    targetPieceCount = pieceCount;

    boardW = boardRenderSize.width;
    boardH = boardRenderSize.height;

    try {
      // 1. Decode full asset image
      decodedSourceImage = await _loadUiImageFromAsset(assetPath);
      prepareProgress.value = 0.20;

      final imgAspect = decodedSourceImage!.width / decodedSourceImage!.height;
      final dims = GridCalculator.calculate(n: targetPieceCount, aspectRatio: imgAspect);
      rows = dims.rows;
      cols = dims.cols;
      actualPieceCount = dims.actualCount;

      pieceW = boardW / cols;
      pieceH = boardH / rows;
      margin = GridCalculator.calculateMargin(pieceW, pieceH);

      // 2. Check for resume snapshot or create fresh seed
      final savedSession = isResume ? _storage.getActiveSession() : null;
      if (savedSession != null && savedSession['pictureId'] == id) {
        seed = savedSession['seed'] as int;
        elapsedSeconds.value = savedSession['elapsedSeconds'] as int? ?? 0;
        moves.value = savedSession['moves'] as int? ?? 0;
      } else {
        seed = Random().nextInt(1000000);
        elapsedSeconds.value = 0;
        moves.value = 0;
      }

      // 3. Generate deterministic edges
      final edgeGen = EdgeGenerator(rows: rows, cols: cols, seed: seed);

      // 4. Pre-render piece bitmaps with progress reporting
      preRenderedPieces = await PieceImagePreRenderer.preRenderAll(
        sourceImage: decodedSourceImage!,
        rows: rows,
        cols: cols,
        boardW: boardW,
        boardH: boardH,
        edgeGenerator: edgeGen,
        onProgress: (p) {
          prepareProgress.value = 0.20 + p * 0.75;
        },
      );

      // 5. Initialize pieces & groups
      _snapEngine = SnapMergeEngine(
        rows: rows,
        cols: cols,
        pieceW: pieceW,
        pieceH: pieceH,
      );

      pieces.clear();
      groups.clear();
      groups[SnapMergeEngine.boardGroupId] = GroupModel(
        id: SnapMergeEngine.boardGroupId,
        locked: true,
        z: 0,
      );

      if (savedSession != null && savedSession['pictureId'] == id) {
        _restoreFromSnapshot(savedSession);
      } else {
        _initializeScatteredPieces();
      }

      _updateLockedCount();

      // Start gameplay timer
      _startTimer();
      state.value = PuzzleState.playing;
    } catch (e, stack) {
      debugPrint('Error starting puzzle: $e\n$stack');
      state.value = PuzzleState.error;
    }
  }

  void _initializeScatteredPieces() {
    final rnd = Random(seed + 1);
    var groupIdCounter = 1;

    // Board area is [0, 0] to [boardW, boardH].
    // Pieces start scattered around the outer perimeter of the board
    final scatterBounds = Rect.fromLTWH(
      -boardW * 0.25,
      -boardH * 0.25,
      boardW * 1.5,
      boardH * 1.5,
    );

    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        final key = '${r}_$c';
        // Random position within scatter area, avoiding exact board slot initially
        double px, py;
        do {
          px = scatterBounds.left + rnd.nextDouble() * (scatterBounds.width - pieceW);
          py = scatterBounds.top + rnd.nextDouble() * (scatterBounds.height - pieceH);
        } while (px > 0 && px < boardW - pieceW && py > 0 && py < boardH - pieceH);

        final gid = groupIdCounter++;
        pieces[key] = PieceModel(
          row: r,
          col: c,
          pos: Offset(px, py),
          groupId: gid,
        );
        groups[gid] = GroupModel(id: gid, locked: false, z: _nextZ++);
      }
    }
  }

  void _restoreFromSnapshot(Map<String, dynamic> snapshot) {
    final snap = PuzzleSessionSnapshot.fromJson(snapshot);
    for (final item in snap.pieces) {
      final key = '${item.row}_${item.col}';
      final pos = Offset(item.normX * boardW, item.normY * boardH);
      pieces[key] = PieceModel(
        row: item.row,
        col: item.col,
        pos: pos,
        groupId: item.groupId,
      );

      if (!groups.containsKey(item.groupId)) {
        groups[item.groupId] = GroupModel(
          id: item.groupId,
          locked: item.groupId == SnapMergeEngine.boardGroupId,
          z: _nextZ++,
        );
      }
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.value == PuzzleState.playing) {
        elapsedSeconds.value++;
      }
    });
  }

  void _updateLockedCount() {
    lockedPiecesCount.value = pieces.values
        .where((p) => p.groupId == SnapMergeEngine.boardGroupId)
        .length;
  }

  /// Hit-tests pieces in descending z-order (front to back).
  /// Returns the hit group id, or null if touch landed on empty canvas.
  int? hitTestGroup(Offset boardTouchPos) {
    final sortedGroups = groups.values.toList()
      ..sort((a, b) => b.z.compareTo(a.z));

    for (final group in sortedGroups) {
      if (group.locked) continue; // Locked board pieces cannot be dragged

      final groupPieces = pieces.entries.where((e) => e.value.groupId == group.id);
      for (final entry in groupPieces) {
        final key = entry.key;
        final piece = entry.value;
        final preRendered = preRenderedPieces[key];
        if (preRendered == null) continue;

        final localTouch = boardTouchPos - piece.pos + Offset(preRendered.margin, preRendered.margin);
        // Fast bounding box check
        final bounds = Rect.fromLTWH(
          0,
          0,
          pieceW + 2 * preRendered.margin,
          pieceH + 2 * preRendered.margin,
        );

        if (bounds.contains(localTouch)) {
          // Precise Bezier path hit-test
          if (preRendered.path.contains(localTouch)) {
            // Bring group to front
            group.z = ++_nextZ;
            return group.id;
          }
        }
      }
    }
    return null;
  }

  /// Handles group drop, snaps to board or neighbors, updates moves, persists state.
  void onGroupDrop(int groupId, Offset totalDragDelta) {
    // 1. Commit drag movement to active pieces
    final activePieces = pieces.values.where((p) => p.groupId == groupId).toList();
    for (final piece in activePieces) {
      piece.pos += totalDragDelta;
    }

    moves.value++;

    // 2. Process snap and merge algorithm
    final snapResult = _snapEngine.processDrop(
      activeGroupId: groupId,
      piecesMap: pieces,
      groupsMap: groups,
    );

    if (snapResult.didSnap) {
      _audio.playSnap();
      _haptics.snap();
    }

    _updateLockedCount();
    _saveCurrentSessionDebounced();

    // 3. Victory check
    if (snapResult.isPuzzleComplete) {
      _handlePuzzleVictory();
    }
  }

  void _handlePuzzleVictory() {
    state.value = PuzzleState.completed;
    _timer?.cancel();

    _audio.playWin();
    _haptics.win();

    // Clear session snapshot from Hive
    _storage.clearActiveSession();

    // Mark as completed in stats
    _storage.markCompleted(pictureId, actualPieceCount, elapsedSeconds.value, moves.value);

    // If pictureId is a progressive level (e.g. n001, a015), automatically unlock next level!
    final match = RegExp(r'^([a-zA-Z]+)(\d+)$').firstMatch(pictureId);
    if (match != null) {
      final prefix = match.group(1)!.toLowerCase();
      final lvlNum = int.tryParse(match.group(2)!) ?? 1;
      const categoryMap = {
        'n': 'nature',
        'a': 'animals',
        'f': 'flowers',
        'l': 'landmarks',
        'art': 'art',
      };
      final cat = categoryMap[prefix] ?? prefix;
      _storage.unlockNextLevel(cat, lvlNum);
    }

    // Reward player with coins
    _economy.rewardPuzzleComplete(actualPieceCount);

    // Notify monetization for frequency capped interstitial
    _monetization.onPuzzleCompleted();
  }

  // --- Controls & Tools ---
  void toggleGhost() {
    showGhost.value = !showGhost.value;
  }

  void toggleEdges() {
    edgesOnly.value = !edgesOnly.value;
  }

  bool requestHint() {
    // Check if player has 15 coins
    if (!_economy.spendCoins(AppConfig.coinsHintCost)) {
      return false;
    }

    _triggerHint();
    return true;
  }

  void triggerRewardedHint() {
    _triggerHint();
  }

  void _triggerHint() {
    // Find an unlocked piece, preferring pieces neighboring locked ones
    final unlockedPieces = pieces.entries
        .where((e) => e.value.groupId != SnapMergeEngine.boardGroupId)
        .toList();

    if (unlockedPieces.isEmpty) return;

    // Find neighbor of locked pieces
    MapEntry<String, PieceModel>? bestCandidate;
    for (final entry in unlockedPieces) {
      final p = entry.value;
      final neighborKeys = [
        '${p.row - 1}_${p.col}',
        '${p.row + 1}_${p.col}',
        '${p.row}_${p.col - 1}',
        '${p.row}_${p.col + 1}',
      ];
      final touchesLocked = neighborKeys.any((k) =>
          pieces[k]?.groupId == SnapMergeEngine.boardGroupId);
      if (touchesLocked) {
        bestCandidate = entry;
        break;
      }
    }

    bestCandidate ??= unlockedPieces[Random().nextInt(unlockedPieces.length)];

    hintPieceKey.value = bestCandidate.key;
    _hintTimer?.cancel();
    _hintTimer = Timer(const Duration(milliseconds: AppConfig.hintDurationMs), () {
      hintPieceKey.value = null;
    });
  }

  // --- Auto-Save Snapshots ---
  void _saveCurrentSessionDebounced() {
    final snapshot = _createSnapshotMap();
    _storage.saveSessionDebounced(snapshot);
  }

  void _saveCurrentSessionImmediate() {
    if (state.value == PuzzleState.playing) {
      final snapshot = _createSnapshotMap();
      _storage.saveSessionDebounced(snapshot);
      _storage.flushSessionSync();
    }
  }

  Map<String, dynamic> _createSnapshotMap() {
    final lockedIds = groups.values.where((g) => g.locked).map((g) => g.id).toList();
    final items = pieces.values.map((p) {
      return PieceSnapshotItem(
        row: p.row,
        col: p.col,
        normX: p.pos.dx / boardW,
        normY: p.pos.dy / boardH,
        groupId: p.groupId,
      );
    }).toList();

    final snapshot = PuzzleSessionSnapshot(
      pictureId: pictureId,
      pieceCount: actualPieceCount,
      seed: seed,
      rows: rows,
      cols: cols,
      pieces: items,
      lockedGroupIds: lockedIds,
      elapsedSeconds: elapsedSeconds.value,
      moves: moves.value,
    );

    return snapshot.toJson();
  }

  Future<ui.Image> _loadUiImageFromAsset(String assetPath) async {
    final data = await rootBundle.load(assetPath);
    final bytes = data.buffer.asUint8List();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    return frame.image;
  }
}
