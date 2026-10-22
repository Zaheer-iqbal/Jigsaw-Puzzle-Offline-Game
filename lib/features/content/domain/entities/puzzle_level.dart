/// Represents a progressive puzzle level.
/// Supports both category progression and the 25-level Saga Campaign map.
class PuzzleLevel {
  final int levelNumber; // 1 to 25 (or 1 to 100)
  final String category; // 'nature', 'animals', 'flowers', 'landmarks', 'art'
  final String id; // picture id, e.g. 'n001.bpm', 'a001'
  final String title;
  final String imagePath;
  final int defaultPieceCount; // Scaled difficulty
  final bool isPremium;

  const PuzzleLevel({
    required this.levelNumber,
    required this.category,
    required this.id,
    required this.title,
    required this.imagePath,
    required this.defaultPieceCount,
    required this.isPremium,
  });

  String get pictureId => id;
  int get pieceCount => defaultPieceCount;

  static const PuzzleLevel fallbackNatureLevel = PuzzleLevel(
    levelNumber: 1,
    category: 'nature',
    id: 'n001.bpm',
    title: 'Nature Level 1',
    imagePath: 'assets/puzzles/nature/n001.bpm.jpg',
    defaultPieceCount: 12,
    isPremium: false,
  );

  /// Dynamic Shuffled Difficulty Curve (Every 3-4 levels a medium/hard milestone is shuffled in):
  /// - 1: 12 pcs (Novice)
  /// - 2: 12 pcs (Novice)
  /// - 3: 24 pcs (Casual)
  /// - 4: 48 pcs (⚡ Medium Milestone!)
  /// - 5: 12 pcs (🌱 Relaxing Breather)
  /// - 6: 24 pcs (Casual)
  /// - 7: 48 pcs (Medium)
  /// - 8: 100 pcs (🔥 Hard Milestone!)
  /// - 9: 24 pcs (🌱 Breather)
  /// - 10: 48 pcs (Medium)
  /// - 11: 48 pcs (Medium)
  /// - 12: 100 pcs (🔥 Hard Milestone!)
  /// - 13: 24 pcs (🌱 Breather)
  /// - 14: 100 pcs (Hard)
  /// - 15: 200 pcs (💎 Expert Milestone!)
  /// - 16: 48 pcs (Medium Breather)
  /// - 17: 100 pcs (Hard)
  /// - 18: 100 pcs (Hard)
  /// - 19: 200 pcs (💎 Expert Milestone!)
  /// - 20: 48 pcs (Breather)
  /// - 21: 100 pcs (Hard)
  /// - 22: 200 pcs (Expert)
  /// - 23: 200 pcs (Expert)
  /// - 24: 400 pcs (👑 Master Peak!)
  /// - 25: 400 pcs (👑 Grand Finale Boss!)
  static int compute25LevelPieceCount(int level) {
    switch (level) {
      case 1:
      case 2:
      case 5:
        return 12;
      case 3:
      case 6:
      case 9:
      case 13:
        return 24;
      case 4:
      case 7:
      case 10:
      case 11:
      case 16:
      case 20:
        return 48;
      case 8:
      case 12:
      case 14:
      case 17:
      case 18:
      case 21:
        return 100;
      case 15:
      case 19:
      case 22:
      case 23:
        return 200;
      case 24:
      case 25:
      default:
        return 400;
    }
  }

  static bool isMilestoneLevel(int level) {
    return level == 4 || level == 8 || level == 12 || level == 15 || level == 19 || level == 24 || level == 25;
  }

  static String getMilestoneBadge(int level) {
    switch (level) {
      case 4:
        return '⚡ Medium Milestone';
      case 8:
        return '🔥 Hard Milestone';
      case 12:
        return '🔥 Hard Challenge';
      case 15:
        return '💎 Expert Milestone';
      case 19:
        return '💎 Expert Challenge';
      case 24:
        return '👑 Master Peak';
      case 25:
        return '👑 Grand Finale';
      default:
        return '';
    }
  }

  /// General difficulty scaling for 100-level category grids
  static int computeDefaultPieceCount(int level) {
    if (level <= 10) return 12;
    if (level <= 25) return 24;
    if (level <= 50) return 48;
    if (level <= 75) return 100;
    if (level <= 90) return 200;
    return 400;
  }

  static String getDifficultyLabel(int pieceCount) {
    switch (pieceCount) {
      case 12:
        return 'Novice';
      case 24:
        return 'Easy';
      case 48:
        return 'Medium';
      case 100:
        return 'Hard';
      case 200:
        return 'Expert';
      case 400:
        return 'Master';
      default:
        return '$pieceCount Pieces';
    }
  }
}
