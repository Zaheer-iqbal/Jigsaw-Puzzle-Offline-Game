import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:jigsaw_pro/core/storage/hive_storage.dart';
import 'package:jigsaw_pro/features/content/domain/entities/puzzle_level.dart';
import 'package:jigsaw_pro/features/content/domain/entities/puzzle_picture.dart';
import 'package:jigsaw_pro/features/content/domain/repositories/puzzle_repository.dart';

class ContentController extends GetxController {
  final PuzzleRepository _repository;
  final HiveStorage _storage;

  ContentController(this._repository, this._storage);

  final RxBool isLoading = true.obs;
  final RxString errorMessage = ''.obs;

  final RxList<PuzzlePicture> allPictures = <PuzzlePicture>[].obs;
  final RxList<String> categories = <String>[].obs;
  final Rx<PuzzlePicture?> dailyPicture = Rx<PuzzlePicture?>(null);
  final RxList<PuzzleLevel> sagaLevels = <PuzzleLevel>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadContent();
  }

  Future<void> loadContent() async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final pictures = await _repository.getAll();
      final cats = await _repository.getCategories();
      final daily = await _repository.getDaily(DateTime.now());
      final saga = await _repository.getSagaLevels();

      allPictures.assignAll(pictures);
      categories.assignAll(cats);
      dailyPicture.value = daily;
      sagaLevels.assignAll(saga);
    } catch (e) {
      debugPrint('Error loading content: $e');
      errorMessage.value = 'Failed to load puzzles. Please verify asset manifest.';
    } finally {
      isLoading.value = false;
    }
  }

  int getPictureLevelNumber(PuzzlePicture picture) {
    final numStr = picture.id.replaceAll(RegExp(r'[^0-9]'), '').replaceFirst(RegExp(r'^0+'), '');
    return int.tryParse(numStr) ?? 1;
  }

  bool isPictureUnlocked(PuzzlePicture picture) {
    // 1. Explicitly unlocked via Ad or Coins (saved in storage)
    if (_storage.isPictureUnlocked(picture.id)) return true;

    // 2. Already completed by player
    if (_storage.isPictureCompleted(picture.id)) return true;

    // 3. Level 1 of any category is always free & unlocked
    final lvl = getPictureLevelNumber(picture);
    if (lvl <= 1) return true;

    // 4. Sequential progression: Unlocked if previous puzzle in the category is completed
    final catPics = allPictures
        .where((p) => p.category.toLowerCase() == picture.category.toLowerCase())
        .toList();
    final index = catPics.indexWhere((p) => p.id == picture.id);
    if (index > 0) {
      final prevPic = catPics[index - 1];
      if (_storage.isPictureCompleted(prevPic.id)) {
        return true;
      }
    }

    return false;
  }

  bool isPictureCompleted(String pictureId) {
    return _storage.isPictureCompleted(pictureId);
  }

  /// Unlocks ONLY this single puzzle (e.g. from watching a rewarded video ad or coins)
  Future<bool> unlockPicture(PuzzlePicture picture) async {
    await _storage.unlockPicture(picture.id);
    update();
    return true;
  }

  // --- 100 Levels Per Category Progression ---
  Future<List<PuzzleLevel>> getLevels(String category) async {
    return _repository.getLevelsByCategory(category);
  }

  bool isLevelUnlocked(String category, int levelNumber) {
    return _storage.isLevelUnlocked(category, levelNumber);
  }

  int getHighestLevel(String category) {
    return _storage.getHighestUnlockedLevel(category);
  }

  Future<void> onLevelSolved(String category, int levelNumber) async {
    await _storage.unlockNextLevel(category, levelNumber);
    update();
  }

  // --- 25-Level Saga Campaign ---
  int get highestSagaLevel => _storage.getHighestSagaLevel();

  bool isSagaLevelUnlocked(int levelNumber) {
    return _storage.isSagaLevelUnlocked(levelNumber);
  }

  int getSagaStars(int levelNumber) {
    return _storage.getSagaStars(levelNumber);
  }

  Future<void> onSagaLevelSolved(int levelNumber, int stars) async {
    await _storage.unlockNextSagaLevel(levelNumber);
    await _storage.setSagaStars(levelNumber, stars);
    update();
  }
}
