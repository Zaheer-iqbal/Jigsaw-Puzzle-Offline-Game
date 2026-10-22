import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jigsaw_pro/core/storage/hive_storage.dart';
import 'package:jigsaw_pro/core/theme/app_theme.dart';

class SettingsController extends GetxController {
  final HiveStorage _storage;

  SettingsController(this._storage);

  late final RxBool soundEnabled;
  late final RxBool musicEnabled;
  late final RxBool vibrationEnabled;
  late final RxBool keepScreenAwake;
  late final RxString themeModeString;
  late final Rx<BoardBackgroundStyle> boardBackground;
  late final RxInt freeHints;

  @override
  void onInit() {
    super.onInit();
    soundEnabled = _storage.soundEnabled.obs;
    musicEnabled = _storage.musicEnabled.obs;
    vibrationEnabled = _storage.vibrationEnabled.obs;
    keepScreenAwake = _storage.keepScreenAwake.obs;
    themeModeString = _storage.themeMode.obs;
    freeHints = _storage.freeHints.obs;

    final savedBg = BoardBackgroundStyle.values.firstWhere(
      (b) => b.name == _storage.boardBackground,
      orElse: () => BoardBackgroundStyle.cleanLight,
    );
    boardBackground = savedBg.obs;
  }

  void toggleSound() {
    soundEnabled.value = !soundEnabled.value;
    _storage.setSoundEnabled(soundEnabled.value);
  }

  void toggleMusic() {
    musicEnabled.value = !musicEnabled.value;
    _storage.setMusicEnabled(musicEnabled.value);
  }

  void toggleKeepScreenAwake() {
    keepScreenAwake.value = !keepScreenAwake.value;
    _storage.setKeepScreenAwake(keepScreenAwake.value);
  }

  void toggleVibration() {
    vibrationEnabled.value = !vibrationEnabled.value;
    _storage.setVibrationEnabled(vibrationEnabled.value);
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
}
