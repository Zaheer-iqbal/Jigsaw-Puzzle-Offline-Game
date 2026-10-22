import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:jigsaw_pro/core/storage/hive_storage.dart';
import 'package:jigsaw_pro/core/utils/responsive.dart';
import 'package:jigsaw_pro/core/widgets/casual_game_background.dart';
import 'package:jigsaw_pro/features/content/domain/entities/puzzle_level.dart';
import 'package:jigsaw_pro/features/content/domain/entities/puzzle_picture.dart';
import 'package:jigsaw_pro/features/content/presentation/controllers/content_controller.dart';

class DifficultyPickerPage extends StatefulWidget {
  final String pictureId;
  final int? initialCount;

  const DifficultyPickerPage({
    super.key,
    required this.pictureId,
    this.initialCount,
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
      final saved = storage.getActiveSession()?['pieceCount'] as int? ?? 48;
      _selectedCount = pieceCounts.contains(saved) ? saved : 48;
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = Get.find<ContentController>();
    var pic = content.allPictures.firstWhereOrNull((p) => p.id == widget.pictureId);

    if (pic == null && content.allPictures.isNotEmpty) {
      final prefix = widget.pictureId.substring(0, 1).toLowerCase();
      const catMap = {'n': 'nature', 'a': 'animals', 'f': 'flowers', 'l': 'landmarks', 'art': 'art'};
      final cat = catMap[prefix] ?? 'nature';
      final catPics = content.allPictures.where((p) => p.category.toLowerCase() == cat).toList();
      final fallbackPic = catPics.isNotEmpty ? catPics.first : content.allPictures.first;
      final numStr = widget.pictureId.replaceAll(RegExp(r'[^0-9]'), '');
      pic = PuzzlePicture(
        id: widget.pictureId,
        category: cat,
        path: fallbackPic.path,
        title: '${cat[0].toUpperCase()}${cat.substring(1)} Level $numStr',
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
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CasualGameBackground(
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 8),
              // Top Bar with Circular Back button & 3D Title
              _buildTopBar(context, targetPic),
              const SizedBox(height: 8),
              // Content Area
              Expanded(
                child: Responsive(
                  portrait: (context, constraints) => _buildPortrait(context, targetPic, constraints),
                  landscape: (context, constraints) => _buildLandscape(context, targetPic, constraints),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, PuzzlePicture pic) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Dark Circular Back Button
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/gallery');
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
          // Title
          Expanded(
            child: Text(
              pic.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                shadows: [
                  Shadow(color: Color(0xFF0D2544), offset: Offset(0, 2), blurRadius: 0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPortrait(BuildContext context, PuzzlePicture pic, BoxConstraints constraints) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        children: [
          // Preview Card
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(26),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x300D2544),
                    blurRadius: 18,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(pic.path, fit: BoxFit.contain),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Controls Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(26),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x250D2544),
                  blurRadius: 16,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Choose Puzzle Difficulty',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0E2A47),
                  ),
                ),
                const SizedBox(height: 14),
                _buildPieceChips(),
                const SizedBox(height: 18),
                _buildStartButton(context, pic),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLandscape(BuildContext context, PuzzlePicture pic, BoxConstraints constraints) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        children: [
          // Preview
          Expanded(
            flex: 5,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(26),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x300D2544),
                    blurRadius: 16,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(pic.path, fit: BoxFit.contain),
              ),
            ),
          ),
          const SizedBox(width: 20),
          // Controls
          Expanded(
            flex: 5,
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(26),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x250D2544),
                    blurRadius: 16,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Choose Puzzle Difficulty',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0E2A47),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _buildPieceChips(),
                  const SizedBox(height: 18),
                  _buildStartButton(context, pic),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPieceChips() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      alignment: WrapAlignment.center,
      children: pieceCounts.map((count) {
        final isSelected = count == _selectedCount;
        final label = PuzzleLevel.getDifficultyLabel(count);

        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() {
              _selectedCount = count;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFFFB300) : const Color(0xFFF0F4F8),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? const Color(0xFFFF8F00) : const Color(0xFFCFD8DC),
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected
                  ? const [
                      BoxShadow(color: Color(0x33FFB300), blurRadius: 6, offset: Offset(0, 2)),
                    ]
                  : null,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$count Pcs',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                    color: isSelected ? const Color(0xFF0E2A47) : const Color(0xFF37474F),
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? const Color(0xFF3E2723) : const Color(0xFF78909C),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStartButton(BuildContext context, PuzzlePicture pic) {
    return SizedBox(
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
          HapticFeedback.lightImpact();
          context.push('/puzzle?id=${pic.id}&count=$_selectedCount');
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.play_arrow_rounded, size: 28),
            const SizedBox(width: 8),
            Text(
              'Start Puzzle ($_selectedCount Pieces)',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
    );
  }
}
