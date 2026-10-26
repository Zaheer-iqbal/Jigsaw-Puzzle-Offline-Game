import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:jigsaw_pro/core/config/app_config.dart';
import 'package:jigsaw_pro/core/utils/responsive.dart';
import 'package:jigsaw_pro/core/widgets/casual_game_background.dart';
import 'package:jigsaw_pro/core/widgets/clay_container.dart';
import 'package:jigsaw_pro/features/content/presentation/controllers/content_controller.dart';
import 'package:jigsaw_pro/features/economy/presentation/controllers/economy_controller.dart';
import 'package:jigsaw_pro/features/puzzle/presentation/controllers/puzzle_controller.dart';

class WinPage extends StatelessWidget {
  const WinPage({super.key});

  @override
  Widget build(BuildContext context) {
    final puzzle = Get.find<PuzzleController>();
    final economy = Get.find<EconomyController>();

    final time = _formatTime(puzzle.elapsedSeconds.value);
    final moves = puzzle.moves.value;
    final pieces = puzzle.actualPieceCount;

    int coinsEarned;
    if (pieces <= 24) {
      coinsEarned = AppConfig.coinsFinish12or24;
    } else if (pieces <= 100) {
      coinsEarned = AppConfig.coinsFinish48or100;
    } else if (pieces <= 200) {
      coinsEarned = AppConfig.coinsFinish200;
    } else {
      coinsEarned = AppConfig.coinsFinish400;
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CasualGameBackground(
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 8),
              _buildTopBar(context, economy),
              const SizedBox(height: 8),
              Expanded(
                child: Responsive(
                  portrait: (context, constraints) => _buildPortrait(context, puzzle, time, moves, coinsEarned),
                  landscape: (context, constraints) => _buildLandscape(context, puzzle, time, moves, coinsEarned),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Top Navigation & Coins Header ---
  Widget _buildTopBar(BuildContext context, EconomyController economy) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Circular Home Button
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              context.go('/home');
            },
            child: Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: Color(0xFF16355C),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: Color(0x33000000), blurRadius: 6, offset: Offset(0, 3)),
                ],
              ),
              child: const Center(
                child: Icon(Icons.home_rounded, color: Colors.white, size: 22),
              ),
            ),
          ),

          // Title
          const Text(
            'Victory!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.6,
              shadows: [
                Shadow(color: Color(0xFF0D2544), offset: Offset(0, 3), blurRadius: 0),
              ],
            ),
          ),

          // Coins Counter Pill
          Obx(() => Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: const Color(0xFF16355C),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(color: Color(0x33000000), blurRadius: 6, offset: Offset(0, 3)),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🪙', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 6),
                    Text(
                      '${economy.coins.value}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  // --- Portrait Layout ---
  Widget _buildPortrait(
    BuildContext context,
    PuzzleController puzzle,
    String time,
    int moves,
    int coinsEarned,
  ) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        children: [
          // White Celebration Card (Claymorphic)
          ClayContainer(
            color: Colors.white,
            depth: 7.0,
            bevelColor: const Color(0xFFCBD5E1),
            borderRadius: BorderRadius.circular(30),
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.90),
              width: 1.2,
            ),
            child: Column(
              children: [
                // Golden Stars Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildStar(size: 32, angle: -0.15),
                    const SizedBox(width: 6),
                    _buildStar(size: 42, isCenter: true),
                    const SizedBox(width: 6),
                    _buildStar(size: 32, angle: 0.15),
                  ],
                ),
                const SizedBox(height: 12),

                // Floating Trophy Badge
                _buildTrophyBadge(),
                const SizedBox(height: 14),

                // Celebration Title
                const Text(
                  'PUZZLE COMPLETED!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF0E2A47),
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),

                // Puzzle Title / Level Subtitle
                Text(
                  _cleanTitle(puzzle),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF607D8B),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),

                // Solved Picture Thumbnail with Solved Checkmark
                _buildPictureThumbnail(puzzle),
                const SizedBox(height: 18),

                // 3-Column Stats Row
                _buildStatsCard(time, moves, coinsEarned),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Action Buttons
          _buildActionButtons(context, puzzle),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // --- Landscape Layout ---
  Widget _buildLandscape(
    BuildContext context,
    PuzzleController puzzle,
    String time,
    int moves,
    int coinsEarned,
  ) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: ClayContainer(
        color: Colors.white,
        depth: 7.0,
        bevelColor: const Color(0xFFCBD5E1),
        borderRadius: BorderRadius.circular(30),
        padding: const EdgeInsets.all(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.90),
          width: 1.2,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Left Column: Picture Thumbnail & Trophy
            Expanded(
              flex: 5,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildTrophyBadge(size: 64, iconSize: 36),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'PUZZLE COMPLETED!',
                              style: TextStyle(
                                color: Color(0xFF0E2A47),
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text(
                              _cleanTitle(puzzle),
                              style: const TextStyle(
                                color: Color(0xFF607D8B),
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 140,
                    child: _buildPictureThumbnail(puzzle),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 24),

            // Right Column: Stats & Action Buttons
            Expanded(
              flex: 6,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildStatsCard(time, moves, coinsEarned),
                  const SizedBox(height: 16),
                  _buildActionButtons(context, puzzle),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStar({required double size, double angle = 0, bool isCenter = false}) {
    return Transform.rotate(
      angle: angle,
      child: Icon(
        Icons.star_rounded,
        size: size,
        color: const Color(0xFFFFB300),
        shadows: const [
          Shadow(
            color: Color(0x55FFA000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
    );
  }

  Widget _buildTrophyBadge({double size = 80, double iconSize = 48}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [
            Color(0xFFFFE082),
            Color(0xFFFFB300),
            Color(0xFFFF8F00),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF8F00).withValues(alpha: 0.45),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Center(
        child: Icon(Icons.emoji_events_rounded, size: iconSize, color: Colors.white),
      ),
    );
  }

  Widget _buildPictureThumbnail(PuzzleController puzzle) {
    return Container(
      width: double.infinity,
      height: 170,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x180D2544),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Solved Picture
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                puzzle.picturePath,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: const Color(0xFFE2E8F0),
                  child: const Center(
                    child: Icon(Icons.image_rounded, size: 48, color: Color(0xFF90A4AE)),
                  ),
                ),
              ),
            ),
          ),

          // Green 'SOLVED' Checkmark Pill Badge
          Positioned(
            bottom: 10,
            right: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF00E676),
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x33000000),
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_rounded, color: Colors.white, size: 16),
                  SizedBox(width: 4),
                  Text(
                    'SOLVED',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.6,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- 3-Column Stats Row ---
  Widget _buildStatsCard(String time, int moves, int coinsEarned) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('⏱️', 'Time', time, const Color(0xFF0288D1)),
          Container(width: 1, height: 40, color: const Color(0xFFCBD5E1)),
          _buildStatItem('🎯', 'Moves', '$moves', const Color(0xFF7E57C2)),
          Container(width: 1, height: 40, color: const Color(0xFFCBD5E1)),
          _buildStatItem('🪙', 'Coins', '+$coinsEarned', const Color(0xFFFF8F00)),
        ],
      ),
    );
  }

  Widget _buildStatItem(String emoji, String label, String value, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 17,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            color: Color(0xFF64748B),
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.4,
          ),
        ),
      ],
    );
  }

  // --- Big 3D Tactile Golden NEXT PUZZLE & Home Buttons (Claymorphic) ---
  Widget _buildActionButtons(BuildContext context, PuzzleController puzzle) {
    return Column(
      children: [
        // Big 3D Tactile Golden NEXT PUZZLE ClayButton
        ClayButton(
          onTap: () => _handleNextPuzzle(context, puzzle),
          width: double.infinity,
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
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.play_arrow_rounded, color: Color(0xFF3E2723), size: 30),
                SizedBox(width: 6),
                Text(
                  'NEXT PUZZLE',
                  style: TextStyle(
                    color: Color(0xFF3E2723),
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Back to Home ClayButton
        ClayButton(
          onTap: () {
            HapticFeedback.lightImpact();
            context.go('/home');
          },
          width: double.infinity,
          height: 48,
          depth: 4.5,
          color: const Color(0xFF16355C),
          bevelColor: const Color(0xFF0C1D33),
          borderRadius: BorderRadius.circular(24),
          child: const Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.home_rounded, color: Colors.white, size: 20),
                SizedBox(width: 6),
                Text(
                  'BACK TO HOME',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _handleNextPuzzle(BuildContext context, PuzzleController puzzle) {
    HapticFeedback.mediumImpact();
    final content = Get.isRegistered<ContentController>() ? Get.find<ContentController>() : null;

    // 1. If played as a Saga Campaign Level, launch the next Saga level!
    if (puzzle.currentSagaLevel != null && content != null) {
      final nextSagaNum = puzzle.currentSagaLevel! + 1;
      final nextLevel = content.sagaLevels.firstWhereOrNull((l) => l.levelNumber == nextSagaNum);
      if (nextLevel != null) {
        context.pushReplacement(
          '/puzzle?id=${nextLevel.pictureId}&pieces=${nextLevel.pieceCount}&sagaLevel=${nextLevel.levelNumber}',
        );
        return;
      }
    }

    // 2. If it was a numbered level (e.g. n001 -> n002 or numeric 1 -> 2)
    final match = RegExp(r'^([a-zA-Z]+)(\d+)$').firstMatch(puzzle.pictureId);
    if (match != null && content != null) {
      final prefix = match.group(1)!;
      final currentNum = int.tryParse(match.group(2)!) ?? 1;
      final nextNum = currentNum + 1;
      final padDigits = match.group(2)!.length;
      final nextId = '$prefix${nextNum.toString().padLeft(padDigits, '0')}';

      final nextPic = content.allPictures.firstWhereOrNull(
        (p) => p.id == nextId || p.id == '$nextId.bpm' || p.id == '$nextId.png',
      );
      if (nextPic != null) {
        context.pushReplacement(
          '/puzzle?id=${nextPic.id}&pieces=${puzzle.actualPieceCount}',
        );
        return;
      }
    } else {
      final pureNum = int.tryParse(puzzle.pictureId);
      if (pureNum != null && content != null) {
        final nextNum = pureNum + 1;
        final nextPic = content.allPictures.firstWhereOrNull(
          (p) => p.id == '$nextNum' || p.id == nextNum.toString().padLeft(2, '0') || p.id == nextNum.toString().padLeft(3, '0'),
        );
        if (nextPic != null) {
          context.pushReplacement(
            '/puzzle?id=${nextPic.id}&pieces=${puzzle.actualPieceCount}',
          );
          return;
        }
      }
    }

    // 3. Fallback: Take next picture from allPictures
    if (content != null && content.allPictures.isNotEmpty) {
      final currentIndex = content.allPictures.indexWhere((p) => p.id == puzzle.pictureId);
      if (currentIndex >= 0 && currentIndex + 1 < content.allPictures.length) {
        final nextPic = content.allPictures[currentIndex + 1];
        context.pushReplacement(
          '/puzzle?id=${nextPic.id}&pieces=${puzzle.actualPieceCount}',
        );
        return;
      }
    }

    // 4. Default: Gallery page
    context.go('/gallery');
  }

  String _cleanTitle(PuzzleController puzzle) {
    if (puzzle.isDaily) return 'Daily Puzzle';
    if (puzzle.currentSagaLevel != null) return 'Level ${puzzle.currentSagaLevel}';

    var title = puzzle.pictureTitle;
    title = title.replaceAll(RegExp(r'\.(bpm|png|jpg|jpeg)$', caseSensitive: false), '').trim();
    if (RegExp(r'^[a-z]+[0-9]+$', caseSensitive: false).hasMatch(title)) {
      final numStr = title.replaceAll(RegExp(r'[^0-9]'), '').replaceFirst(RegExp(r'^0+'), '');
      return 'Level ${numStr.isEmpty ? "1" : numStr}';
    }
    return title.isNotEmpty ? title : 'Puzzle Completed';
  }

  String _formatTime(int totalSeconds) {
    final m = totalSeconds ~/ 60;
    final s = totalSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}
