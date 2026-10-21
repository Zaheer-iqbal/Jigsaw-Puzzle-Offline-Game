import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:jigsaw_pro/core/storage/hive_storage.dart';
import 'package:jigsaw_pro/core/theme/app_theme.dart';
import 'package:jigsaw_pro/core/utils/responsive.dart';
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
        appBar: AppBar(),
        body: const Center(child: Text('Picture not found')),
      );
    }

    final targetPic = pic;
    return Scaffold(
      appBar: AppBar(
        title: Text(targetPic.title),
      ),
      body: SafeArea(
        child: Responsive(
          portrait: (context, constraints) => _buildPortrait(context, targetPic, constraints),
          landscape: (context, constraints) => _buildLandscape(context, targetPic, constraints),
        ),
      ),
    );
  }

  Widget _buildPortrait(BuildContext context, PuzzlePicture pic, BoxConstraints constraints) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(pic.path, fit: BoxFit.contain),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Choose Piece Count',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 14),
          _buildPieceChips(),
          const SizedBox(height: 24),
          _buildStartButton(context, pic),
        ],
      ),
    );
  }

  Widget _buildLandscape(BuildContext context, PuzzlePicture pic, BoxConstraints constraints) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(pic.path, fit: BoxFit.contain),
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            flex: 5,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Choose Piece Count',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _buildPieceChips(),
                const SizedBox(height: 24),
                _buildStartButton(context, pic),
              ],
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
        return ChoiceChip(
          label: Text(
            '$count Pieces',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.black : null,
            ),
          ),
          selected: isSelected,
          selectedColor: AppTheme.accentAmber,
          onSelected: (_) {
            setState(() {
              _selectedCount = count;
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildStartButton(BuildContext context, PuzzlePicture pic) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryTeal,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        onPressed: () {
          context.push('/puzzle?id=${pic.id}&count=$_selectedCount');
        },
        child: const Text('Start Puzzle', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
