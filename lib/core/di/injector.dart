import 'package:get/get.dart';
import 'package:get_it/get_it.dart';
import 'package:jigsaw_pro/core/audio/audio_service.dart';
import 'package:jigsaw_pro/core/haptics/haptic_service.dart';
import 'package:jigsaw_pro/core/storage/hive_storage.dart';
import 'package:jigsaw_pro/features/content/data/datasources/asset_manifest_data_source.dart';
import 'package:jigsaw_pro/features/content/data/repositories/puzzle_repository_impl.dart';
import 'package:jigsaw_pro/features/content/domain/repositories/puzzle_repository.dart';
import 'package:jigsaw_pro/features/content/presentation/controllers/content_controller.dart';
import 'package:jigsaw_pro/features/economy/presentation/controllers/economy_controller.dart';
import 'package:jigsaw_pro/features/monetization/presentation/controllers/monetization_controller.dart';
import 'package:jigsaw_pro/features/puzzle/presentation/controllers/puzzle_controller.dart';
import 'package:jigsaw_pro/features/settings/presentation/controllers/settings_controller.dart';

final getIt = GetIt.instance;

class AppInjector {
  AppInjector._();

  static Future<void> init() async {
    // 1. Local Storage (Hive)
    final storage = HiveStorage();
    await storage.init();
    getIt.registerSingleton<HiveStorage>(storage);
    Get.put<HiveStorage>(storage, permanent: true);

    // 2. Audio & Haptics
    final audio = AudioService(storage);
    final haptics = HapticService(storage);
    getIt.registerSingleton<AudioService>(audio);
    getIt.registerSingleton<HapticService>(haptics);
    Get.put<AudioService>(audio, permanent: true);
    Get.put<HapticService>(haptics, permanent: true);

    // 3. Domain & Data Content Repositories
    final manifestDataSource = AssetManifestDataSource();
    final puzzleRepository = PuzzleRepositoryImpl(manifestDataSource);
    getIt.registerSingleton<PuzzleRepository>(puzzleRepository);
    Get.put<PuzzleRepository>(puzzleRepository, permanent: true);

    // 4. GetX Controllers (State Management)
    Get.put(SettingsController(storage, audio, haptics), permanent: true);
    final economyController = Get.put(EconomyController(storage), permanent: true);
    final monetizationController = Get.put(MonetizationController(storage, economyController), permanent: true);
    Get.put(ContentController(puzzleRepository, storage), permanent: true);
    Get.put(
      PuzzleController(
        storage,
        audio,
        haptics,
        economyController,
        monetizationController,
      ),
      permanent: true,
    );
  }
}
