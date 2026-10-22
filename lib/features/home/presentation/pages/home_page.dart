import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:jigsaw_pro/core/storage/hive_storage.dart';
import 'package:jigsaw_pro/core/theme/app_theme.dart';
import 'package:jigsaw_pro/core/widgets/casual_game_background.dart';
import 'package:jigsaw_pro/features/content/domain/entities/puzzle_level.dart';
import 'package:jigsaw_pro/features/content/presentation/controllers/content_controller.dart';
import 'package:jigsaw_pro/features/economy/presentation/controllers/economy_controller.dart';
import 'package:jigsaw_pro/features/monetization/presentation/controllers/monetization_controller.dart';
import 'package:jigsaw_pro/features/settings/presentation/controllers/settings_controller.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final storage = Get.find<HiveStorage>();
    final content = Get.find<ContentController>();
    final economy = Get.find<EconomyController>();
    final settings = Get.find<SettingsController>();
    final monetization = Get.find<MonetizationController>();

    final activeSession = storage.getActiveSession();

    final highestSaga = storage.getHighestSagaLevel();

    return Scaffold(
      backgroundColor: Colors.transparent,
      bottomNavigationBar: _buildBottomNav(context, storage, settings, monetization, economy, content),
      body: CasualGameBackground(
        child: SafeArea(
          child: _buildHeroHomeView(context, storage, content, economy, settings, monetization, activeSession, highestSaga),
        ),
      ),
    );
  }

  // --- Casual Hero Home View (Exact UI from Reference Screenshot) ---
  Widget _buildHeroHomeView(
    BuildContext context,
    HiveStorage storage,
    ContentController content,
    EconomyController economy,
    SettingsController settings,
    MonetizationController monetization,
    Map<String, dynamic>? activeSession,
    int highestSaga,
  ) {
    final heroImagePath = _getHeroImagePath(activeSession, content, highestSaga);
    final heroTitle = _getHeroTitle(activeSession, content, highestSaga);
    final heroPieces = _getHeroPieces(activeSession, content, highestSaga);
    final heroProgress = _getHeroProgress(activeSession);
    final heroProgressPercent = '${(heroProgress * 100).toInt()}%';
    final isContinue = activeSession != null;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 8),

          // Top Header Bar: Coins Pill (Left) | Streak Pill (Center) | Settings Sliders (Right)
          _buildTopBar(context, economy, storage, settings, monetization),

          const SizedBox(height: 14),

          // App Branding Title: "Jigsaw Journey" + "Puzzle Games"
          _buildBrandHeader(),

          const SizedBox(height: 18),

          // Main Hero Puzzle Card (Continue / Sunset Hills)
          _buildHeroCard(
            context: context,
            imagePath: heroImagePath,
            title: heroTitle,
            pieceCount: heroPieces,
            progress: heroProgress,
            progressPercent: heroProgressPercent,
            isContinue: isContinue,
            highestSaga: highestSaga,
            activeSession: activeSession,
            content: content,
          ),

          const SizedBox(height: 14),

          // Big 3D Tactile Golden PLAY Button
          _buildBigPlayButton(
            onPressed: () => _onPlayHeroPressed(context, activeSession, content, highestSaga),
          ),

          const SizedBox(height: 18),

          // Daily Puzzle Card (+20 coins today)
          _buildDailyPuzzleCard(context, content),

          const SizedBox(height: 18),

          // Collections Section (WITH REAL IMAGES)
          _buildCollectionsSection(context, content),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // --- Top Status Bar ---
  Widget _buildTopBar(
    BuildContext context,
    EconomyController economy,
    HiveStorage storage,
    SettingsController settings,
    MonetizationController monetization,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Coins Pill with Green + Button
        Obx(() {
          final coins = economy.coins.value;
          return Container(
            padding: const EdgeInsets.fromLTRB(10, 5, 6, 5),
            decoration: BoxDecoration(
              color: const Color(0xFF132238),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.20),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.monetization_on_rounded, color: Color(0xFFFFB300), size: 18),
                const SizedBox(width: 5),
                Text(
                  '$coins',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13),
                ),
                const SizedBox(width: 6),
                InkWell(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    context.push('/shop');
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF00E676),
                    ),
                    child: const Icon(Icons.add_rounded, color: Colors.white, size: 14),
                  ),
                ),
              ],
            ),
          );
        }),

        // Streak Pill
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF132238),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.20),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.local_fire_department_rounded, color: Color(0xFFFF9100), size: 18),
              const SizedBox(width: 5),
              Text(
                '${storage.streak > 0 ? storage.streak : 3} days',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13),
              ),
            ],
          ),
        ),

        // Settings / Sliders Filter Circular Button
        InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            _showProfileModal(context, storage, settings, monetization, economy);
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF132238),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.20),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(Icons.tune_rounded, color: Colors.white, size: 20),
          ),
        ),
      ],
    );
  }

  // --- App Branding Header ---
  Widget _buildBrandHeader() {
    return Column(
      children: [
        Text(
          'Jigsaw Puzzle',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.6,
            color: Colors.white,
            shadows: [
              Shadow(
                offset: const Offset(0, 3.5),
                color: const Color(0xFF0D2544),
                blurRadius: 0,
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Offline Game',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.8,
            color: const Color(0xFFFFC107),
            shadows: [
              Shadow(
                offset: const Offset(0, 2),
                color: const Color(0x664E342E),
                blurRadius: 0,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- Hero Puzzle Featured Card ---
  Widget _buildHeroCard({
    required BuildContext context,
    required String imagePath,
    required String title,
    required int pieceCount,
    required double progress,
    required String progressPercent,
    required bool isContinue,
    required int highestSaga,
    required Map<String, dynamic>? activeSession,
    required ContentController content,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Preview Container with rounded corners
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Stack(
              children: [
                // Real Image Asset
                Image.asset(
                  imagePath,
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 160,
                    color: const Color(0xFF64B5F6),
                    child: const Center(
                      child: Icon(Icons.image_rounded, size: 48, color: Colors.white),
                    ),
                  ),
                ),

                // Subtle jigsaw watermark silhouette overlay
                Positioned(
                  top: 10,
                  right: 14,
                  child: Icon(
                    Icons.extension_rounded,
                    size: 44,
                    color: Colors.white.withValues(alpha: 0.35),
                  ),
                ),

                // Badge: "Continue" (pink) or "Level X"
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF3366),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF3366).withValues(alpha: 0.4),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      isContinue ? 'Continue' : 'Level $highestSaga',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 11,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Title & Stats Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFF1E293B),
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$pieceCount pieces',
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              Text(
                progressPercent,
                style: const TextStyle(
                  color: Color(0xFF1E293B),
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Emerald Green Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 7,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: const AlwaysStoppedAnimation(Color(0xFF00E676)),
            ),
          ),
          const SizedBox(height: 2),
        ],
      ),
    );
  }

  // --- Big 3D Tactile PLAY Button ---
  Widget _buildBigPlayButton({required VoidCallback onPressed}) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(28),
      child: Container(
        width: 230,
        height: 54,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: const LinearGradient(
            colors: [
              Color(0xFFFFCA28),
              Color(0xFFFFA000),
              Color(0xFFFF8F00),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFD87C00).withValues(alpha: 0.90),
              offset: const Offset(0, 5),
              blurRadius: 0,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.22),
              offset: const Offset(0, 8),
              blurRadius: 10,
            ),
          ],
        ),
        alignment: Alignment.center,
        child: const Text(
          'PLAY',
          style: TextStyle(
            color: Color(0xFF3E2723),
            fontSize: 22,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.8,
          ),
        ),
      ),
    );
  }

  // --- Daily Puzzle Card ---
  Widget _buildDailyPuzzleCard(BuildContext context, ContentController content) {
    return Obx(() {
      final dailyPic = content.dailyPicture.value;
      final dailyImg = dailyPic?.path ?? 'assets/puzzles/animals/a001.bmp';

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xEE112238),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.20),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Daily Real Image Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                dailyImg,
                width: 48,
                height: 48,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 48,
                  height: 48,
                  color: AppTheme.accentAmber,
                  child: const Icon(Icons.extension_rounded, color: Colors.white, size: 28),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Daily Text & Coin Bonus
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Daily Puzzle',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: const [
                      Icon(Icons.monetization_on_rounded, color: Color(0xFFFFD54F), size: 14),
                      SizedBox(width: 4),
                      Text(
                        '+20 coins today',
                        style: TextStyle(color: Color(0xFFFFD54F), fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Green Play Button
            InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                final picId = dailyPic?.id ?? 'n001.bpm';
                context.push('/difficulty/$picId?defaultCount=48&daily=true');
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                decoration: BoxDecoration(
                  color: const Color(0xFF00E676),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00E676).withValues(alpha: 0.35),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Text(
                  'Play',
                  style: TextStyle(color: Color(0xFF053E1B), fontWeight: FontWeight.w900, fontSize: 13),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  // --- Collections Section (WITH REAL ASSET IMAGES) ---
  Widget _buildCollectionsSection(BuildContext context, ContentController content) {
    final categoriesData = [
      {'id': 'nature', 'name': 'Nature', 'fallback': 'assets/puzzles/nature/n001.bpm.jpg'},
      {'id': 'animals', 'name': 'Animals', 'fallback': 'assets/puzzles/animals/a001.bmp'},
      {'id': 'flowers', 'name': 'Flowers', 'fallback': 'assets/puzzles/flowers/f001.bpm.jpg'},
      {'id': 'landmarks', 'name': 'Landmarks', 'fallback': 'assets/puzzles/landmarks/l001.bmp'},
      {'id': 'art', 'name': 'Art', 'fallback': 'assets/puzzles/art/art001.bmp'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // "Collections" Title
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            'Collections',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 18,
              letterSpacing: 0.3,
            ),
          ),
        ),

        // Horizontal Carousel of Real Images
        SizedBox(
          height: 114,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: categoriesData.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final cat = categoriesData[index];
              final catId = cat['id']!;
              final catName = cat['name']!;
              final realImgPath = _getCategoryRealImagePath(catId, content, cat['fallback']!);

              return InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  context.push('/gallery?category=$catId');
                },
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  width: 96,
                  height: 112,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.14),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Top: Real Photo from this category
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                        child: Image.asset(
                          realImgPath,
                          width: 96,
                          height: 76,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 96,
                            height: 76,
                            color: const Color(0xFF90CAF9),
                            child: const Icon(Icons.photo_library, color: Colors.white),
                          ),
                        ),
                      ),
                      // Bottom: Category Name Badge
                      Expanded(
                        child: Center(
                          child: Text(
                            catName,
                            style: const TextStyle(
                              color: Color(0xFF1E293B),
                              fontWeight: FontWeight.w900,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // --- Bottom Navigation Bar (Matching Reference Screenshot) ---
  Widget _buildBottomNav(
    BuildContext context,
    HiveStorage storage,
    SettingsController settings,
    MonetizationController monetization,
    EconomyController economy,
    ContentController content,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // 1. Home (Active Amber Circular Pill)
          InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
            },
            borderRadius: BorderRadius.circular(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFB300),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.home_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Home',
                  style: TextStyle(
                    color: Color(0xFFE65100),
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

          // 2. Gallery
          InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              context.push('/gallery');
            },
            borderRadius: BorderRadius.circular(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                  child: Icon(Icons.grid_view_rounded, color: Color(0xFF718096), size: 22),
                ),
                SizedBox(height: 2),
                Text(
                  'Gallery',
                  style: TextStyle(color: Color(0xFF718096), fontWeight: FontWeight.bold, fontSize: 11),
                ),
              ],
            ),
          ),

          // 3. Daily
          InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              final dailyPic = content.dailyPicture.value;
              final picId = dailyPic?.id ?? 'n001.bpm';
              context.push('/difficulty/$picId?defaultCount=48&daily=true');
            },
            borderRadius: BorderRadius.circular(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                  child: Icon(Icons.calendar_today_rounded, color: Color(0xFF718096), size: 20),
                ),
                SizedBox(height: 2),
                Text(
                  'Daily',
                  style: TextStyle(color: Color(0xFF718096), fontWeight: FontWeight.bold, fontSize: 11),
                ),
              ],
            ),
          ),

          // 4. Shop
          InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              context.push('/shop');
            },
            borderRadius: BorderRadius.circular(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                  child: Icon(Icons.shopping_bag_outlined, color: Color(0xFF718096), size: 22),
                ),
                SizedBox(height: 2),
                Text(
                  'Shop',
                  style: TextStyle(color: Color(0xFF718096), fontWeight: FontWeight.bold, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Real Asset Category Lookup ---
  String _getCategoryRealImagePath(String category, ContentController content, String fallback) {
    final match = content.allPictures.firstWhereOrNull(
      (p) => p.category.toLowerCase() == category.toLowerCase(),
    );
    if (match != null && match.path.isNotEmpty) {
      return match.path;
    }
    return fallback;
  }

  String _getHeroImagePath(Map<String, dynamic>? activeSession, ContentController content, int highestSaga) {
    if (activeSession != null && activeSession['picturePath'] != null) {
      return activeSession['picturePath'] as String;
    }
    final currentLevel = content.sagaLevels.firstWhereOrNull((l) => l.levelNumber == highestSaga);
    if (currentLevel != null && currentLevel.imagePath.isNotEmpty) {
      return currentLevel.imagePath;
    }
    return 'assets/puzzles/nature/n001.bpm.jpg';
  }

  String _getHeroTitle(Map<String, dynamic>? activeSession, ContentController content, int highestSaga) {
    if (activeSession != null && activeSession['pictureTitle'] != null) {
      return activeSession['pictureTitle'] as String;
    }
    final currentLevel = content.sagaLevels.firstWhereOrNull((l) => l.levelNumber == highestSaga);
    if (currentLevel != null && currentLevel.title.isNotEmpty) {
      return currentLevel.title;
    }
    return 'Sunset Hills';
  }

  int _getHeroPieces(Map<String, dynamic>? activeSession, ContentController content, int highestSaga) {
    if (activeSession != null && activeSession['actualPieceCount'] != null) {
      return activeSession['actualPieceCount'] as int;
    }
    final currentLevel = content.sagaLevels.firstWhereOrNull((l) => l.levelNumber == highestSaga);
    if (currentLevel != null) {
      return currentLevel.pieceCount;
    }
    return 100;
  }

  double _getHeroProgress(Map<String, dynamic>? activeSession) {
    if (activeSession != null) {
      final pieces = activeSession['actualPieceCount'] as int? ?? 100;
      final locked = (activeSession['lockedPieceKeys'] as List?)?.length ?? 0;
      return pieces > 0 ? (locked / pieces).clamp(0.0, 1.0) : 0.0;
    }
    return 0.62;
  }

  void _onPlayHeroPressed(
    BuildContext context,
    Map<String, dynamic>? activeSession,
    ContentController content,
    int highestSaga,
  ) {
    HapticFeedback.lightImpact();
    if (activeSession != null && activeSession['pictureId'] != null) {
      final picId = activeSession['pictureId'] as String;
      final pieces = activeSession['actualPieceCount'] as int? ?? 48;
      final saga = activeSession['sagaLevel'] as int?;
      context.push('/puzzle?id=$picId&pieces=$pieces${saga != null ? "&sagaLevel=$saga" : ""}&resume=true');
    } else {
      final currentLevel = content.sagaLevels.firstWhereOrNull((l) => l.levelNumber == highestSaga);
      if (currentLevel != null) {
        _startLevel(context, currentLevel);
      } else {
        context.push('/puzzle?id=n001.bpm&pieces=48&sagaLevel=1');
      }
    }
  }

  void _startLevel(BuildContext context, PuzzleLevel level) {
    HapticFeedback.lightImpact();
    context.push(
      '/puzzle?id=${level.pictureId}&pieces=${level.pieceCount}&sagaLevel=${level.levelNumber}',
    );
  }

  // --- Profile & Settings Game Hub Modal ---
  void _showProfileModal(
    BuildContext context,
    HiveStorage storage,
    SettingsController settings,
    MonetizationController monetization,
    EconomyController economy,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF141C28),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          maxChildSize: 0.95,
          minChildSize: 0.50,
          expand: false,
          builder: (_, scrollController) {
            final completedCount = storage.completedIds.length;
            final highest = storage.getHighestSagaLevel();
            int totalStars = 0;
            for (var i = 1; i <= 25; i++) {
              totalStars += storage.getSagaStars(i);
            }

            return ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
              children: [
                // Top drag pill
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Player Profile Header
                Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: AppTheme.accentAmber,
                      child: const Icon(Icons.person, color: Colors.white, size: 36),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Puzzle Master',
                            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Level $highest Explorer  •  Offline Active',
                            style: const TextStyle(color: AppTheme.accentAmber, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Player Stats Card
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E2838),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatBadge(Icons.extension_rounded, 'Solved', '$completedCount'),
                      Container(width: 1, height: 32, color: Colors.white12),
                      _buildStatBadge(Icons.star_rounded, 'Stars', '$totalStars/75', color: const Color(0xFFFFD700)),
                      Container(width: 1, height: 32, color: Colors.white12),
                      _buildStatBadge(Icons.monetization_on_rounded, 'Coins', '${economy.coins.value}', color: AppTheme.accentAmber),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Remove Ads Card (In-App Purchase)
                Obx(() {
                  final isRemoved = monetization.isRemoveAdsPurchased.value;
                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isRemoved
                            ? [const Color(0xFF1B5E20), const Color(0xFF2E7D32)]
                            : [const Color(0xFF4A148C), const Color(0xFF6A1B9A)],
                      ),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isRemoved ? Icons.check_circle_rounded : Icons.block_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isRemoved ? 'Ad-Free VIP Active' : 'Remove Ads Forever',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              Text(
                                isRemoved ? 'Enjoy 100% uninterrupted jigsaw solving!' : 'No banner or interstitial ads',
                                style: const TextStyle(color: Colors.white70, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                        if (!isRemoved)
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.accentAmber,
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () {
                              monetization.isRemoveAdsPurchased.value = true;
                              storage.setRemoveAds(true);
                              Get.snackbar('Ad-Free Activated!', 'All advertisements removed!',
                                  backgroundColor: const Color(0xDD000000), colorText: Colors.white);
                            },
                            child: const Text('Remove', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 18),

                // Free Hints Reward Center
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E2838),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppTheme.accentAmber.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.lightbulb_rounded, color: AppTheme.accentAmber, size: 20),
                          const SizedBox(width: 8),
                          Obx(() => Text(
                                'Free Hints Balance: ${settings.freeHints.value}',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                              )),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: const BorderSide(color: AppTheme.accentAmber),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              icon: const Icon(Icons.video_library_rounded, size: 16, color: AppTheme.accentAmber),
                              label: const Text('+1 Free Hint', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                              onPressed: () {
                                monetization.showRewardedAd(
                                  onRewardEarned: () {
                                    settings.addFreeHint(1);
                                    Get.snackbar('Reward Earned!', '+1 Free Hint added!',
                                        backgroundColor: const Color(0xDD000000), colorText: Colors.white);
                                  },
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: const BorderSide(color: Colors.white24),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              icon: const Icon(Icons.monetization_on, size: 16, color: AppTheme.accentAmber),
                              label: const Text('+30 Coins', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                              onPressed: () {
                                monetization.showRewardedAd(
                                  onRewardEarned: () {
                                    economy.addCoins(30);
                                    Get.snackbar('Coins Earned!', '+30 Coins added!',
                                        backgroundColor: const Color(0xDD000000), colorText: Colors.white);
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Game Audio & Screen Settings
                const Text('Game Settings', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E2838),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Column(
                    children: [
                      Obx(() => SwitchListTile(
                            title: const Text('Sound Effects (Snap & Win)', style: TextStyle(color: Colors.white, fontSize: 13)),
                            secondary: const Icon(Icons.volume_up_rounded, color: AppTheme.accentAmber, size: 20),
                            value: settings.soundEnabled.value,
                            activeThumbColor: AppTheme.accentAmber,
                            onChanged: (_) => settings.toggleSound(),
                          )),
                      const Divider(height: 1, color: Colors.white12),
                      Obx(() => SwitchListTile(
                            title: const Text('Background Music', style: TextStyle(color: Colors.white, fontSize: 13)),
                            secondary: const Icon(Icons.music_note_rounded, color: AppTheme.accentAmber, size: 20),
                            value: settings.musicEnabled.value,
                            activeThumbColor: AppTheme.accentAmber,
                            onChanged: (_) => settings.toggleMusic(),
                          )),
                      const Divider(height: 1, color: Colors.white12),
                      Obx(() => SwitchListTile(
                            title: const Text('Haptic Vibration', style: TextStyle(color: Colors.white, fontSize: 13)),
                            secondary: const Icon(Icons.vibration_rounded, color: AppTheme.accentAmber, size: 20),
                            value: settings.vibrationEnabled.value,
                            activeThumbColor: AppTheme.accentAmber,
                            onChanged: (_) => settings.toggleVibration(),
                          )),
                      const Divider(height: 1, color: Colors.white12),
                      Obx(() => SwitchListTile(
                            title: const Text('Keep Screen Awake (Auto-Lock)', style: TextStyle(color: Colors.white, fontSize: 13)),
                            secondary: const Icon(Icons.screen_lock_portrait_rounded, color: AppTheme.accentAmber, size: 20),
                            value: settings.keepScreenAwake.value,
                            activeThumbColor: AppTheme.accentAmber,
                            onChanged: (_) => settings.toggleKeepScreenAwake(),
                          )),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Board Theme Selector
                const Text('Puzzle Board Theme', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 8),
                Obx(() {
                  final currentBg = settings.boardBackground.value;
                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: BoardBackgroundStyle.values.map((style) {
                      final isSelected = style == currentBg;
                      return ChoiceChip(
                        label: Text(style.label),
                        selected: isSelected,
                        selectedColor: AppTheme.accentAmber,
                        backgroundColor: const Color(0xFF1E2838),
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.black : Colors.white70,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 12,
                        ),
                        onSelected: (val) {
                          if (val) settings.setBoardBackground(style);
                        },
                      );
                    }).toList(),
                  );
                }),
                const SizedBox(height: 20),

                // Achievements Section
                const Text('Achievements', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 8),
                _buildAchievementTile('First Victory', 'Solve your first jigsaw puzzle', completedCount >= 1),
                _buildAchievementTile('Saga Explorer', 'Reach Level 5 in Campaign', highest >= 5),
                _buildAchievementTile('Puzzle Pro', 'Reach Level 10 in Campaign', highest >= 10),
                _buildAchievementTile('Star Master', 'Collect at least 15 stars', totalStars >= 15),
                _buildAchievementTile('Saga Champion', 'Clear all 25 levels', highest >= 25),
                const SizedBox(height: 20),

                // Privacy Policy & About Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white70,
                          side: const BorderSide(color: Colors.white24),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        icon: const Icon(Icons.privacy_tip_outlined, size: 16),
                        label: const Text('Privacy Policy', style: TextStyle(fontSize: 12)),
                        onPressed: () => _showPrivacyPolicy(context),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white70,
                          side: const BorderSide(color: Colors.white24),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        icon: const Icon(Icons.info_outline, size: 16),
                        label: const Text('About Game', style: TextStyle(fontSize: 12)),
                        onPressed: () => _showAboutGame(context),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildStatBadge(IconData icon, String label, String value, {Color? color}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: color ?? Colors.white70),
        const SizedBox(height: 3),
        Text(value, style: TextStyle(color: color ?? Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10)),
      ],
    );
  }

  Widget _buildAchievementTile(String title, String desc, bool unlocked) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: unlocked ? const Color(0xFF1B3828) : const Color(0xFF1E2838),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: unlocked ? Colors.green.withValues(alpha: 0.4) : Colors.white12),
      ),
      child: Row(
        children: [
          Icon(
            unlocked ? Icons.emoji_events_rounded : Icons.lock_outline_rounded,
            color: unlocked ? const Color(0xFFFFD700) : Colors.white38,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: unlocked ? Colors.white : Colors.white60, fontWeight: FontWeight.bold, fontSize: 12)),
                Text(desc, style: const TextStyle(color: Colors.white54, fontSize: 10)),
              ],
            ),
          ),
          if (unlocked)
            const Icon(Icons.check_circle_rounded, color: Color(0xFF66BB6A), size: 18),
        ],
      ),
    );
  }

  void _showPrivacyPolicy(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E2838),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text('Privacy Policy', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17)),
        content: const SingleChildScrollView(
          child: Text(
            'Jigsaw Puzzle: Offline Game respects player privacy:\n\n'
            '• Fully Playable Offline: All puzzle pictures, progress, and star ratings are stored 100% locally on your device.\n'
            '• Zero Personal Data Collection: We do not collect or sell your personal identifiable information.\n'
            '• Google AdMob: When connected to the internet, non-personalized advertisements may be served per Google AdMob compliance policies.\n'
            '• In-App Purchases: Purchases for Remove Ads and coin packs are processed securely via Google Play / Apple App Store.',
            style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close', style: TextStyle(color: AppTheme.accentAmber))),
        ],
      ),
    );
  }

  void _showAboutGame(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E2838),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text('About Jigsaw Puzzle', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17)),
        content: const SingleChildScrollView(
          child: Text(
            'Jigsaw Puzzle: Offline Game\nVersion 1.0.0\n\n'
            'A relaxing, beautiful jigsaw puzzle game designed for puzzle lovers of all ages.\n\n'
            'Features:\n'
            '• 25 Progressive Saga Levels\n'
            '• Real Precision Cut tabs & blanks\n'
            '• 3 Free Hints + Rewarded Video hints\n'
            '• Auto-save progression & offline support\n'
            '• Multiple tabletop board themes',
            style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close', style: TextStyle(color: AppTheme.accentAmber))),
        ],
      ),
    );
  }
}
