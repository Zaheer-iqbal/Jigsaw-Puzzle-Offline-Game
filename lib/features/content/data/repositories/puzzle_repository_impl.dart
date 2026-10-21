import 'package:jigsaw_pro/core/config/app_config.dart';
import 'package:jigsaw_pro/features/content/data/datasources/asset_manifest_data_source.dart';
import 'package:jigsaw_pro/features/content/domain/entities/puzzle_level.dart';
import 'package:jigsaw_pro/features/content/domain/entities/puzzle_picture.dart';
import 'package:jigsaw_pro/features/content/domain/repositories/puzzle_repository.dart';

class PuzzleRepositoryImpl implements PuzzleRepository {
  final AssetManifestDataSource _dataSource;

  PuzzleRepositoryImpl(this._dataSource);

  @override
  Future<List<PuzzlePicture>> getAll() async {
    return _dataSource.loadManifest();
  }

  @override
  Future<List<PuzzlePicture>> getByCategory(String category) async {
    final all = await getAll();
    return all.where((p) => p.category.toLowerCase() == category.toLowerCase()).toList();
  }

  @override
  Future<PuzzlePicture?> getById(String id) async {
    final all = await getAll();
    try {
      return all.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<PuzzlePicture> getDaily(DateTime date) async {
    final all = await getAll();
    final freePictures = all.where((p) => !p.premium).toList();

    if (freePictures.isEmpty) {
      if (all.isNotEmpty) return all.first;
      throw Exception('No pictures available in manifest for daily puzzle.');
    }

    final dateOnly = DateTime(date.year, date.month, date.day);
    final epochOnly = DateTime(
      AppConfig.dailyEpoch.year,
      AppConfig.dailyEpoch.month,
      AppConfig.dailyEpoch.day,
    );

    final days = dateOnly.difference(epochOnly).inDays.abs();
    final index = days % freePictures.length;
    return freePictures[index];
  }

  @override
  Future<List<String>> getCategories() async {
    final all = await getAll();
    final categories = <String>{};
    for (final p in all) {
      categories.add(p.category);
    }
    return categories.toList()..sort();
  }

  @override
  Future<List<PuzzleLevel>> getLevelsByCategory(String category) async {
    final catPics = await getByCategory(category);
    final levels = <PuzzleLevel>[];

    for (var i = 1; i <= 100; i++) {
      final defaultCount = PuzzleLevel.computeDefaultPieceCount(i);
      final prefix = category.isNotEmpty ? category.substring(0, 1).toLowerCase() : 'p';
      final id = '$prefix${i.toString().padLeft(3, '0')}';

      // Check if user has uploaded a file specifically for this level ID
      PuzzlePicture? matchingPic;
      for (final p in catPics) {
        if (p.id.toLowerCase() == id.toLowerCase()) {
          matchingPic = p;
          break;
        }
      }

      final imagePath = matchingPic?.path ??
          (catPics.isNotEmpty ? catPics[(i - 1) % catPics.length].path : 'assets/puzzles/nature/n001.bmp');
      final title = matchingPic?.title ??
          '${category[0].toUpperCase()}${category.substring(1)} Level $i';
      final isPremium = (i % 10 == 0); // Every 10th level is a special premium unlock

      levels.add(PuzzleLevel(
        levelNumber: i,
        category: category,
        id: id,
        title: title,
        imagePath: imagePath,
        defaultPieceCount: defaultCount,
        isPremium: isPremium,
      ));
    }

    return levels;
  }
}
