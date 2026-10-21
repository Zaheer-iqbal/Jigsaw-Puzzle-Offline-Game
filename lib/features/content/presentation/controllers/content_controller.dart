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

      allPictures.assignAll(pictures);
      categories.assignAll(cats);
      dailyPicture.value = daily;
    } catch (e) {
      debugPrint('Error loading content: $e');
      errorMessage.value = 'Failed to load puzzles. Please verify asset manifest.';
    } finally {
      isLoading.value = false;
    }
  }

  bool isPictureUnlocked(PuzzlePicture picture) {
    if (!picture.premium) return true;
    return _storage.isPictureUnlocked(picture.id);
  }

  bool isPictureCompleted(String pictureId) {
    return _storage.isPictureCompleted(pictureId);
  }

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
}
