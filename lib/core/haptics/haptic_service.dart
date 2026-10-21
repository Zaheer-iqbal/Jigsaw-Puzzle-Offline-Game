import 'package:flutter/services.dart';
import 'package:jigsaw_pro/core/storage/hive_storage.dart';

class HapticService {
  final HiveStorage _storage;

  HapticService(this._storage);

  Future<void> snap() async {
    if (!_storage.vibrationEnabled) return;
    await HapticFeedback.mediumImpact();
  }

  Future<void> click() async {
    if (!_storage.vibrationEnabled) return;
    await HapticFeedback.selectionClick();
  }

  Future<void> win() async {
    if (!_storage.vibrationEnabled) return;
    await HapticFeedback.heavyImpact();
  }
}
