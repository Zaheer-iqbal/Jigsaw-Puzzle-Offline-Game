import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:jigsaw_pro/core/storage/hive_storage.dart';

class AudioService {
  final HiveStorage _storage;
  final AudioPlayer _player = AudioPlayer();

  AudioService(this._storage) {
    _player.setAudioContext(AudioContext(
      android: const AudioContextAndroid(
        isSpeakerphoneOn: false,
        stayAwake: false,
        contentType: AndroidContentType.sonification,
        usageType: AndroidUsageType.game,
        audioFocus: AndroidAudioFocus.none,
      ),
    ));
  }

  Future<void> playSnap() async {
    if (!_storage.soundEnabled) return;
    try {
      await _player.stop();
      await _player.play(AssetSource('sounds/snap.wav'), volume: 0.7);
    } catch (e) {
      debugPrint('Audio play error: $e');
    }
  }

  Future<void> playWin() async {
    if (!_storage.soundEnabled) return;
    try {
      await _player.stop();
      await _player.play(AssetSource('sounds/win.wav'), volume: 0.9);
    } catch (e) {
      debugPrint('Audio play error: $e');
    }
  }

  Future<void> playClick() async {
    if (!_storage.soundEnabled) return;
    try {
      await _player.stop();
      await _player.play(AssetSource('sounds/click.wav'), volume: 0.5);
    } catch (e) {
      debugPrint('Audio play error: $e');
    }
  }

  void dispose() {
    _player.dispose();
  }
}
