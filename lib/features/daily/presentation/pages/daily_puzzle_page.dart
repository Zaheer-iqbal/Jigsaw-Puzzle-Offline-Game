import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:jigsaw_pro/core/storage/hive_storage.dart';
import 'package:jigsaw_pro/core/widgets/app_bottom_nav_bar.dart';
import 'package:jigsaw_pro/core/widgets/casual_game_background.dart';
import 'package:jigsaw_pro/features/content/domain/entities/puzzle_picture.dart';
import 'package:jigsaw_pro/features/content/presentation/controllers/content_controller.dart';
import 'package:jigsaw_pro/features/economy/presentation/controllers/economy_controller.dart';

class DailyPuzzlePage extends StatefulWidget {
  const DailyPuzzlePage({super.key});

  @override
  State<DailyPuzzlePage> createState() => _DailyPuzzlePageState();
}

class _DailyPuzzlePageState extends State<DailyPuzzlePage> {
  final HiveStorage _storage = Get.find<HiveStorage>();
  final ContentController _content = Get.find<ContentController>();
  final EconomyController _economy = Get.find<EconomyController>();

  late DateTime _today;

  @override
  void initState() {
    super.initState();
    _today = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      bottomNavigationBar: const AppBottomNavBar(currentTab: AppTab.daily),
      body: CasualGameBackground(
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 8),
              _buildTopBar(context),
              const SizedBox(height: 12),
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
                  children: [
                    // Streak Showcase Banner
                    _buildStreakCard(),
                    const SizedBox(height: 16),

                    // Today's Puzzle Challenge Card
                    _buildTodayPuzzleChallenge(),
                    const SizedBox(height: 20),

                    // Past Challenges List
                    _buildPastChallengesSection(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Top Navigation & Coins Bar ---
  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          // Circular Back Button
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/home');
              }
            },
            child: Container(
              width: 42,
              height: 42,
              decoration: const BoxDecoration(
                color: Color(0xFF16355C),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: Color(0x33000000), blurRadius: 6, offset: Offset(0, 3)),
                ],
              ),
              child: const Center(
                child: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // 3D Bubble Title (Flexible to eliminate any right overflow)
          const Expanded(
            child: Center(
              child: Text(
                'Daily Puzzle',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.6,
                  shadows: [
                    Shadow(color: Color(0xFF0D2544), offset: Offset(0, 3), blurRadius: 0),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Coins Capsule Pill
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              context.push('/shop');
            },
            child: Obx(() => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
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
                      const Text('🪙', style: TextStyle(fontSize: 15)),
                      const SizedBox(width: 5),
                      Text(
                        '${_economy.coins.value}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                )),
          ),
        ],
      ),
    );
  }

  // --- Streak Card ---
  Widget _buildStreakCard() {
    final streak = _storage.streak;
    final isTodayDone = _storage.isDailyDateCompleted(_today);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(color: Color(0x250D2544), blurRadius: 16, offset: Offset(0, 6)),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF9100), Color(0xFFFF3D00)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF3D00).withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text('🔥', style: TextStyle(fontSize: 26)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      streak > 0 ? '$streak-Day Streak!' : 'Start Your Streak!',
                      style: const TextStyle(
                        color: Color(0xFF0E2A47),
                        fontWeight: FontWeight.w900,
                        fontSize: 17,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isTodayDone
                          ? "Today's puzzle completed! Great job!"
                          : "Solve today's puzzle to maintain your streak!",
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Color(0xFF607D8B), fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 7-Day Dots Row (Sized to never overflow)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (index) {
              final weekStart = _today.subtract(Duration(days: _today.weekday - 1));
              final dayDate = weekStart.add(Duration(days: index));
              final isDone = _storage.isDailyDateCompleted(dayDate);
              final isDayToday = dayDate.day == _today.day && dayDate.month == _today.month;

              return Column(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDone
                          ? const Color(0xFF00E676)
                          : (isDayToday ? const Color(0xFFFFF8E1) : const Color(0xFFECEFF1)),
                      border: isDayToday
                          ? Border.all(color: const Color(0xFFFFB300), width: 2)
                          : null,
                      boxShadow: isDone
                          ? [
                              BoxShadow(
                                color: const Color(0xFF00E676).withValues(alpha: 0.35),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              )
                            ]
                          : null,
                    ),
                    child: Center(
                      child: isDone
                          ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
                          : Text(
                              '${dayDate.day}',
                              style: TextStyle(
                                color: isDayToday ? const Color(0xFFFF8F00) : const Color(0xFF78909C),
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _weekdayShort(index + 1),
                    style: TextStyle(
                      color: isDayToday ? const Color(0xFF0E2A47) : const Color(0xFF90A4AE),
                      fontSize: 9.5,
                      fontWeight: isDayToday ? FontWeight.w900 : FontWeight.w700,
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  // --- Past Daily Challenges (Recent Days) ---
  Widget _buildPastChallengesSection() {
    final pastDays = List.generate(5, (index) {
      return _today.subtract(Duration(days: index + 1));
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text(
              'Past Challenges',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                shadows: [
                  Shadow(color: Color(0xFF0D2544), offset: Offset(0, 2), blurRadius: 0),
                ],
              ),
            ),
            Flexible(
              child: Text(
                'Catch Up & Earn Coins',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Color(0xFFCFD8DC),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...pastDays.map((date) => _buildPastDayCard(date)),
      ],
    );
  }

  Widget _buildPastDayCard(DateTime date) {
    final pic = _getDailyPictureForDate(date);
    final isDone = _storage.isDailyDateCompleted(date);
    final isYesterday = date.day == _today.subtract(const Duration(days: 1)).day &&
        date.month == _today.subtract(const Duration(days: 1)).month;
    final dateLabel = isYesterday ? 'Yesterday' : DateFormat('EEEE, MMM d').format(date);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Color(0x200D2544), blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          // Thumbnail with checkmark overlay if done
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Stack(
              children: [
                Image.asset(
                  pic.path,
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 56,
                    height: 56,
                    color: const Color(0xFF90CAF9),
                    child: const Icon(Icons.image_rounded, color: Colors.white, size: 28),
                  ),
                ),
                if (isDone)
                  Container(
                    width: 56,
                    height: 56,
                    color: Colors.black.withValues(alpha: 0.35),
                    child: const Center(
                      child: Icon(Icons.check_circle_rounded, color: Color(0xFF00E676), size: 24),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // Day Info (Wrapped to prevent any right overflow)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dateLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF0E2A47),
                    fontWeight: FontWeight.w900,
                    fontSize: 14.5,
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 5,
                  runSpacing: 4,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECEFF1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        '48 Pieces',
                        style: TextStyle(
                          color: Color(0xFF546E7A),
                          fontWeight: FontWeight.w700,
                          fontSize: 10.5,
                        ),
                      ),
                    ),
                    if (isDone)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Solved ✓',
                          style: TextStyle(
                            color: Color(0xFF2E7D32),
                            fontWeight: FontWeight.w800,
                            fontSize: 10.5,
                          ),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF8E1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('🪙', style: TextStyle(fontSize: 10)),
                            SizedBox(width: 2),
                            Text(
                              '+30 Coins',
                              style: TextStyle(
                                color: Color(0xFFFF8F00),
                                fontWeight: FontWeight.w800,
                                fontSize: 10.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Action Button
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              _playDayPuzzle(date);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isDone ? const Color(0xFFECEFF1) : const Color(0xFFFFB300),
                borderRadius: BorderRadius.circular(16),
                boxShadow: isDone
                    ? null
                    : const [
                        BoxShadow(
                          color: Color(0x40FFA000),
                          blurRadius: 6,
                          offset: Offset(0, 3),
                        ),
                      ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isDone ? Icons.replay_rounded : Icons.play_arrow_rounded,
                    color: isDone ? const Color(0xFF546E7A) : Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isDone ? 'Replay' : 'Play',
                    style: TextStyle(
                      color: isDone ? const Color(0xFF546E7A) : Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 12.5,
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

  // --- Today's Puzzle Challenge Preview & Play ---
  Widget _buildTodayPuzzleChallenge() {
    final dailyPic = _getDailyPicture();
    final isTodayDone = _storage.isDailyDateCompleted(_today);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(color: Color(0x250D2544), blurRadius: 16, offset: Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Flexible(
                child: Text(
                  "Today's Challenge",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Color(0xFF0E2A47),
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isTodayDone ? const Color(0xFFE8F5E9) : const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isTodayDone ? Icons.check_circle_rounded : Icons.star_rounded,
                      color: isTodayDone ? const Color(0xFF00E676) : const Color(0xFFFFB300),
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isTodayDone ? 'COMPLETED' : '+50 COINS',
                      style: TextStyle(
                        color: isTodayDone ? const Color(0xFF2E7D32) : const Color(0xFFFF8F00),
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Picture Preview
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Stack(
              children: [
                Image.asset(
                  dailyPic.path,
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
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xEE112238),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      DateFormat('EEEE, MMM d').format(_today),
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Big 3D Tactile Golden PLAY Button
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              _playDayPuzzle(_today);
            },
            child: Container(
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isTodayDone ? Icons.replay_rounded : Icons.play_arrow_rounded,
                    color: const Color(0xFF3E2723),
                    size: 28,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isTodayDone ? 'REPLAY TODAY\'S PUZZLE' : 'PLAY TODAY\'S PUZZLE',
                    style: const TextStyle(
                      color: Color(0xFF3E2723),
                      fontSize: 16.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.1,
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

  void _playDayPuzzle(DateTime date) {
    final pic = _getDailyPictureForDate(date);
    context.push('/puzzle?id=${pic.id}&pieces=48&daily=true');
  }

  PuzzlePicture _getDailyPicture() {
    return _getDailyPictureForDate(_today);
  }

  PuzzlePicture _getDailyPictureForDate(DateTime date) {
    if (_content.allPictures.isNotEmpty) {
      final index = (date.year * 365 + date.month * 31 + date.day) % _content.allPictures.length;
      return _content.allPictures[index];
    }
    return PuzzlePicture(
      id: 'n001',
      category: 'nature',
      path: 'assets/puzzles/nature/n001.jpg',
      title: 'Daily Puzzle',
      premium: false,
    );
  }

  String _weekdayShort(int weekday) {
    switch (weekday) {
      case 1:
        return 'MON';
      case 2:
        return 'TUE';
      case 3:
        return 'WED';
      case 4:
        return 'THU';
      case 5:
        return 'FRI';
      case 6:
        return 'SAT';
      case 7:
        return 'SUN';
      default:
        return '';
    }
  }
}
