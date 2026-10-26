import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:jigsaw_pro/core/audio/audio_service.dart';
import 'package:jigsaw_pro/core/storage/hive_storage.dart';
import 'package:jigsaw_pro/core/theme/app_theme.dart';
import 'package:jigsaw_pro/core/widgets/app_bottom_nav_bar.dart';
import 'package:jigsaw_pro/core/widgets/casual_game_background.dart';
import 'package:jigsaw_pro/core/widgets/clay_container.dart';
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Get.isRegistered<AudioService>()) {
        Get.find<AudioService>().startBgm();
      }
      final storage = Get.find<HiveStorage>();
      if (!storage.hasConsentedToPrivacy && mounted) {
        _showConsentDialog(context, storage);
      }
    });
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

    return ValueListenableBuilder(
      valueListenable: storage.progressBoxListenable,
      builder: (context, _, __) {
        return ValueListenableBuilder(
          valueListenable: storage.sessionBoxListenable,
          builder: (context, _, __) {
            return Obx(() {
              final activeSession = storage.getActiveSession();
              final highestSaga = storage.getHighestSagaLevel();

              return Scaffold(
                backgroundColor: Colors.transparent,
                bottomNavigationBar: const AppBottomNavBar(currentTab: AppTab.home),
                body: CasualGameBackground(
                  child: SafeArea(
                    child: _buildHeroHomeView(
                      context,
                      storage,
                      content,
                      economy,
                      settings,
                      monetization,
                      activeSession,
                      highestSaga,
                    ),
                  ),
                ),
              );
            });
          },
        );
      },
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
    final lockedInSession = (activeSession?['lockedPieceKeys'] as List?)?.length ?? 0;
    final totalInSession = (activeSession?['pieceCount'] ?? activeSession?['actualPieceCount']) as int? ?? 1;
    final isContinue = activeSession != null && lockedInSession > 0 && lockedInSession < totalInSession;

    final heroImagePath = _getHeroImagePath(activeSession, content, highestSaga, isContinue);
    final heroTitle = _getHeroTitle(activeSession, content, highestSaga, isContinue);
    final heroPieces = _getHeroPieces(activeSession, content, highestSaga, isContinue);
    final heroProgress = _getHeroProgress(activeSession, isContinue);
    final heroProgressPercent = '${(heroProgress * 100).toInt()}%';

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

          // Daily Puzzle Card (+20 coins today / in progress / completed)
          _buildDailyPuzzleCard(context, content, storage),

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

        // Streak Pill (opens Daily Calendar)
        GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            context.push('/daily');
          },
          child: Container(
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
                  '${storage.streak > 0 ? storage.streak : 1} days',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13),
                ),
              ],
            ),
          ),
        ),

        // Profile & Settings Action Buttons (Top Right)
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Profile Circular Button (opens Game Hub Modal)
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
                child: const Icon(Icons.person_rounded, color: Colors.white, size: 20),
              ),
            ),
            const SizedBox(width: 8),

            // Settings Circular Button
            InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                context.push('/settings');
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
                child: const Icon(Icons.settings_rounded, color: Colors.white, size: 20),
              ),
            ),
          ],
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

  // --- Hero Puzzle Featured Card (Claymorphic 3D Card) ---
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF132238) : Colors.white;
    final cardBevel = isDark ? const Color(0xFF091322) : const Color(0xFFCBD5E1);
    final titleColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final subtitleColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return GestureDetector(
      onTap: () => _onPlayHeroPressed(context, activeSession, content, highestSaga),
      child: ClayContainer(
        color: cardBg,
        depth: 6.0,
        bevelColor: cardBevel,
        borderRadius: BorderRadius.circular(28),
        padding: const EdgeInsets.all(12),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.12) : Colors.white.withValues(alpha: 0.90),
          width: 1.2,
        ),
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
                      style: TextStyle(
                        color: titleColor,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$pieceCount pieces',
                      style: TextStyle(
                        color: subtitleColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                Text(
                  progressPercent,
                  style: TextStyle(
                    color: titleColor,
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
                backgroundColor: isDark ? const Color(0xFF243B55) : const Color(0xFFE2E8F0),
                valueColor: const AlwaysStoppedAnimation(Color(0xFF00E676)),
              ),
            ),
            const SizedBox(height: 2),
          ],
        ),
      ),
    );
  }

  // --- Big 3D Tactile Claymorphic PLAY Button ---
  Widget _buildBigPlayButton({required VoidCallback onPressed}) {
    return ClayButton(
      onTap: onPressed,
      width: 240,
      height: 56,
      depth: 5.5,
      color: const Color(0xFFFFB300),
      bevelColor: const Color(0xFFD87C00),
      borderRadius: BorderRadius.circular(28),
      gradient: const LinearGradient(
        colors: [
          Color(0xFFFFD54F),
          Color(0xFFFFB300),
          Color(0xFFFFA000),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
      child: const Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.play_arrow_rounded, color: Color(0xFF3E2723), size: 30),
            SizedBox(width: 6),
            Text(
              'PLAY',
              style: TextStyle(
                color: Color(0xFF3E2723),
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.8,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Daily Puzzle Card (Claymorphic) ---
  Widget _buildDailyPuzzleCard(BuildContext context, ContentController content, HiveStorage storage) {
    return Obx(() {
      final dailyPic = content.dailyPicture.value;
      final dailyImg = dailyPic?.path ?? 'assets/puzzles/animals/a001.jpg';
      final isCompletedToday = storage.isDailyDateCompleted(DateTime.now());

      final activeSession = storage.getActiveSession();
      final isDailySession = activeSession != null &&
          (activeSession['isDaily'] == true ||
           (dailyPic != null && activeSession['pictureId'] == dailyPic.id));

      final totalPieces = isDailySession
          ? ((activeSession['pieceCount'] ?? activeSession['actualPieceCount']) as int? ?? 48)
          : 48;
      final placedPieces = isDailySession
          ? ((activeSession['lockedPieceKeys'] as List?)?.length ?? 0)
          : 0;
      final remainingPieces = totalPieces - placedPieces;
      final progressFraction = totalPieces > 0 ? (placedPieces / totalPieces).clamp(0.0, 1.0) : 0.0;

      return ClayContainer(
        color: const Color(0xFF132238),
        depth: 4.5,
        bevelColor: const Color(0xFF091322),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isCompletedToday
              ? const Color(0xFF00E676).withValues(alpha: 0.35)
              : Colors.white.withValues(alpha: 0.15),
          width: 1.2,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                // Daily Real Image Thumbnail with Checkmark if completed
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    children: [
                      Image.asset(
                        dailyImg,
                        width: 52,
                        height: 52,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 52,
                          height: 52,
                          color: AppTheme.accentAmber,
                          child: const Icon(Icons.extension_rounded, color: Colors.white, size: 28),
                        ),
                      ),
                      if (isCompletedToday)
                        Container(
                          width: 52,
                          height: 52,
                          color: Colors.black.withValues(alpha: 0.40),
                          child: const Center(
                            child: Icon(Icons.check_circle_rounded, color: Color(0xFF00E676), size: 28),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),

                // Daily Text & Coin Bonus / In-Progress Stats
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Daily Puzzle',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15),
                          ),
                          if (isCompletedToday) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1B5E20),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'SOLVED',
                                style: TextStyle(color: Color(0xFF00E676), fontSize: 9.5, fontWeight: FontWeight.w900),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      if (isCompletedToday)
                        Row(
                          children: const [
                            Icon(Icons.check_circle_outline_rounded, color: Color(0xFF00E676), size: 14),
                            SizedBox(width: 4),
                            Text(
                              'Completed Today! +20 Coins Claimed',
                              style: TextStyle(color: Color(0xFF00E676), fontWeight: FontWeight.bold, fontSize: 11.5),
                            ),
                          ],
                        )
                      else if (isDailySession && placedPieces > 0)
                        Text(
                          '$placedPieces placed • $remainingPieces left (${(progressFraction * 100).toInt()}%)',
                          style: const TextStyle(color: Color(0xFFFFD54F), fontWeight: FontWeight.bold, fontSize: 12),
                        )
                      else
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
                const SizedBox(width: 8),

                // Action Button (Play / Continue / Done)
                if (isCompletedToday)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1B5E20),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF00E676)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_rounded, color: Color(0xFF00E676), size: 16),
                        SizedBox(width: 4),
                        Text(
                          'Done',
                          style: TextStyle(color: Color(0xFF00E676), fontWeight: FontWeight.w900, fontSize: 12.5),
                        ),
                      ],
                    ),
                  )
                else
                  InkWell(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      final picId = dailyPic?.id ?? 'n001';
                      if (isDailySession) {
                        context.push('/puzzle?id=$picId&pieces=$totalPieces&daily=true&resume=true');
                      } else {
                        context.push('/difficulty/$picId?defaultCount=48&daily=true');
                      }
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                      decoration: BoxDecoration(
                        gradient: isDailySession
                            ? const LinearGradient(colors: [Color(0xFFFFCA28), Color(0xFFFFA000)])
                            : const LinearGradient(colors: [Color(0xFF00E676), Color(0xFF00C853)]),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: isDailySession
                                ? const Color(0xFFFF8F00).withValues(alpha: 0.35)
                                : const Color(0xFF00E676).withValues(alpha: 0.35),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        isDailySession ? 'Continue' : 'Play',
                        style: TextStyle(
                          color: isDailySession ? const Color(0xFF3E2723) : const Color(0xFF053E1B),
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            if (isDailySession && placedPieces > 0 && !isCompletedToday) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progressFraction,
                  minHeight: 5,
                  backgroundColor: Colors.white12,
                  valueColor: const AlwaysStoppedAnimation(Color(0xFFFFB300)),
                ),
              ),
            ],
          ],
        ),
      );
    });
  }

  // --- Collections Section (WITH REAL ASSET IMAGES) ---
  Widget _buildCollectionsSection(BuildContext context, ContentController content) {
    final categoriesData = [
      {'id': 'nature', 'name': 'Nature', 'fallback': 'assets/puzzles/nature/n001.jpg'},
      {'id': 'animals', 'name': 'Animals', 'fallback': 'assets/puzzles/animals/a001.jpg'},
      {'id': 'flowers', 'name': 'Flowers', 'fallback': 'assets/puzzles/flowers/f001.jpg'},
      {'id': 'landmarks', 'name': 'Landmarks', 'fallback': 'assets/puzzles/landmarks/l001.jpg'},
      {'id': 'art', 'name': 'Art', 'fallback': 'assets/puzzles/art/art001.jpg'},
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

  String _getHeroImagePath(Map<String, dynamic>? activeSession, ContentController content, int highestSaga, bool isContinue) {
    if (isContinue && activeSession != null && activeSession['picturePath'] != null) {
      return activeSession['picturePath'] as String;
    }
    final currentLevel = content.sagaLevels.firstWhereOrNull((l) => l.levelNumber == highestSaga);
    if (currentLevel != null && currentLevel.imagePath.isNotEmpty) {
      return currentLevel.imagePath;
    }
    if (content.allPictures.isNotEmpty) {
      final index = (highestSaga - 1) % content.allPictures.length;
      return content.allPictures[index].path;
    }
    return 'assets/puzzles/nature/n001.jpg';
  }

  String _getHeroTitle(Map<String, dynamic>? activeSession, ContentController content, int highestSaga, bool isContinue) {
    if (isContinue && activeSession != null && activeSession['pictureTitle'] != null) {
      return activeSession['pictureTitle'] as String;
    }
    final currentLevel = content.sagaLevels.firstWhereOrNull((l) => l.levelNumber == highestSaga);
    if (currentLevel != null && currentLevel.title.isNotEmpty) {
      return currentLevel.title;
    }
    if (content.allPictures.isNotEmpty) {
      final index = (highestSaga - 1) % content.allPictures.length;
      return content.allPictures[index].title;
    }
    return 'Level $highestSaga';
  }

  int _getHeroPieces(Map<String, dynamic>? activeSession, ContentController content, int highestSaga, bool isContinue) {
    if (isContinue && activeSession != null && (activeSession['actualPieceCount'] != null || activeSession['pieceCount'] != null)) {
      return (activeSession['actualPieceCount'] ?? activeSession['pieceCount']) as int;
    }
    final currentLevel = content.sagaLevels.firstWhereOrNull((l) => l.levelNumber == highestSaga);
    if (currentLevel != null) {
      return currentLevel.pieceCount;
    }
    return PuzzleLevel.compute25LevelPieceCount(highestSaga);
  }

  double _getHeroProgress(Map<String, dynamic>? activeSession, bool isContinue) {
    if (isContinue && activeSession != null) {
      final pieces = (activeSession['pieceCount'] ?? activeSession['actualPieceCount']) as int? ?? 100;
      final locked = (activeSession['lockedPieceKeys'] as List?)?.length ?? 0;
      if (pieces > 0) {
        return (locked / pieces).clamp(0.0, 1.0);
      }
    }
    return 0.0;
  }

  void _onPlayHeroPressed(
    BuildContext context,
    Map<String, dynamic>? activeSession,
    ContentController content,
    int highestSaga,
  ) {
    HapticFeedback.lightImpact();
    final locked = (activeSession?['lockedPieceKeys'] as List?)?.length ?? 0;
    final total = (activeSession?['pieceCount'] ?? activeSession?['actualPieceCount']) as int? ?? 48;
    final isContinue = activeSession != null && locked > 0 && locked < total;

    if (isContinue && activeSession?['pictureId'] != null) {
      final picId = activeSession!['pictureId'] as String;
      final saga = activeSession['sagaLevel'] as int?;
      context.push('/puzzle?id=$picId&pieces=$total${saga != null ? "&sagaLevel=$saga" : ""}&resume=true');
      return;
    }

    // Always start clean fresh puzzle with all pieces in bottom card
    final currentLevel = content.sagaLevels.firstWhereOrNull((l) => l.levelNumber == highestSaga);
    if (currentLevel != null) {
      _startLevel(context, currentLevel);
    } else {
      String fallbackId = 'n001';
      if (content.allPictures.isNotEmpty) {
        final index = (highestSaga - 1) % content.allPictures.length;
        fallbackId = content.allPictures[index].id;
      }
      final pcs = PuzzleLevel.compute25LevelPieceCount(highestSaga);
      context.push('/puzzle?id=$fallbackId&pieces=$pcs&sagaLevel=$highestSaga');
    }
  }

  // --- Start Level ---
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
                                  context: context,
                                  rewardTitle: '+1 Free Hint',
                                  onRewardEarned: () {
                                    settings.addFreeHint(1);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: const Text('+1 Free Hint added to balance!'),
                                        backgroundColor: const Color(0xEE112238),
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                      ),
                                    );
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
                                  context: context,
                                  rewardTitle: '+30 Coins',
                                  onRewardEarned: () {
                                    economy.addCoins(30);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: const Text('+30 Coins added to your stash!'),
                                        backgroundColor: const Color(0xEE112238),
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                      ),
                                    );
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

  void _showConsentDialog(BuildContext context, HiveStorage storage) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return PopScope(
          canPop: false,
          child: Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x350D2544),
                    blurRadius: 24,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 66,
                    height: 66,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF42A5F5), Color(0xFF1976D2)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1976D2).withValues(alpha: 0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(Icons.security_rounded, size: 36, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 14),

                  const Text(
                    'Privacy & Data Consent',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF0E2A47),
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),

                  const Text(
                    'We value your privacy! This game runs offline and stores your progress locally on your device.\n\n'
                    'Google AdMob may use device identifiers to provide rewarded ads for free hints and coins.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFF546E7A), fontSize: 13, height: 1.4),
                  ),
                  const SizedBox(height: 22),

                  // Agree & Continue Button
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      storage.setPrivacyConsent(true);
                      Navigator.pop(ctx);
                    },
                    child: Container(
                      width: double.infinity,
                      height: 52,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(26),
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
                            offset: const Offset(0, 4),
                            blurRadius: 0,
                          ),
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.20),
                            offset: const Offset(0, 6),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          'AGREE & CONTINUE',
                          style: TextStyle(
                            color: Color(0xFF3E2723),
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Privacy details button
                  TextButton(
                    onPressed: () {
                      _showPrivacyPolicy(ctx);
                    },
                    child: const Text('View Privacy Policy', style: TextStyle(color: Color(0xFF78909C), fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
