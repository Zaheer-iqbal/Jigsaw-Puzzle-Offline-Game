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
import 'package:jigsaw_pro/features/settings/presentation/controllers/settings_controller.dart';

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
  bool isDaily = false;
  int? currentSagaLevel;
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

  // Tray & Board state (Easybrain style bottom scrollable tray + active board workspace)
  final RxList<String> trayPieceKeys = <String>[].obs;
  final RxSet<String> boardPieceKeys = <String>{}.obs;
  final RxSet<String> lockedPieceKeys = <String>{}.obs;

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
    int? sagaLevel,
    bool isDailyPuzzle = false,
  }) async {
    state.value = PuzzleState.preparing;
    prepareProgress.value = 0.05;

    pictureId = id;
    picturePath = assetPath;
    isDaily = isDailyPuzzle;

    // Clean and sanitize picture title from raw file extensions or ids
    var cleanTitle = title.replaceAll(RegExp(r'\.(bpm|png|jpg|jpeg)$', caseSensitive: false), '').trim();
    if (isDailyPuzzle) {
      cleanTitle = 'Daily Puzzle';
    } else if (RegExp(r'^[a-z]+[0-9]+$', caseSensitive: false).hasMatch(cleanTitle)) {
      final numStr = cleanTitle.replaceAll(RegExp(r'[^0-9]'), '').replaceFirst(RegExp(r'^0+'), '');
      cleanTitle = 'Level ${numStr.isEmpty ? "1" : numStr}';
    }
    pictureTitle = cleanTitle.isNotEmpty ? cleanTitle : 'Puzzle Level';
    targetPieceCount = pieceCount;
    currentSagaLevel = sagaLevel;

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

      // Base board width is 750.0. Clamped to ~1.25 so the board has comfortable, tall height
      // and fills mobile portrait screens prominently rather than looking like a narrow strip!
      boardW = 750.0;
      final effectiveAspect = imgAspect.clamp(1.15, 1.30);
      boardH = boardW / effectiveAspect;

      pieceW = boardW / cols;
      pieceH = boardH / rows;
      margin = GridCalculator.calculateMargin(pieceW, pieceH);

      // 2. Check for resume snapshot or create fresh seed
      final savedSession = isResume ? _storage.getActiveSession() : null;
      bool shouldRestore = false;
      if (savedSession != null && savedSession['pictureId'] == id) {
        final lockedCount = (savedSession['lockedPieceKeys'] as List?)?.length ?? 0;
        final totalCount = (savedSession['pieceCount'] ?? savedSession['actualPieceCount']) as int? ?? targetPieceCount;
        if (lockedCount > 0 && lockedCount < totalCount) {
          shouldRestore = true;
          seed = savedSession['seed'] as int;
          elapsedSeconds.value = savedSession['elapsedSeconds'] as int? ?? 0;
          moves.value = savedSession['moves'] as int? ?? 0;
        } else {
          // Already completed or empty: clear session so user gets a fresh game
          _storage.clearActiveSession();
        }
      }

      if (!shouldRestore) {
        seed = Random().nextInt(1000000);
        elapsedSeconds.value = 0;
        moves.value = 0;
      }

      // 3. Generate deterministic edges (flatEdges: true ensures clean straight tiles without side cuts)
      final edgeGen = EdgeGenerator(rows: rows, cols: cols, seed: seed, flatEdges: true);

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
      trayPieceKeys.clear();
      boardPieceKeys.clear();
      lockedPieceKeys.clear();

      for (var r = 0; r < rows; r++) {
        for (var c = 0; c < cols; c++) {
          final key = '${r}_$c';
          pieces[key] = PieceModel(
            row: r,
            col: c,
            pos: Offset(c * pieceW, r * pieceH),
            groupId: -1,
          );
          trayPieceKeys.add(key);
        }
      }
      trayPieceKeys.shuffle(Random(seed));

      if (shouldRestore && savedSession != null) {
        try {
          _restoreFromSnapshot(savedSession);
        } catch (e) {
          debugPrint('Snapshot restore notice: $e');
          _storage.clearActiveSession();
        }
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

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.value == PuzzleState.playing) {
        elapsedSeconds.value++;
      }
    });
  }

  void pauseTimer() {
    _timer?.cancel();
  }

  void resumeTimer() {
    if (state.value == PuzzleState.playing) {
      _startTimer();
    }
  }

  /// Restarts the current puzzle session fresh from the beginning
  void restartPuzzle() {
    _timer?.cancel();
    _storage.clearActiveSession();
    elapsedSeconds.value = 0;
    moves.value = 0;
    lockedPieceKeys.clear();
    boardPieceKeys.clear();
    trayPieceKeys.clear();

    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        final key = '${r}_$c';
        pieces[key] = PieceModel(
          row: r,
          col: c,
          pos: Offset(c * pieceW, r * pieceH),
          groupId: 0,
        );
        trayPieceKeys.add(key);
      }
    }
    trayPieceKeys.shuffle(Random(seed));
    _updateLockedCount();
    _startTimer();
  }

  /// Re-shuffles the remaining pieces in the bottom tray with tactile feedback
  void shuffleTrayPieces() {
    trayPieceKeys.shuffle();
    _haptics.click();
  }

  /// Attempts to snap a piece dragged onto the board.
  /// If dropped over its correct slot, locks to the board permanently.
  /// If dropped anywhere else (wrong slot or empty board space), it does NOT fix on the board
  /// and safely returns to the bottom tray!
  bool trySnapPiece(String pieceKey, Offset boardLocalPos) {
    final piece = pieces[pieceKey];
    if (piece == null) return false;

    final targetPos = piece.correctPos(pieceW, pieceH);
    final targetCenter = targetPos + Offset(pieceW / 2, pieceH / 2);

    // Exact slot hit-test: slot rectangle or tight radial distance to center
    final slotRect = Rect.fromLTWH(targetPos.dx, targetPos.dy, pieceW, pieceH).inflate(min(pieceW, pieceH) * 0.20);
    final distToCenter = (boardLocalPos - targetCenter).distance;
    final maxSnapDistance = min(pieceW, pieceH) * 0.55;

    final isCorrectSlot = slotRect.contains(boardLocalPos) || distToCenter <= maxSnapDistance;

    if (isCorrectSlot) {
      // Piece belongs here: snap and lock into exact target position!
      return autoSnapPiece(pieceKey);
    } else {
      // Wrong location: do NOT fix on the board!
      // Return to tray if it was on the board, or keep in tray
      if (boardPieceKeys.contains(pieceKey)) {
        boardPieceKeys.remove(pieceKey);
        if (!trayPieceKeys.contains(pieceKey)) {
          trayPieceKeys.insert(0, pieceKey);
        }
      }
      _haptics.light();
      return false;
    }
  }

  /// Returns a piece currently on the board back to the bottom tray
  void returnPieceToTray(String pieceKey) {
    if (boardPieceKeys.contains(pieceKey)) {
      boardPieceKeys.remove(pieceKey);
      if (!trayPieceKeys.contains(pieceKey)) {
        trayPieceKeys.insert(0, pieceKey);
      }
      moves.value++;
      _haptics.click();
      _saveCurrentSessionDebounced();
    }
  }

  /// Locks a piece directly to its correct slot on the board (e.g., via tap-to-place or auto-snap)
  bool autoSnapPiece(String pieceKey) {
    if (!pieces.containsKey(pieceKey)) return false;
    final piece = pieces[pieceKey]!;
    piece.groupId = SnapMergeEngine.boardGroupId;
    piece.pos = piece.correctPos(pieceW, pieceH);

    boardPieceKeys.remove(pieceKey);
    lockedPieceKeys.add(pieceKey);
    trayPieceKeys.remove(pieceKey);
    if (hintPieceKey.value == pieceKey) {
      hintPieceKey.value = null;
    }
    moves.value++;
    _updateLockedCount();
    _audio.playSnap();
    _haptics.snap();
    _saveCurrentSessionDebounced();

    // Strict Victory check: All pieces must be placed, tray must be empty, boardPieceKeys empty!
    if (lockedPieceKeys.length >= actualPieceCount && trayPieceKeys.isEmpty && boardPieceKeys.isEmpty) {
      _handlePuzzleVictory();
    }
    return true;
  }

  void _updateLockedCount() {
    lockedPiecesCount.value = lockedPieceKeys.length;
  }

  bool isBorderPieceKey(String key) {
    final p = pieces[key];
    if (p == null) return false;
    return p.row == 0 || p.row == rows - 1 || p.col == 0 || p.col == cols - 1;
  }

  List<String> get visibleTrayPieceKeys {
    if (!edgesOnly.value) return trayPieceKeys;
    final borderOnly = trayPieceKeys.where(isBorderPieceKey).toList();
    return borderOnly.isNotEmpty ? borderOnly : trayPieceKeys;
  }

  void _restoreFromSnapshot(Map<dynamic, dynamic> snapshot) {
    try {
      final snap = PuzzleSessionSnapshot.fromJson(snapshot);
      for (final item in snap.pieces) {
        final key = '${item.row}_${item.col}';
        if (item.groupId == SnapMergeEngine.boardGroupId) {
          lockedPieceKeys.add(key);
          trayPieceKeys.remove(key);
          boardPieceKeys.remove(key);
        } else if (item.groupId == 1) {
          final p = pieces[key];
          if (p != null) {
            p.pos = Offset(item.normX * boardW, item.normY * boardH);
          }
          trayPieceKeys.remove(key);
          boardPieceKeys.add(key);
        }
      }
    } catch (e) {
      debugPrint('Error restoring snapshot: $e');
    }
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

    // Sync any board-locked pieces
    for (final p in pieces.values) {
      if (p.groupId == SnapMergeEngine.boardGroupId) {
        final key = '${p.row}_${p.col}';
        lockedPieceKeys.add(key);
        trayPieceKeys.remove(key);
        boardPieceKeys.remove(key);
      }
    }

    _updateLockedCount();
    _saveCurrentSessionDebounced();

    // 3. Victory check: ONLY when all pieces are locked and none left in tray or loose
    if (snapResult.isPuzzleComplete && lockedPieceKeys.length >= actualPieceCount && trayPieceKeys.isEmpty && boardPieceKeys.isEmpty) {
      _handlePuzzleVictory();
    }
  }

  void _handlePuzzleVictory() async {
    state.value = PuzzleState.completed;
    _timer?.cancel();

    _audio.playWin();
    _haptics.win();

    // Clear session snapshot from Hive IMMEDIATELY
    await _storage.clearActiveSession();

    // Mark as completed in stats
    _storage.markCompleted(pictureId, actualPieceCount, elapsedSeconds.value, moves.value);

    // If played as a Daily Puzzle, mark today's calendar date as completed!
    if (isDaily) {
      _storage.markDailyCompleted(DateTime.now());
    }

    // If played as a Saga Campaign Level, unlock next Saga level and award stars!
    if (currentSagaLevel != null) {
      int stars = 1;
      final targetSeconds = actualPieceCount * 6;
      if (elapsedSeconds.value <= targetSeconds) {
        stars = 3;
      } else if (elapsedSeconds.value <= targetSeconds * 1.5) {
        stars = 2;
      }
      await _storage.unlockNextSagaLevel(currentSagaLevel!);
      await _storage.setSagaStars(currentSagaLevel!, stars);
    } else {
      // Also advance saga on home screen so the hero card advances to the next level!
      final currentSaga = _storage.getHighestSagaLevel();
      await _storage.unlockNextSagaLevel(currentSaga);
    }

    // If pictureId is a progressive level (e.g. n001, a015, or numeric like 1, 2)
    int? lvlNum;
    String cat = 'nature';
    final match = RegExp(r'^([a-zA-Z]+)(\d+)').firstMatch(pictureId);
    if (match != null) {
      final prefix = match.group(1)!.toLowerCase();
      lvlNum = int.tryParse(match.group(2)!);
      const categoryMap = {
        'n': 'nature',
        'a': 'animals',
        'f': 'flowers',
        'l': 'landmarks',
        'art': 'art',
      };
      cat = categoryMap[prefix] ?? prefix;
    } else {
      lvlNum = int.tryParse(pictureId.replaceAll(RegExp(r'[^0-9]'), ''));
      if (assetPath.contains('animals')) {
        cat = 'animals';
      } else if (assetPath.contains('flowers')) {
        cat = 'flowers';
      } else if (assetPath.contains('landmarks')) {
        cat = 'landmarks';
      } else if (assetPath.contains('art')) {
        cat = 'art';
      }
    }
    if (lvlNum != null) {
      await _storage.unlockNextLevel(cat, lvlNum);
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
    // 1. First check if player has free hints available (starts with 3 free hints)
    final settings = Get.find<SettingsController>();
    if (settings.useFreeHint()) {
      _triggerHint();
      return true;
    }

    // 2. Otherwise check if player has 15 coins
    if (_economy.spendCoins(AppConfig.coinsHintCost)) {
      _triggerHint();
      return true;
    }

    // Out of free hints and coins -> player can watch Rewarded Ad to get hints!
    return false;
  }

  void triggerRewardedHint() {
    final settings = Get.find<SettingsController>();
    settings.addFreeHint(1);
    _triggerHint();
  }

  void triggerHintAnimation() {
    _triggerHint();
  }

  void _triggerHint() {
    final available = trayPieceKeys.isNotEmpty ? trayPieceKeys : boardPieceKeys.toList();
    if (available.isEmpty) return;
    hintPieceKey.value = available.first;
    _hintTimer?.cancel();
    _hintTimer = Timer(const Duration(milliseconds: AppConfig.hintDurationMs * 2), () {
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
    final items = pieces.values.map((p) {
      final key = '${p.row}_${p.col}';
      final isLocked = lockedPieceKeys.contains(key);
      final isBoard = boardPieceKeys.contains(key);
      return PieceSnapshotItem(
        row: p.row,
        col: p.col,
        normX: p.pos.dx / boardW,
        normY: p.pos.dy / boardH,
        groupId: isLocked ? SnapMergeEngine.boardGroupId : (isBoard ? 1 : 0),
      );
    }).toList();

    final snapshot = PuzzleSessionSnapshot(
      pictureId: pictureId,
      pieceCount: actualPieceCount,
      seed: seed,
      rows: rows,
      cols: cols,
      pieces: items,
      lockedGroupIds: lockedPieceKeys.isNotEmpty ? [SnapMergeEngine.boardGroupId] : [],
      elapsedSeconds: elapsedSeconds.value,
      moves: moves.value,
    );

    final map = snapshot.toJson();
    map['picturePath'] = assetPath;
    map['pictureTitle'] = title;
    map['actualPieceCount'] = actualPieceCount;
    map['lockedPieceKeys'] = lockedPieceKeys.toList();
    if (currentSagaLevel != null) {
      map['sagaLevel'] = currentSagaLevel;
    }
    return map;
  }

  Future<ui.Image> _loadUiImageFromAsset(String assetPath) async {
    try {
      final data = await rootBundle.load(assetPath);
      final bytes = data.buffer.asUint8List();
      final codec = await ui.instantiateImageCodec(bytes, targetWidth: 1200);
      final frame = await codec.getNextFrame();
      return frame.image;
    } catch (e) {
      debugPrint('Error loading asset $assetPath: $e. Falling back to nature...');
      final data = await rootBundle.load('assets/puzzles/nature/n001.jpg');
      final bytes = data.buffer.asUint8List();
      final codec = await ui.instantiateImageCodec(bytes, targetWidth: 1200);
      final frame = await codec.getNextFrame();
      return frame.image;
    }
  }
}
