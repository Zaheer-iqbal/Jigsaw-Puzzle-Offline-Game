import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:jigsaw_pro/core/storage/hive_storage.dart';

class AudioService {
  final HiveStorage _storage;
  final AudioPlayer _sfxPlayer = AudioPlayer();
  final AudioPlayer _bgmPlayer = AudioPlayer();

  bool _isBgmPlaying = false;

  AudioService(this._storage) {
    _initPlayers();
  }

  Future<void> _initPlayers() async {
    try {
      await _sfxPlayer.setAudioContext(AudioContext(
        android: const AudioContextAndroid(
          isSpeakerphoneOn: false,
          stayAwake: false,
          contentType: AndroidContentType.sonification,
          usageType: AndroidUsageType.game,
          audioFocus: AndroidAudioFocus.none,
        ),
      ));
      await _sfxPlayer.setPlayerMode(PlayerMode.lowLatency);

      await _bgmPlayer.setAudioContext(AudioContext(
        android: const AudioContextAndroid(
          isSpeakerphoneOn: false,
          stayAwake: false,
          contentType: AndroidContentType.music,
          usageType: AndroidUsageType.game,
          audioFocus: AndroidAudioFocus.gainTransientMayDuck,
        ),
      ));
      await _bgmPlayer.setReleaseMode(ReleaseMode.loop);
      await _bgmPlayer.setVolume(0.35);

      if (_storage.musicEnabled) {
        startBgm();
      }
    } catch (e) {
      debugPrint('AudioService init error: $e');
    }
  }

  /// Starts or resumes soothing ambient background music
  Future<void> startBgm() async {
    if (!_storage.musicEnabled) return;
    try {
      if (!_isBgmPlaying) {
        await _bgmPlayer.play(AssetSource('sounds/bgm.wav'));
        _isBgmPlaying = true;
      }
    } catch (e) {
      debugPrint('BGM play error: $e');
    }
  }

  /// Stops background music
  Future<void> stopBgm() async {
    try {
      await _bgmPlayer.stop();
      _isBgmPlaying = false;
    } catch (e) {
      debugPrint('BGM stop error: $e');
    }
  }

  /// Pauses background music (e.g. when watching an ad)
  Future<void> pauseBgm() async {
    try {
      if (_isBgmPlaying) {
        await _bgmPlayer.pause();
      }
    } catch (e) {
      debugPrint('BGM pause error: $e');
    }
  }

  /// Resumes background music (e.g. after ad finishes)
  Future<void> resumeBgm() async {
    if (!_storage.musicEnabled) return;
    try {
      if (_isBgmPlaying) {
        await _bgmPlayer.resume();
      } else {
        startBgm();
      }
    } catch (e) {
      debugPrint('BGM resume error: $e');
    }
  }

  /// Called when user toggles music switch in Settings
  void updateMusicPreference(bool enabled) {
    if (enabled) {
      startBgm();
    } else {
      stopBgm();
    }
  }

  Future<void> playSnap() async {
    if (!_storage.soundEnabled) return;
    try {
      await _sfxPlayer.stop();
      await _sfxPlayer.play(AssetSource('sounds/snap.wav'), volume: 0.85);
    } catch (e) {
      debugPrint('Snap sound error: $e');
    }
  }

  Future<void> playWin() async {
    if (!_storage.soundEnabled) return;
    try {
      await _sfxPlayer.stop();
      await _sfxPlayer.play(AssetSource('sounds/win.wav'), volume: 1.0);
    } catch (e) {
      debugPrint('Win sound error: $e');
    }
  }

  Future<void> playClick() async {
    if (!_storage.soundEnabled) return;
    try {
      await _sfxPlayer.stop();
      await _sfxPlayer.play(AssetSource('sounds/click.wav'), volume: 0.6);
    } catch (e) {
      debugPrint('Click sound error: $e');
    }
  }

  void dispose() {
    _sfxPlayer.dispose();
    _bgmPlayer.dispose();
  }
}
