import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jigsaw_pro/core/audio/audio_service.dart';
import 'package:jigsaw_pro/core/haptics/haptic_service.dart';
import 'package:jigsaw_pro/core/storage/hive_storage.dart';
import 'package:jigsaw_pro/core/theme/app_theme.dart';

class SettingsController extends GetxController {
  final HiveStorage _storage;
  final AudioService _audio;
  final HapticService _haptics;

  SettingsController(this._storage, this._audio, this._haptics);

  late final RxBool soundEnabled;
  late final RxBool musicEnabled;
  late final RxBool vibrationEnabled;
  late final RxBool keepScreenAwake;
  late final RxString themeModeString;
  late final Rx<BoardBackgroundStyle> boardBackground;
  late final RxString screenTheme;
  late final RxInt freeHints;

  @override
  void onInit() {
    super.onInit();
    soundEnabled = _storage.soundEnabled.obs;
    musicEnabled = _storage.musicEnabled.obs;
    vibrationEnabled = _storage.vibrationEnabled.obs;
    keepScreenAwake = _storage.keepScreenAwake.obs;
    themeModeString = _storage.themeMode.obs;
    screenTheme = _storage.screenTheme.obs;
    final initialHints = _storage.freeHints.clamp(0, 3);
    freeHints = initialHints.obs;
    _storage.setFreeHints(freeHints.value);

    final savedBg = BoardBackgroundStyle.values.firstWhere(
      (b) => b.name == _storage.boardBackground,
      orElse: () => BoardBackgroundStyle.cleanLight,
    );
    boardBackground = savedBg.obs;
  }

  void toggleSound() {
    _haptics.click();
    soundEnabled.value = !soundEnabled.value;
    _storage.setSoundEnabled(soundEnabled.value);
    if (soundEnabled.value) {
      _audio.playClick();
    }
  }

  void toggleMusic() {
    _haptics.click();
    _audio.playClick();
    musicEnabled.value = !musicEnabled.value;
    _storage.setMusicEnabled(musicEnabled.value);
    _audio.updateMusicPreference(musicEnabled.value);
  }

  void toggleKeepScreenAwake() {
    _haptics.click();
    _audio.playClick();
    keepScreenAwake.value = !keepScreenAwake.value;
    _storage.setKeepScreenAwake(keepScreenAwake.value);
  }

  void toggleVibration() {
    vibrationEnabled.value = !vibrationEnabled.value;
    _storage.setVibrationEnabled(vibrationEnabled.value);
    _haptics.click();
    _audio.playClick();
  }

  void addFreeHint([int count = 1]) {
    freeHints.value += count;
    _storage.setFreeHints(freeHints.value);
  }

  bool useFreeHint() {
    if (freeHints.value > 0) {
      freeHints.value--;
      _storage.setFreeHints(freeHints.value);
      return true;
    }
    return false;
  }

  void setThemeMode(String mode) {
    themeModeString.value = mode;
    _storage.setThemeMode(mode);
    if (mode == 'light') {
      Get.changeThemeMode(ThemeMode.light);
    } else if (mode == 'dark') {
      Get.changeThemeMode(ThemeMode.dark);
    } else {
      Get.changeThemeMode(ThemeMode.system);
    }
  }

  ThemeMode get currentThemeMode {
    if (themeModeString.value == 'light') return ThemeMode.light;
    if (themeModeString.value == 'dark') return ThemeMode.dark;
    return ThemeMode.system;
  }

  void setBoardBackground(BoardBackgroundStyle style) {
    boardBackground.value = style;
    _storage.setBoardBackground(style.name);
  }

  void setScreenTheme(String theme) {
    screenTheme.value = theme;
    _storage.setScreenTheme(theme);
  }

  Future<void> resetAllGameData() async {
    await _storage.resetAllGameData();
    freeHints.value = 3;
  }
}
