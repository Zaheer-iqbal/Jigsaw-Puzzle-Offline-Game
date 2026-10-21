import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

void main() {
  final dir = Directory('assets/sounds');
  if (!dir.existsSync()) dir.createSync(recursive: true);

  File('${dir.path}/snap.wav').writeAsBytesSync(_generateTone(
    durationMs: 90,
    startFreq: 520,
    endFreq: 220,
    sampleRate: 22050,
  ));

  File('${dir.path}/click.wav').writeAsBytesSync(_generateTone(
    durationMs: 40,
    startFreq: 800,
    endFreq: 400,
    sampleRate: 22050,
  ));

  File('${dir.path}/win.wav').writeAsBytesSync(_generateChime(
    sampleRate: 22050,
  ));

  stdout.writeln('Generated audio files: snap.wav, click.wav, win.wav');
}

Uint8List _generateTone({
  required int durationMs,
  required double startFreq,
  required double endFreq,
  required int sampleRate,
}) {
  final numSamples = (durationMs * sampleRate) ~/ 1000;
  final byteSize = numSamples * 2;
  final buffer = Uint8List(44 + byteSize);
  final byteData = ByteData.view(buffer.buffer);

  _writeWavHeader(byteData, sampleRate, byteSize);

  for (var i = 0; i < numSamples; i++) {
    final t = i / numSamples;
    final freq = startFreq + (endFreq - startFreq) * t;
    final phase = 2 * pi * freq * (i / sampleRate);
    final envelope = (1.0 - t) * (1.0 - t);
    final sample = (sin(phase) * envelope * 24000).toInt().clamp(-32768, 32767);
    byteData.setInt16(44 + i * 2, sample, Endian.little);
  }

  return buffer;
}

Uint8List _generateChime({required int sampleRate}) {
  const durationMs = 700;
  final numSamples = (durationMs * sampleRate) ~/ 1000;
  final byteSize = numSamples * 2;
  final buffer = Uint8List(44 + byteSize);
  final byteData = ByteData.view(buffer.buffer);

  _writeWavHeader(byteData, sampleRate, byteSize);

  final notes = [523.25, 659.25, 783.99, 1046.50]; // C5, E5, G5, C6
  for (var i = 0; i < numSamples; i++) {
    final tGlobal = i / sampleRate;
    double totalAmp = 0;

    for (var n = 0; n < notes.length; n++) {
      final noteStartTime = n * 0.12;
      if (tGlobal >= noteStartTime) {
        final tNote = tGlobal - noteStartTime;
        final env = exp(-tNote * 6.0);
        final phase = 2 * pi * notes[n] * tNote;
        totalAmp += sin(phase) * env;
      }
    }

    final sample = (totalAmp * 8000).toInt().clamp(-32768, 32767);
    byteData.setInt16(44 + i * 2, sample, Endian.little);
  }

  return buffer;
}

void _writeWavHeader(ByteData b, int sampleRate, int dataSize) {
  // "RIFF"
  b.setUint8(0, 0x52); b.setUint8(1, 0x49); b.setUint8(2, 0x46); b.setUint8(3, 0x46);
  b.setUint32(4, 36 + dataSize, Endian.little);
  // "WAVE"
  b.setUint8(8, 0x57); b.setUint8(9, 0x41); b.setUint8(10, 0x56); b.setUint8(11, 0x45);
  // "fmt "
  b.setUint8(12, 0x66); b.setUint8(13, 0x6D); b.setUint8(14, 0x74); b.setUint8(15, 0x20);
  b.setUint32(16, 16, Endian.little); // PCM format size
  b.setUint16(20, 1, Endian.little);  // PCM format
  b.setUint16(22, 1, Endian.little);  // Mono
  b.setUint32(24, sampleRate, Endian.little);
  b.setUint32(28, sampleRate * 2, Endian.little); // Byte rate (16-bit mono)
  b.setUint16(32, 2, Endian.little);  // Block align
  b.setUint16(34, 16, Endian.little); // Bits per sample
  // "data"
  b.setUint8(36, 0x64); b.setUint8(37, 0x61); b.setUint8(38, 0x74); b.setUint8(39, 0x61);
  b.setUint32(40, dataSize, Endian.little);
}
