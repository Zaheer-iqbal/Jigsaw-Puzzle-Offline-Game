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

  const PuzzlePage({
    super.key,
    this.pictureId,
    this.pieceCount,
    this.isResume = false,
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

  void _initSession() {
    final content = Get.find<ContentController>();
    final picId = widget.pictureId ?? (content.allPictures.isNotEmpty ? content.allPictures.first.id : 'n001');
    var pic = content.allPictures.firstWhereOrNull((p) => p.id == picId);

    if (pic == null && content.allPictures.isNotEmpty) {
      final prefix = picId.substring(0, 1).toLowerCase();
      const catMap = {'n': 'nature', 'a': 'animals', 'f': 'flowers', 'l': 'landmarks', 'art': 'art'};
      final cat = catMap[prefix] ?? 'nature';
      final catPics = content.allPictures.where((p) => p.category.toLowerCase() == cat).toList();
      final fallbackPic = catPics.isNotEmpty ? catPics.first : content.allPictures.first;
      final numStr = picId.replaceAll(RegExp(r'[^0-9]'), '');
      pic = PuzzlePicture(
        id: picId,
        category: cat,
        path: fallbackPic.path,
        title: '${cat[0].toUpperCase()}${cat.substring(1)} Level $numStr',
        premium: false,
      );
    }

    if (pic == null) return;

    // Allocate 1000px virtual canvas resolution with image aspect ratio
    const baseCanvasW = 1000.0;
    const baseCanvasH = 750.0;

    _puzzleController.startPuzzle(
      id: pic.id,
      assetPath: pic.path,
      title: pic.title,
      pieceCount: widget.pieceCount ?? 48,
      boardRenderSize: const Size(baseCanvasW, baseCanvasH),
      isResume: widget.isResume,
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
