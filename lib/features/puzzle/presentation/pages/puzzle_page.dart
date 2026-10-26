import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:jigsaw_pro/features/content/domain/entities/puzzle_picture.dart';
import 'package:jigsaw_pro/features/content/presentation/controllers/content_controller.dart';
import 'package:jigsaw_pro/features/puzzle/presentation/controllers/puzzle_controller.dart';
import 'package:jigsaw_pro/features/puzzle/presentation/widgets/puzzle_board_view.dart';

class PuzzlePage extends StatefulWidget {
  final String? pictureId;
  final int? pieceCount;
  final bool isResume;
  final int? sagaLevel;
  final bool isDaily;

  const PuzzlePage({
    super.key,
    this.pictureId,
    this.pieceCount,
    this.isResume = false,
    this.sagaLevel,
    this.isDaily = false,
  });

  @override
  State<PuzzlePage> createState() => _PuzzlePageState();
}

class _PuzzlePageState extends State<PuzzlePage> {
  late final PuzzleController _puzzleController;
  Worker? _winWorker;

  @override
  void initState() {
    super.initState();
    _puzzleController = Get.find<PuzzleController>();

    // Listen for puzzle victory to push WinPage
    _winWorker = ever(_puzzleController.state, (state) {
      if (state == PuzzleState.completed && mounted) {
        context.pushReplacement('/win');
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initSession();
    });
  }

  @override
  void dispose() {
    _winWorker?.dispose();
    super.dispose();
  }

  Future<void> _initSession() async {
    final content = Get.find<ContentController>();
    if (content.allPictures.isEmpty) {
      await content.loadContent();
    }

    final picId = widget.pictureId ?? (content.allPictures.isNotEmpty ? content.allPictures.first.id : 'n001');
    var pic = content.allPictures.firstWhereOrNull((p) => p.id == picId);

    // Loose match if exact id match failed (e.g. 'n001' vs 'n001.bpm')
    pic ??= content.allPictures.firstWhereOrNull(
      (p) => p.id.toLowerCase().contains(picId.toLowerCase()) ||
             picId.toLowerCase().contains(p.id.toLowerCase()),
    );

    if (pic == null && content.allPictures.isNotEmpty) {
      final lower = picId.toLowerCase();
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
      final numStr = picId.replaceAll(RegExp(r'[^0-9]'), '').replaceFirst(RegExp(r'^0+'), '');
      pic = PuzzlePicture(
        id: picId,
        category: cat,
        path: fallbackPic.path,
        title: widget.isDaily ? 'Daily Puzzle' : '${cat[0].toUpperCase()}${cat.substring(1)} Level ${numStr.isEmpty ? "1" : numStr}',
        premium: false,
      );
    }

    // Guaranteed ultimate fallback
    pic ??= const PuzzlePicture(
      id: 'n001',
      category: 'nature',
      path: 'assets/puzzles/nature/n001.jpg',
      title: 'Nature Level 1',
      premium: false,
    );

    // Allocate 1000px virtual canvas resolution with image aspect ratio
    const baseCanvasW = 1000.0;
    const baseCanvasH = 750.0;

    _puzzleController.startPuzzle(
      id: pic.id,
      assetPath: pic.path,
      title: widget.isDaily ? 'Daily Puzzle' : pic.title,
      pieceCount: widget.pieceCount ?? 48,
      boardRenderSize: const Size(baseCanvasW, baseCanvasH),
      isResume: widget.isResume,
      sagaLevel: widget.sagaLevel,
      isDailyPuzzle: widget.isDaily,
    );
  }

  void _handleBack() {
    // Controller auto-saves on dispose / back
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _handleBack();
        }
      },
      child: PuzzleBoardView(
        controller: _puzzleController,
        onBack: _handleBack,
      ),
    );
  }
}
