import 'package:go_router/go_router.dart';
import 'package:jigsaw_pro/features/gallery/presentation/pages/difficulty_picker_page.dart';
import 'package:jigsaw_pro/features/gallery/presentation/pages/gallery_page.dart';
import 'package:jigsaw_pro/features/home/presentation/pages/home_page.dart';
import 'package:jigsaw_pro/features/home/presentation/pages/splash_page.dart';
import 'package:jigsaw_pro/features/monetization/presentation/pages/shop_page.dart';
import 'package:jigsaw_pro/features/puzzle/presentation/pages/puzzle_page.dart';
import 'package:jigsaw_pro/features/puzzle/presentation/pages/win_page.dart';
import 'package:jigsaw_pro/features/settings/presentation/pages/settings_page.dart';

class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: '/gallery',
        builder: (context, state) {
          final category = state.uri.queryParameters['category'];
          return GalleryPage(initialCategory: category);
        },
      ),
      GoRoute(
        path: '/difficulty/:pictureId',
        builder: (context, state) {
          final pictureId = state.pathParameters['pictureId'] ?? 'n001';
          final defaultCountStr = state.uri.queryParameters['defaultCount'];
          final defaultCount = defaultCountStr != null ? int.tryParse(defaultCountStr) : null;
          return DifficultyPickerPage(
            pictureId: pictureId,
            initialCount: defaultCount,
          );
        },
      ),
      GoRoute(
        path: '/puzzle',
        builder: (context, state) {
          final id = state.uri.queryParameters['id'];
          final countStr = state.uri.queryParameters['count'];
          final isResume = state.uri.queryParameters['resume'] == 'true';
          final count = countStr != null ? int.tryParse(countStr) : null;

          return PuzzlePage(
            pictureId: id,
            pieceCount: count,
            isResume: isResume,
          );
        },
      ),
      GoRoute(
        path: '/win',
        builder: (context, state) => const WinPage(),
      ),
      GoRoute(
        path: '/shop',
        builder: (context, state) => const ShopPage(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsPage(),
      ),
    ],
  );
}
