import 'package:flutter/services.dart';
import 'package:jigsaw_pro/core/storage/hive_storage.dart';

class HapticService {
  final HiveStorage _storage;

  HapticService(this._storage);

  /// Snappy haptic for piece connection
  Future<void> snap() async {
    if (!_storage.vibrationEnabled) return;
    try {
      await HapticFeedback.mediumImpact();
    } catch (_) {}
  }

  /// Responsive haptic for button taps & selections (works on all Android devices)
  Future<void> click() async {
    if (!_storage.vibrationEnabled) return;
    try {
      await HapticFeedback.lightImpact();
    } catch (_) {}
  }

  /// Celebratory haptic when a puzzle is finished
  Future<void> win() async {
    if (!_storage.vibrationEnabled) return;
    try {
      await HapticFeedback.heavyImpact();
    } catch (_) {}
  }
}
