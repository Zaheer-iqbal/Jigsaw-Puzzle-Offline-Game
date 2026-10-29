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

  bool get musicEnabled => _settingsBox.get('music', defaultValue: true) as bool;
  Future<void> setMusicEnabled(bool value) => _settingsBox.put('music', value);

  bool get vibrationEnabled => _settingsBox.get('vibration', defaultValue: true) as bool;
  Future<void> setVibrationEnabled(bool value) => _settingsBox.put('vibration', value);

  bool get keepScreenAwake => _settingsBox.get('keepScreenAwake', defaultValue: true) as bool;
  Future<void> setKeepScreenAwake(bool value) => _settingsBox.put('keepScreenAwake', value);

  String get playerName => _settingsBox.get('playerName', defaultValue: 'Puzzle Master') as String;
  Future<void> setPlayerName(String name) => _settingsBox.put('playerName', name);

  String get themeMode => _settingsBox.get('themeMode', defaultValue: 'system') as String;
  Future<void> setThemeMode(String mode) => _settingsBox.put('themeMode', mode);

  String get boardBackground => _settingsBox.get('boardBg', defaultValue: 'cleanLight') as String;
  Future<void> setBoardBackground(String bg) => _settingsBox.put('boardBg', bg);

  String get screenTheme => _settingsBox.get('screenTheme', defaultValue: 'azureSky') as String;
  Future<void> setScreenTheme(String theme) => _settingsBox.put('screenTheme', theme);

  // --- Privacy & GDPR Consent ---
  bool get hasConsentedToPrivacy => _settingsBox.get('gdprConsent', defaultValue: false) as bool;
  Future<void> setPrivacyConsent(bool value) => _settingsBox.put('gdprConsent', value);

  // --- Achievements Claim Tracking ---
  bool isAchievementClaimed(String id) => _settingsBox.get('ach_$id', defaultValue: false) as bool;
  Future<void> claimAchievement(String id) => _settingsBox.put('ach_$id', true);

  // --- Economy & Hints ---
  int get freeHints => _settingsBoxSafeInt(_economyBox.get('freeHints'), 3);
  Future<void> setFreeHints(int value) => _economyBox.put('freeHints', value);
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

  // --- Daily Puzzle Completion Tracker ---
  List<String> get completedDailyDates =>
      List<String>.from(_progressBox.get('completedDailyDates', defaultValue: <String>[]) as List);

  Future<void> markDailyCompleted(DateTime date) async {
    final key = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final list = completedDailyDates;
    if (!list.contains(key)) {
      list.add(key);
      await _progressBox.put('completedDailyDates', list);
    }
  }

  bool isDailyDateCompleted(DateTime date) {
    final key = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return completedDailyDates.contains(key);
  }

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

  // --- Candy Crush 25-Level Saga Campaign ---
  int getHighestSagaLevel() {
    return _progressBox.get('unlocked_saga_level', defaultValue: 1) as int;
  }

  ValueListenable<Box> get progressBoxListenable => _progressBox.listenable();
  ValueListenable<Box> get sessionBoxListenable => _sessionBox.listenable();

  Future<void> unlockNextSagaLevel(int completedLevel) async {
    final current = getHighestSagaLevel();
    if (completedLevel >= current && current < 25) {
      await _progressBox.put('unlocked_saga_level', completedLevel + 1);
    }
  }

  bool isSagaLevelUnlocked(int levelNumber) {
    if (levelNumber <= 1) return true;
    return levelNumber <= getHighestSagaLevel();
  }

  int getSagaStars(int levelNumber) {
    return _progressBox.get('saga_stars_$levelNumber', defaultValue: 0) as int;
  }

  Future<void> setSagaStars(int levelNumber, int stars) async {
    final current = getSagaStars(levelNumber);
    if (stars > current) {
      await _progressBox.put('saga_stars_$levelNumber', stars);
    }
  }

  // --- Purchases & Ad-Free Unlocks ---
  bool get removeAds => _purchasesBox.get('removeAds', defaultValue: false) as bool;
  Future<void> setRemoveAds(bool value) => _purchasesBox.put('removeAds', value);
  int get removeAdsProgress => (_purchasesBox.get('removeAdsProgress', defaultValue: 0) as num).toInt();
  Future<void> setRemoveAdsProgress(int value) => _purchasesBox.put('removeAdsProgress', value);

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

  Future<void> resetAllGameData() async {
    await clearActiveSession();
    await _progressBox.clear();
    await _unlockedBox.clear();
    await _economyBox.clear();
    await _economyBox.put('coins', AppConfig.startingCoins);
    await _economyBox.put('freeHints', 3);
    await _economyBox.put('streak', 0);
  }

  int _settingsBoxSafeInt(dynamic val, int fallback) {
    if (val is int) return val;
    if (val is num) return val.toInt();
    return fallback;
  }
}
