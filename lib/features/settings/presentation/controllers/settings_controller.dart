import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jigsaw_pro/core/storage/hive_storage.dart';
import 'package:jigsaw_pro/core/theme/app_theme.dart';

class SettingsController extends GetxController {
  final HiveStorage _storage;

  SettingsController(this._storage);

  late final RxBool soundEnabled;
  late final RxBool vibrationEnabled;
  late final RxString themeModeString;
  late final Rx<BoardBackgroundStyle> boardBackground;

  @override
  void onInit() {
    super.onInit();
    soundEnabled = _storage.soundEnabled.obs;
    vibrationEnabled = _storage.vibrationEnabled.obs;
    themeModeString = _storage.themeMode.obs;

    final savedBg = BoardBackgroundStyle.values.firstWhere(
      (b) => b.name == _storage.boardBackground,
      orElse: () => BoardBackgroundStyle.feltGreen,
    );
    boardBackground = savedBg.obs;
  }

  void toggleSound() {
    soundEnabled.value = !soundEnabled.value;
    _storage.setSoundEnabled(soundEnabled.value);
  }

  void toggleVibration() {
    vibrationEnabled.value = !vibrationEnabled.value;
    _storage.setVibrationEnabled(vibrationEnabled.value);
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
