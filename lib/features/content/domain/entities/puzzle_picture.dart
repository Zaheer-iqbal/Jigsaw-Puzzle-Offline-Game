class PuzzlePicture {
  final String id;
  final String category;
  final String path;
  final String title;
  final bool premium;

  const PuzzlePicture({
    required this.id,
    required this.category,
    required this.path,
    required this.title,
    required this.premium,
  });

  factory PuzzlePicture.fromJson(Map<String, dynamic> json) {
    final rawTitle = json['title'] as String? ?? '';
    final category = json['category'] as String? ?? 'nature';
    final cleanTitle = _formatCleanTitle(rawTitle, category);

    return PuzzlePicture(
      id: json['id'] as String,
      category: category,
      path: json['path'] as String,
      title: cleanTitle,
      premium: json['premium'] as bool? ?? false,
    );
  }

  static String _formatCleanTitle(String rawTitle, String category) {
    var title = rawTitle.replaceAll(RegExp(r'\.(bpm|png|jpg|jpeg)$', caseSensitive: false), '').trim();
    if (RegExp(r'^[a-z]+[0-9]+$', caseSensitive: false).hasMatch(title)) {
      final numStr = title.replaceAll(RegExp(r'[^0-9]'), '').replaceFirst(RegExp(r'^0+'), '');
      final catCap = category.isNotEmpty ? '${category[0].toUpperCase()}${category.substring(1)}' : 'Puzzle';
      return '$catCap Level ${numStr.isEmpty ? "1" : numStr}';
    }
    return title.isNotEmpty ? title : 'Puzzle';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category': category,
      'path': path,
      'title': title,
      'premium': premium,
    };
  }
}
