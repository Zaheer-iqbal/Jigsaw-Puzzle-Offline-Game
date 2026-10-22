import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:jigsaw_pro/core/config/app_config.dart';
import 'package:jigsaw_pro/core/utils/responsive.dart';
import 'package:jigsaw_pro/core/widgets/casual_game_background.dart';
import 'package:jigsaw_pro/features/puzzle/presentation/controllers/puzzle_controller.dart';

class WinPage extends StatelessWidget {
  const WinPage({super.key});

  @override
  Widget build(BuildContext context) {
    final puzzle = Get.find<PuzzleController>();

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
          child: Responsive(
            portrait: (context, constraints) => _buildPortrait(context, puzzle, time, moves, coinsEarned),
            landscape: (context, constraints) => _buildLandscape(context, puzzle, time, moves, coinsEarned),
          ),
        ),
      ),
    );
  }

  Widget _buildPortrait(
    BuildContext context,
    PuzzleController puzzle,
    String time,
    int moves,
    int coinsEarned,
  ) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildBadge(),
            const SizedBox(height: 18),
            Text(
              puzzle.pictureTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w900,
                shadows: [
                  Shadow(color: Color(0xFF0D2544), offset: Offset(0, 3), blurRadius: 0),
                ],
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              '🎉 Puzzle Completed! 🎉',
              style: TextStyle(
                color: Color(0xFFFFD54F),
                fontSize: 18,
                fontWeight: FontWeight.w900,
                shadows: [
                  Shadow(color: Color(0x664E342E), offset: Offset(0, 2), blurRadius: 0),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildStatsCard(time, moves, coinsEarned),
            const SizedBox(height: 28),
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildLandscape(
    BuildContext context,
    PuzzleController puzzle,
    String time,
    int moves,
    int coinsEarned,
  ) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              flex: 4,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildBadge(),
                  const SizedBox(height: 12),
                  Text(
                    puzzle.pictureTitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      shadows: [
                        Shadow(color: Color(0xFF0D2544), offset: Offset(0, 3), blurRadius: 0),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 32),
            Expanded(
              flex: 6,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildStatsCard(time, moves, coinsEarned),
                  const SizedBox(height: 20),
                  _buildActionButtons(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge() {
    return Container(
      width: 110,
      height: 110,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [Color(0xFFFFD54F), Color(0xFFFF8F00)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x40000000),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: const Icon(Icons.emoji_events_rounded, size: 68, color: Colors.white),
    );
  }

  Widget _buildStatsCard(String time, int moves, int coinsEarned) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x300D2544),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(Icons.timer_rounded, 'Time', time, const Color(0xFF0288D1)),
          Container(width: 1, height: 44, color: const Color(0xFFCFD8DC)),
          _buildStatItem(Icons.touch_app_rounded, 'Moves', '$moves', const Color(0xFF7E57C2)),
          Container(width: 1, height: 44, color: const Color(0xFFCFD8DC)),
          _buildStatItem(Icons.monetization_on_rounded, 'Coins', '+$coinsEarned', const Color(0xFFFF8F00)),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 26),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: Color(0xFF78909C), fontSize: 12, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFB300),
              foregroundColor: const Color(0xFF0E2A47),
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            ),
            onPressed: () {
              context.go('/gallery');
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.skip_next_rounded, size: 28),
                SizedBox(width: 6),
                Text('Next Puzzle', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF16355C),
              foregroundColor: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            ),
            onPressed: () {
              context.go('/home');
            },
            child: const Text('Back to Home', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
          ),
        ),
      ],
    );
  }

  String _formatTime(int totalSeconds) {
    final m = totalSeconds ~/ 60;
    final s = totalSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}
