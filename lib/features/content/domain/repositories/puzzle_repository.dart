import 'package:jigsaw_pro/features/content/domain/entities/puzzle_level.dart';
import 'package:jigsaw_pro/features/content/domain/entities/puzzle_picture.dart';

abstract class PuzzleRepository {
  Future<List<PuzzlePicture>> getAll();
  Future<List<PuzzlePicture>> getByCategory(String category);
  Future<PuzzlePicture?> getById(String id);
  Future<PuzzlePicture> getDaily(DateTime date);
  Future<List<String>> getCategories();
  Future<List<PuzzleLevel>> getLevelsByCategory(String category);
  Future<List<PuzzleLevel>> getSagaLevels();
}
