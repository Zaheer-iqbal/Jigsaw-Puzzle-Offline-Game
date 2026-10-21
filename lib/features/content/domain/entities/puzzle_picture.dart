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
    return PuzzlePicture(
      id: json['id'] as String,
      category: json['category'] as String,
      path: json['path'] as String,
      title: json['title'] as String,
      premium: json['premium'] as bool? ?? false,
    );
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
