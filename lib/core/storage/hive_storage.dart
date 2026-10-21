import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:jigsaw_pro/core/config/app_config.dart';

class HiveStorage {
  static const String boxSettings = 'settings';
  static const String boxEconomy = 'economy';
  static const String boxProgress = 'progress';
  static const String boxUnlocked = 'unlocked';
  static const String boxSession = 'session';
  static const String boxPurchases = 'purchases';

  late Box _settingsBox;
  late Box _economyBox;
  late Box _progressBox;
  late Box _unlockedBox;
  late Box _sessionBox;
  late Box _purchasesBox;

  Timer? _sessionDebounceTimer;
  Map<String, dynamic>? _pendingSessionSnapshot;

  Future<void> init() async {
    await Hive.initFlutter();

    _settingsBox = await Hive.openBox(boxSettings);
    _economyBox = await Hive.openBox(boxEconomy);
    _progressBox = await Hive.openBox(boxProgress);
    _unlockedBox = await Hive.openBox(boxUnlocked);
    _sessionBox = await Hive.openBox(boxSession);
    _purchasesBox = await Hive.openBox(boxPurchases);

    // Initial seed for economy if new install
    if (!_economyBox.containsKey('coins')) {
      await _economyBox.put('coins', AppConfig.startingCoins);
    }
  }

  // --- Settings ---
  bool get soundEnabled => _settingsBox.get('sound', defaultValue: true) as bool;
  Future<void> setSoundEnabled(bool value) => _settingsBox.put('sound', value);

  bool get vibrationEnabled => _settingsBox.get('vibration', defaultValue: true) as bool;
  Future<void> setVibrationEnabled(bool value) => _settingsBox.put('vibration', value);

  String get themeMode => _settingsBox.get('themeMode', defaultValue: 'system') as String;
  Future<void> setThemeMode(String mode) => _settingsBox.put('themeMode', mode);

  String get boardBackground => _settingsBox.get('boardBg', defaultValue: 'feltGreen') as String;
  Future<void> setBoardBackground(String bg) => _settingsBox.put('boardBg', bg);

  // --- Economy ---
  int get coins => _settingsBoxSafeInt(_economyBox.get('coins'), AppConfig.startingCoins);
  Future<void> setCoins(int value) => _economyBox.put('coins', value);

  String? get lastDailyClaim => _economyBox.get('lastDailyClaim') as String?;
  Future<void> setLastDailyClaim(String dateIso) => _economyBox.put('lastDailyClaim', dateIso);

  int get streak => _settingsBoxSafeInt(_economyBox.get('streak'), 0);
  Future<void> setStreak(int value) => _economyBox.put('streak', value);

  // --- Unlocked Premium Pictures ---
  List<String> get unlockedIds => List<String>.from(_unlockedBox.get('unlockedIds', defaultValue: <String>[]) as List);
  Future<void> unlockPicture(String id) async {
    final list = unlockedIds;
    if (!list.contains(id)) {
      list.add(id);
      await _unlockedBox.put('unlockedIds', list);
    }
  }
  bool isPictureUnlocked(String id) => unlockedIds.contains(id);

  // --- Completed Progress ---
  List<String> get completedIds => List<String>.from(_progressBox.get('completedIds', defaultValue: <String>[]) as List);
  Future<void> markCompleted(String pictureId, int pieceCount, int elapsedSeconds, int moves) async {
    final list = completedIds;
    if (!list.contains(pictureId)) {
      list.add(pictureId);
      await _progressBox.put('completedIds', list);
    }

    // Save best record
    final key = 'stats_${pictureId}_$pieceCount';
    final existing = _progressBox.get(key) as Map?;
    if (existing == null) {
      await _progressBox.put(key, {'time': elapsedSeconds, 'moves': moves});
    } else {
      final bestTime = (existing['time'] as num?)?.toInt() ?? elapsedSeconds;
      final bestMoves = (existing['moves'] as num?)?.toInt() ?? moves;
      await _progressBox.put(key, {
        'time': elapsedSeconds < bestTime ? elapsedSeconds : bestTime,
        'moves': moves < bestMoves ? moves : bestMoves,
      });
    }
  }

  bool isPictureCompleted(String id) => completedIds.contains(id);

  // --- Category Level Progression (1 to 100) ---
  int getHighestUnlockedLevel(String category) {
    return _progressBox.get('unlocked_lvl_${category.toLowerCase()}', defaultValue: 1) as int;
  }

  Future<void> unlockNextLevel(String category, int completedLevel) async {
    final current = getHighestUnlockedLevel(category);
    if (completedLevel >= current && current < 100) {
      await _progressBox.put('unlocked_lvl_${category.toLowerCase()}', completedLevel + 1);
    }
  }

  bool isLevelUnlocked(String category, int levelNumber) {
    if (levelNumber <= 1) return true;
    return levelNumber <= getHighestUnlockedLevel(category);
  }

  // --- Purchases ---
  bool get removeAds => _purchasesBox.get('removeAds', defaultValue: false) as bool;
  Future<void> setRemoveAds(bool value) => _purchasesBox.put('removeAds', value);

  // --- Active Session Auto-Save (Debounced & Immediate Flush) ---
  Map<String, dynamic>? getActiveSession() {
    final data = _sessionBox.get('current');
    if (data == null) return null;
    try {
      return Map<String, dynamic>.from(data as Map);
    } catch (e) {
      debugPrint('Session parse error: $e');
      return null;
    }
  }

  void saveSessionDebounced(Map<String, dynamic> snapshot) {
    _pendingSessionSnapshot = snapshot;
    _sessionDebounceTimer?.cancel();
    _sessionDebounceTimer = Timer(const Duration(milliseconds: 300), () {
      flushSessionSync();
    });
  }

  Future<void> flushSessionSync() async {
    _sessionDebounceTimer?.cancel();
    if (_pendingSessionSnapshot != null) {
      await _sessionBox.put('current', _pendingSessionSnapshot);
      _pendingSessionSnapshot = null;
    }
  }

  Future<void> clearActiveSession() async {
    _sessionDebounceTimer?.cancel();
    _pendingSessionSnapshot = null;
    await _sessionBox.delete('current');
  }

  int _settingsBoxSafeInt(dynamic val, int fallback) {
    if (val is int) return val;
    if (val is num) return val.toInt();
    return fallback;
  }
}
