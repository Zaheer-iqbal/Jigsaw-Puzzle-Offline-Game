import 'dart:io';
import 'dart:typed_data';

/// Generates valid 24-bit uncompressed BMP images for testing the puzzle engine.
/// Flutter natively decodes BMP, PNG, JPEG, and WebP.
void main() {
  final baseDir = Directory('assets/puzzles');
  final categories = {
    'nature': [
      ('n001', 'Emerald Forest', 0x2E7D32, 0x81C784),
      ('n002', 'Sunset Canyon', 0xE65100, 0xFFB74D),
      ('n003', 'Ocean Horizon', 0x01579B, 0x4FC3F7),
      ('n004', 'Alpine Peaks', 0x37474F, 0x90A4AE),
      ('n005', 'Misty Waterfall', 0x00695C, 0x4DB6AC),
    ],
    'animals': [
      ('a001', 'Golden Tiger', 0xBF360C, 0xFF8A65),
      ('a002', 'Arctic Fox', 0x546E7A, 0xCFD8DC),
      ('a003', 'Macaw Flight', 0xC2185B, 0xF48FB1),
      ('a004', 'Playful Dolphins', 0x0277BD, 0x81D4FA),
      ('a005', 'Savanna Giraffe', 0xF57F17, 0xFFEE58),
    ],
    'flowers': [
      ('f001', 'Red Rose Garden', 0xB71C1C, 0xEF5350),
      ('f002', 'Lavender Fields', 0x4A148C, 0xBA68C8),
      ('f003', 'Sunflowers at Noon', 0xF57F17, 0xFFD54F),
      ('f004', 'White Lotus', 0x004D40, 0x80CBC4),
      ('f005', 'Cherry Blossoms', 0x880E4F, 0xF8BBD0),
    ],
    'landmarks': [
      ('l001', 'Eiffel Tower', 0x263238, 0x78909C),
      ('l002', 'Taj Mahal', 0xD84315, 0xFFAB91),
      ('l003', 'Colosseum Dawn', 0x4E342E, 0xA1887F),
      ('l004', 'Great Wall', 0x33691E, 0x9CCC65),
      ('l005', 'Kyoto Pagoda', 0x880E4F, 0xE91E63),
    ],
    'art': [
      ('art001', 'Starry Canvas', 0x1A237E, 0x5C6BC0),
      ('art002', 'Cubist Harmony', 0xE65100, 0x29B6F6),
      ('art003', 'Golden Mosaic', 0xFF6F00, 0xFFCA28),
      ('art004', 'Watercolor Bloom', 0xAD1457, 0x4DD0E1),
      ('art005', 'Abstract Rhythm', 0x311B92, 0x00E676),
    ],
  };

  const width = 800;
  const height = 600;

  for (final entry in categories.entries) {
    final catName = entry.key;
    final catDir = Directory('${baseDir.path}/$catName');
    if (!catDir.existsSync()) {
      catDir.createSync(recursive: true);
    }

    for (final item in entry.value) {
      final id = item.$1;
      final color1 = item.$3;
      final color2 = item.$4;
      final file = File('${catDir.path}/$id.bmp');

      final bytes = _generateBmp(width, height, color1, color2);
      file.writeAsBytesSync(bytes);
      stdout.writeln('Generated asset: ${file.path}');
    }
  }

  // Write sample premium.txt
  final premiumFile = File('tool/premium.txt');
  if (!premiumFile.existsSync()) {
    premiumFile.writeAsStringSync('n005\na005\nf005\nl005\nart005\n');
  }

  stdout.writeln('Sample assets generated successfully.');
}

Uint8List _generateBmp(int width, int height, int colorA, int colorB) {
  final rA = (colorA >> 16) & 0xFF;
  final gA = (colorA >> 8) & 0xFF;
  final bA = colorA & 0xFF;

  final rB = (colorB >> 16) & 0xFF;
  final gB = (colorB >> 8) & 0xFF;
  final bB = colorB & 0xFF;

  final rowPadding = (4 - (width * 3) % 4) % 4;
  final imageSize = (width * 3 + rowPadding) * height;
  const headerSize = 54;
  final fileSize = headerSize + imageSize;

  final buffer = Uint8List(fileSize);
  final byteData = ByteData.view(buffer.buffer);

  // BMP Header
  buffer[0] = 0x42; // 'B'
  buffer[1] = 0x4D; // 'M'
  byteData.setUint32(2, fileSize, Endian.little);
  byteData.setUint32(6, 0, Endian.little); // Reserved
  byteData.setUint32(10, headerSize, Endian.little); // Offset to image data

  // DIB Header (BITMAPINFOHEADER)
  byteData.setUint32(14, 40, Endian.little); // Header size
  byteData.setInt32(18, width, Endian.little);
  byteData.setInt32(22, height, Endian.little); // Bottom-up
  byteData.setUint16(26, 1, Endian.little); // Color planes
  byteData.setUint16(28, 24, Endian.little); // Bits per pixel (24-bit RGB)
  byteData.setUint32(30, 0, Endian.little); // No compression (BI_RGB)
  byteData.setUint32(34, imageSize, Endian.little);
  byteData.setInt32(38, 2835, Endian.little); // Horizontal resolution (72 DPI)
  byteData.setInt32(42, 2835, Endian.little); // Vertical resolution
  byteData.setUint32(46, 0, Endian.little);
  byteData.setUint32(50, 0, Endian.little);

  // Pixel data (BGR format, bottom to top)
  var offset = headerSize;
  for (var y = 0; y < height; y++) {
    final tY = y / height;
    for (var x = 0; x < width; x++) {
      final tX = x / width;
      final t = (tX * 0.6 + tY * 0.4);

      // Vignette effect
      final dx = (x - width / 2) / (width / 2);
      final dy = (y - height / 2) / (height / 2);
      final distSq = dx * dx + dy * dy;
      final vignette = (1.0 - distSq * 0.25).clamp(0.0, 1.0);

      // Decorative concentric pattern for puzzle visual cues
      final pattern = ((x ~/ 40 + y ~/ 40) % 2 == 0) ? 1.05 : 0.95;

      final r = (((rA + (rB - rA) * t) * vignette * pattern)).clamp(0, 255).toInt();
      final g = (((gA + (gB - gA) * t) * vignette * pattern)).clamp(0, 255).toInt();
      final b = (((bA + (bB - bA) * t) * vignette * pattern)).clamp(0, 255).toInt();

      buffer[offset++] = b;
      buffer[offset++] = g;
      buffer[offset++] = r;
    }
    for (var p = 0; p < rowPadding; p++) {
      buffer[offset++] = 0;
    }
  }

  return buffer;
}
