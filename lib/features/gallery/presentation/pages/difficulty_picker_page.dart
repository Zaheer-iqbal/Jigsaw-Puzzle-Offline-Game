import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:jigsaw_pro/core/config/app_config.dart';
import 'package:jigsaw_pro/core/storage/hive_storage.dart';
import 'package:jigsaw_pro/core/widgets/casual_game_background.dart';
import 'package:jigsaw_pro/features/content/domain/entities/puzzle_picture.dart';
import 'package:jigsaw_pro/features/content/presentation/controllers/content_controller.dart';

class DifficultyPickerPage extends StatefulWidget {
  final String pictureId;
  final int? initialCount;
  final bool isDaily;

  const DifficultyPickerPage({
    super.key,
    required this.pictureId,
    this.initialCount,
    this.isDaily = false,
  });

  @override
  State<DifficultyPickerPage> createState() => _DifficultyPickerPageState();
}

class _DifficultyPickerPageState extends State<DifficultyPickerPage> {
  static const List<int> pieceCounts = [12, 24, 48, 100, 200, 400];
  late int _selectedCount;

  @override
  void initState() {
    super.initState();
    if (widget.initialCount != null && pieceCounts.contains(widget.initialCount)) {
      _selectedCount = widget.initialCount!;
    } else {
      final storage = Get.find<HiveStorage>();
      final saved = storage.getActiveSession()?['pieceCount'] as int? ?? 100;
      _selectedCount = pieceCounts.contains(saved) ? saved : 100;
    }
  }

  String _getDifficultyLabel(int count) {
    switch (count) {
      case 12:
        return 'Easy';
      case 24:
        return 'Casual';
      case 48:
        return 'Relaxed';
      case 100:
        return 'Medium';
      case 200:
        return 'Hard';
      case 400:
        return 'Expert';
      default:
        return 'Casual';
    }
  }

  String _getEstimatedTime(int count) {
    switch (count) {
      case 12:
        return 'About 2 min';
      case 24:
        return 'About 5 min';
      case 48:
        return 'About 8 min';
      case 100:
        return 'About 15 min';
      case 200:
        return 'About 30 min';
      case 400:
        return 'About 60 min';
      default:
        return 'About 15 min';
    }
  }

  int _getRewardCoins(int count) {
    if (widget.isDaily) {
      return AppConfig.coinsDailyBonus; // +20
    }
    switch (count) {
      case 12:
      case 24:
        return AppConfig.coinsFinish12or24; // 10
      case 48:
      case 100:
        return AppConfig.coinsFinish48or100; // 25
      case 200:
        return AppConfig.coinsFinish200; // 50
      case 400:
        return AppConfig.coinsFinish400; // 100
      default:
        return 25;
    }
  }

  String _formatDisplayTitle(String rawTitle, String category) {
    if (widget.isDaily) return 'Daily Puzzle';
    var title = rawTitle.replaceAll(RegExp(r'\.(bpm|png|jpg|jpeg)$', caseSensitive: false), '').trim();
    if (RegExp(r'^[a-z]+[0-9]+$', caseSensitive: false).hasMatch(title)) {
      final numStr = title.replaceAll(RegExp(r'[^0-9]'), '').replaceFirst(RegExp(r'^0+'), '');
      final catCap = category.isNotEmpty ? '${category[0].toUpperCase()}${category.substring(1)}' : 'Puzzle';
      return '$catCap Level ${numStr.isEmpty ? "1" : numStr}';
    }
    return title.isNotEmpty ? title : 'Puzzle Level';
  }

  @override
  Widget build(BuildContext context) {
    final content = Get.find<ContentController>();
    var pic = content.allPictures.firstWhereOrNull((p) => p.id == widget.pictureId);

    if (pic == null && content.allPictures.isNotEmpty) {
      final lower = widget.pictureId.toLowerCase();
      String cat = 'nature';
      if (lower.startsWith('art')) {
        cat = 'art';
      } else if (lower.startsWith('n')) {
        cat = 'nature';
      } else if (lower.startsWith('a')) {
        cat = 'animals';
      } else if (lower.startsWith('f')) {
        cat = 'flowers';
      } else if (lower.startsWith('l')) {
        cat = 'landmarks';
      }

      final catPics = content.allPictures.where((p) => p.category.toLowerCase() == cat).toList();
      final fallbackPic = catPics.isNotEmpty ? catPics.first : content.allPictures.first;
      final numStr = widget.pictureId.replaceAll(RegExp(r'[^0-9]'), '').replaceFirst(RegExp(r'^0+'), '');

      pic = PuzzlePicture(
        id: widget.pictureId,
        category: cat,
        path: fallbackPic.path,
        title: widget.isDaily ? 'Daily Puzzle' : '${cat[0].toUpperCase()}${cat.substring(1)} Level ${numStr.isEmpty ? "1" : numStr}',
        premium: false,
      );
    }

    if (pic == null) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: CasualGameBackground(
          child: const Center(
            child: Text('Picture not found', style: TextStyle(color: Colors.white, fontSize: 16)),
          ),
        ),
      );
    }

    final targetPic = pic;
    final displayTitle = _formatDisplayTitle(targetPic.title, targetPic.category);
    final displayCategory = widget.isDaily
        ? 'Daily Challenge'
        : (targetPic.category.isNotEmpty
            ? '${targetPic.category[0].toUpperCase()}${targetPic.category.substring(1)}'
            : 'Puzzle');

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CasualGameBackground(
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 8),
              // Top Bar with Back Button & 3D "Choose size"
              _buildTopBar(context),
              const SizedBox(height: 10),

              // Main Body Content
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Picture Card (Hero Image with rounded corners & clean Title/Category strip)
                      _buildPicturePreviewCard(targetPic, displayTitle, displayCategory),

                      const SizedBox(height: 18),

                      // 2. "Pieces" Header
                      const Text(
                        'Pieces',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          shadows: [
                            Shadow(
                              color: Color(0xFF0D2544),
                              offset: Offset(0, 2),
                              blurRadius: 0,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      // 3. 2x3 Grid of 6 Pieces Cards (12, 24, 48, 100, 200, 400)
                      _buildPiecesGrid(),

                      const SizedBox(height: 14),

                      // 4. Time Estimate & Reward Pill
                      _buildEstimateAndRewardPill(),

                      const SizedBox(height: 12),

                      // 5. Mystery Mode Pill
                      _buildMysteryModePill(),

                      const SizedBox(height: 20),

                      // 6. Big Golden 3D START Button
                      _buildStartButton(context, targetPic),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
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
                child: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
              ),
            ),
          ),
          const SizedBox(width: 14),

          // 3D Bubble Title "Choose size"
          const Text(
            'Choose size',
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
              shadows: [
                Shadow(
                  color: Color(0xFF0D2544),
                  offset: Offset(0, 3),
                  blurRadius: 0,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPicturePreviewCard(PuzzlePicture pic, String displayTitle, String displayCategory) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x280D2544),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Image Preview with Rounded Top Corners
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: AspectRatio(
              aspectRatio: 1.55,
              child: Image.asset(
                pic.path,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: const Color(0xFFCFD8DC),
                    child: const Center(
                      child: Icon(Icons.image_outlined, color: Colors.blueGrey, size: 48),
                    ),
                  );
                },
              ),
            ),
          ),

          // Bottom Info Strip
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    displayTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF0E2A47),
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  displayCategory,
                  style: const TextStyle(
                    color: Color(0xFF78909C),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPiecesGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: pieceCounts.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.25,
      ),
      itemBuilder: (context, index) {
        final count = pieceCounts[index];
        final isSelected = count == _selectedCount;
        final label = _getDifficultyLabel(count);

        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() {
              _selectedCount = count;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFFFB300) : Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: isSelected ? const Color(0xFFE65100) : const Color(0x200D2544),
                  offset: Offset(0, isSelected ? 4 : 3),
                  blurRadius: isSelected ? 0 : 6,
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$count',
                  style: const TextStyle(
                    color: Color(0xFF0E2A47),
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? const Color(0xFF0E2A47) : const Color(0xFF546E7A),
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEstimateAndRewardPill() {
    final estTime = _getEstimatedTime(_selectedCount);
    final reward = _getRewardCoins(_selectedCount);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
      decoration: BoxDecoration(
        color: const Color(0xFF16355C),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x25000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            estTime,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          Row(
            children: [
              const Text(
                'Reward ',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Text('🪙', style: TextStyle(fontSize: 15)),
              const SizedBox(width: 4),
              Text(
                '+$reward',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMysteryModePill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
      decoration: BoxDecoration(
        color: const Color(0xFF16355C),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x25000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Mystery mode',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Text(
              'Coming soon',
              style: TextStyle(
                color: Color(0xFF16355C),
                fontWeight: FontWeight.w900,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStartButton(BuildContext context, PuzzlePicture pic) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        context.push('/puzzle?id=${pic.id}&count=$_selectedCount${widget.isDaily ? "&daily=true" : ""}');
      },
      child: Container(
        width: double.infinity,
        height: 58,
        decoration: BoxDecoration(
          color: const Color(0xFFFFB300),
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(
              color: Color(0xFFE65100),
              offset: Offset(0, 5),
              blurRadius: 0,
            ),
            BoxShadow(
              color: Color(0x33000000),
              offset: Offset(0, 7),
              blurRadius: 8,
            ),
          ],
        ),
        child: const Center(
          child: Text(
            'START',
            style: TextStyle(
              color: Color(0xFF0E2A47),
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
        ),
      ),
    );
  }
}
