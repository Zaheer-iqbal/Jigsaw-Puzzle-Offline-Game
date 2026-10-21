import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:jigsaw_pro/core/config/app_config.dart';
import 'package:jigsaw_pro/core/theme/app_theme.dart';
import 'package:jigsaw_pro/core/utils/responsive.dart';
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
      backgroundColor: const Color(0xFF14171A),
      body: SafeArea(
        child: Responsive(
          portrait: (context, constraints) => _buildPortrait(context, puzzle, time, moves, coinsEarned),
          landscape: (context, constraints) => _buildLandscape(context, puzzle, time, moves, coinsEarned),
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
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildBadge(),
            const SizedBox(height: 20),
            Text(
              puzzle.pictureTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Puzzle Completed!',
              style: TextStyle(color: AppTheme.accentAmber, fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 28),
            _buildStatsCard(time, moves, coinsEarned),
            const SizedBox(height: 36),
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
                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
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
                  const SizedBox(height: 24),
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
          colors: [AppTheme.accentAmber, Color(0xFFFF6F00)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.accentAmber.withValues(alpha: 0.4),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const Icon(Icons.emoji_events, size: 64, color: Colors.white),
    );
  }

  Widget _buildStatsCard(String time, int moves, int coinsEarned) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2429),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(Icons.timer_outlined, 'Time', time),
          Container(width: 1, height: 40, color: Colors.white12),
          _buildStatItem(Icons.touch_app_outlined, 'Moves', '$moves'),
          Container(width: 1, height: 40, color: Colors.white12),
          _buildStatItem(Icons.monetization_on, 'Coins', '+$coinsEarned', color: AppTheme.accentAmber),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value, {Color? color}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color ?? Colors.white70, size: 24),
        const SizedBox(height: 6),
        Text(value, style: TextStyle(color: color ?? Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentAmber,
              foregroundColor: Colors.black,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: () {
              context.go('/gallery');
            },
            child: const Text('Next Puzzle', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
              side: const BorderSide(color: Colors.white24),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: () {
              context.go('/home');
            },
            child: const Text('Back to Home', style: TextStyle(fontSize: 16)),
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
