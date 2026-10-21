import 'dart:convert';
import 'dart:io';

void main() {
  final scriptDir = Directory.current;
  final puzzlesDir = Directory('${scriptDir.path}/assets/puzzles');
  final manifestFile = File('${scriptDir.path}/assets/puzzles_manifest.json');
  final premiumFile = File('${scriptDir.path}/tool/premium.txt');

  if (!puzzlesDir.existsSync()) {
    puzzlesDir.createSync(recursive: true);
  }

  // Load existing premium IDs from premium.txt if available
  final Set<String> premiumIds = {};
  if (premiumFile.existsSync()) {
    final lines = premiumFile.readAsLinesSync();
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isNotEmpty && !trimmed.startsWith('#')) {
        premiumIds.add(trimmed);
      }
    }
  }

  // Also preserve premium flags from existing manifest
  if (manifestFile.existsSync()) {
    try {
      final existingJson = jsonDecode(manifestFile.readAsStringSync()) as List<dynamic>;
      for (final item in existingJson) {
        if (item is Map<String, dynamic> && item['premium'] == true) {
          premiumIds.add(item['id'].toString());
        }
      }
    } catch (_) {
      // Ignore parse errors from empty/corrupted existing manifest
    }
  }

  final categories = ['nature', 'animals', 'flowers', 'landmarks', 'art'];
  final List<Map<String, dynamic>> manifest = [];

  for (final category in categories) {
    final catDir = Directory('${puzzlesDir.path}/$category');
    if (!catDir.existsSync()) {
      catDir.createSync(recursive: true);
      continue;
    }

    final entities = catDir.listSync().toList()
      ..sort((a, b) => a.path.compareTo(b.path));

    for (final entity in entities) {
      if (entity is File) {
        final ext = entity.path.toLowerCase();
        if (ext.endsWith('.webp') || ext.endsWith('.jpg') || ext.endsWith('.jpeg') || ext.endsWith('.png') || ext.endsWith('.bmp')) {
          final filename = entity.uri.pathSegments.last;
          final id = filename.substring(0, filename.lastIndexOf('.'));
          final isPremium = premiumIds.contains(id);

          // Convert id to a readable title (e.g. n001 -> Nature 1, alpine_lake -> Alpine Lake)
          final title = _generateTitle(id, category);

          manifest.add({
            'id': id,
            'category': category,
            'path': 'assets/puzzles/$category/$filename',
            'title': title,
            'premium': isPremium,
          });
        }
      }
    }
  }

  manifestFile.writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert(manifest),
  );

  stdout.writeln('Successfully generated manifest with ${manifest.length} puzzles at ${manifestFile.path}');
}

String _generateTitle(String id, String category) {
  final clean = id.replaceAll(RegExp(r'[_-]+'), ' ');
  final words = clean.split(' ').where((w) => w.isNotEmpty).map((w) {
    return w[0].toUpperCase() + (w.length > 1 ? w.substring(1) : '');
  }).toList();

  if (words.isEmpty) {
    return category[0].toUpperCase() + category.substring(1);
  }
  return words.join(' ');
}
