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

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
    ),
  );

  // Initialize all storage, repos, audio, ads, and GetX controllers
  await AppInjector.init();

  runApp(const JigsawProApp());
}
