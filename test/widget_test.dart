import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jigsaw_pro/core/config/app_config.dart';
import 'package:jigsaw_pro/core/theme/app_theme.dart';

void main() {
  testWidgets('App theme and config smoke test', (WidgetTester tester) async {
    expect(AppConfig.appName, 'Jigsaw Puzzle: Offline Game');
    expect(AppConfig.startingCoins, 50);
    expect(AppConfig.snapThresholdRatio, 0.28);
    expect(AppTheme.primaryTeal, const Color(0xFF00796B));
  });
}
