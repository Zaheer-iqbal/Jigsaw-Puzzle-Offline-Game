/// Represents a progressive puzzle level (1 to 100 per category).
/// Implements dynamic difficulty scaling as levels advance.
class PuzzleLevel {
  final int levelNumber; // 1 to 100
  final String category; // 'nature', 'animals', 'flowers', 'landmarks', 'art'
  final String id; // e.g. 'n001', 'a045'
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

  /// Dynamic difficulty progression curve (tora tora hard hota jaye ga):
  /// - Levels 1–10: 12 pieces (Warmup / Gentle)
  /// - Levels 11–25: 24 pieces (Easy)
  /// - Levels 26–50: 48 pieces (Casual Medium)
  /// - Levels 51–75: 100 pieces (Challenging)
  /// - Levels 76–90: 200 pieces (Enthusiast)
  /// - Levels 91–100: 400 pieces (Master Grandmaster)
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
