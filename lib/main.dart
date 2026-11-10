import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jigsaw_pro/app.dart';
import 'package:jigsaw_pro/core/di/injector.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Allow both portrait and landscape orientations as requested by user
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Set system UI overlay style with edge-to-edge transparency
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
    ),
  );
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // Initialize all storage, repos, audio, ads, and GetX controllers
  await AppInjector.init();

  runApp(const JigsawProApp());
}
