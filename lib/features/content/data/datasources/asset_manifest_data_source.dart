import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:jigsaw_pro/features/content/domain/entities/puzzle_picture.dart';

class AssetManifestDataSource {
  static const String manifestAssetPath = 'assets/puzzles_manifest.json';
  List<PuzzlePicture>? _cache;

  Future<List<PuzzlePicture>> loadManifest() async {
    if (_cache != null) return _cache!;

    try {
      final jsonString = await rootBundle.loadString(manifestAssetPath);
      final list = jsonDecode(jsonString) as List<dynamic>;
      _cache = list
          .map((item) => PuzzlePicture.fromJson(item as Map<String, dynamic>))
          .toList();
      return _cache!;
    } catch (e) {
      throw Exception('Failed to load puzzles manifest: $e');
    }
  }

  void clearCache() {
    _cache = null;
  }
}
