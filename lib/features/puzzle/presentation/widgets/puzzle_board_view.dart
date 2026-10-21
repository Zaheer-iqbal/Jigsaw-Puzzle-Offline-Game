import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jigsaw_pro/core/config/app_config.dart';
import 'package:jigsaw_pro/core/theme/app_theme.dart';
import 'package:jigsaw_pro/core/utils/responsive.dart';
import 'package:jigsaw_pro/features/monetization/presentation/controllers/monetization_controller.dart';
import 'package:jigsaw_pro/features/puzzle/presentation/canvas/board_painter.dart';
import 'package:jigsaw_pro/features/puzzle/presentation/controllers/puzzle_controller.dart';
import 'package:jigsaw_pro/features/settings/presentation/controllers/settings_controller.dart';

class PuzzleBoardView extends StatefulWidget {
  final PuzzleController controller;
  final VoidCallback onBack;

  const PuzzleBoardView({
    super.key,
    required this.controller,
    required this.onBack,
  });

  @override
  State<PuzzleBoardView> createState() => _PuzzleBoardViewState();
}

class _PuzzleBoardViewState extends State<PuzzleBoardView> {
  final TransformationController _transformController = TransformationController();
  final ValueNotifier<Offset> _activeDragDeltaNotifier = ValueNotifier(Offset.zero);

  int? _activeDraggingGroupId;
  Offset? _touchStartScenePos;
  bool _isPanningAllowed = true;

  @override
  void dispose() {
    _transformController.dispose();
    _activeDragDeltaNotifier.dispose();
    super.dispose();
  }

  void _resetZoomFit(Size boardSize, Size viewportSize) {
    final scaleX = (viewportSize.width * 0.90) / boardSize.width;
    final scaleY = (viewportSize.height * 0.90) / boardSize.height;
    final fitScale = (scaleX < scaleY ? scaleX : scaleY).clamp(AppConfig.minZoomScale, AppConfig.maxZoomScale);

    final dx = (viewportSize.width - boardSize.width * fitScale) / 2;
    final dy = (viewportSize.height - boardSize.height * fitScale) / 2;

    _transformController.value = Matrix4(
      fitScale, 0, 0, 0,
      0, fitScale, 0, 0,
      0, 0, 1, 0,
      dx, dy, 0, 1,
    );
  }

  Offset _screenToBoard(Offset screenPos) {
    final inverse = Matrix4.tryInvert(_transformController.value);
    if (inverse == null) return screenPos;
    return MatrixUtils.transformPoint(inverse, screenPos);
  }

  @override
  Widget build(BuildContext context) {
    final settings = Get.find<SettingsController>();

    return Obx(() {
      final state = widget.controller.state.value;

      if (state == PuzzleState.preparing) {
        return _buildLoadingScreen(widget.controller.prepareProgress.value);
      }

      if (state == PuzzleState.error) {
        return _buildErrorScreen();
      }

      final bgStyle = settings.boardBackground.value;

      return Scaffold(
        backgroundColor: bgStyle.primaryColor,
        body: SafeArea(
          child: Responsive(
            portrait: (context, constraints) => _buildPortraitLayout(context, constraints, bgStyle),
            landscape: (context, constraints) => _buildLandscapeLayout(context, constraints, bgStyle),
          ),
        ),
      );
    });
  }

  Widget _buildPortraitLayout(BuildContext context, BoxConstraints constraints, BoardBackgroundStyle bgStyle) {
    return Column(
      children: [
        _buildTopBar(),
        Expanded(
          child: _buildCanvasArea(
            Size(constraints.maxWidth, constraints.maxHeight - 160),
            bgStyle,
          ),
        ),
        _buildBottomToolbar(isLandscape: false),
      ],
    );
  }

  Widget _buildLandscapeLayout(BuildContext context, BoxConstraints constraints, BoardBackgroundStyle bgStyle) {
    return Row(
      children: [
        SizedBox(
          width: 72,
          child: _buildLandscapeSideToolbar(),
        ),
        Expanded(
          child: Column(
            children: [
              _buildTopBar(isLandscape: true),
              Expanded(
                child: _buildCanvasArea(
                  Size(constraints.maxWidth - 80, constraints.maxHeight - 50),
                  bgStyle,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCanvasArea(Size viewportSize, BoardBackgroundStyle bgStyle) {
    final boardSize = Size(widget.controller.boardW, widget.controller.boardH);

    return LayoutBuilder(
      builder: (context, box) {
        return Listener(
          onPointerDown: (event) {
            final scenePos = _screenToBoard(event.localPosition);
            final hitGroup = widget.controller.hitTestGroup(scenePos);

            if (hitGroup != null) {
              setState(() {
                _activeDraggingGroupId = hitGroup;
                _touchStartScenePos = scenePos;
                _isPanningAllowed = false;
                _activeDragDeltaNotifier.value = Offset.zero;
              });
            } else {
              _isPanningAllowed = true;
            }
          },
          onPointerMove: (event) {
            if (_activeDraggingGroupId != null && _touchStartScenePos != null) {
              final currentScenePos = _screenToBoard(event.localPosition);
              _activeDragDeltaNotifier.value = currentScenePos - _touchStartScenePos!;
            }
          },
          onPointerUp: (event) {
            if (_activeDraggingGroupId != null && _touchStartScenePos != null) {
              final currentScenePos = _screenToBoard(event.localPosition);
              final totalDelta = currentScenePos - _touchStartScenePos!;
              final gid = _activeDraggingGroupId!;

              setState(() {
                _activeDraggingGroupId = null;
                _touchStartScenePos = null;
                _isPanningAllowed = true;
                _activeDragDeltaNotifier.value = Offset.zero;
              });

              widget.controller.onGroupDrop(gid, totalDelta);
            }
          },
          child: InteractiveViewer(
            transformationController: _transformController,
            constrained: false,
            panEnabled: _isPanningAllowed,
            scaleEnabled: _isPanningAllowed,
            minScale: AppConfig.minZoomScale,
            maxScale: AppConfig.maxZoomScale,
            boundaryMargin: const EdgeInsets.all(500),
            child: SizedBox(
              width: boardSize.width,
              height: boardSize.height,
              child: RepaintBoundary(
                child: ValueListenableBuilder<Offset>(
                  valueListenable: _activeDragDeltaNotifier,
                  builder: (context, dragDelta, _) {
                    return Obx(() {
                      return CustomPaint(
                        size: boardSize,
                        painter: BoardPainter(
                          pieces: widget.controller.pieces,
                          groups: widget.controller.groups,
                          preRenderedPieces: widget.controller.preRenderedPieces,
                          activeGroupId: _activeDraggingGroupId,
                          activeDragDelta: dragDelta,
                          boardSize: boardSize,
                          fullImage: widget.controller.decodedSourceImage,
                          showGhost: widget.controller.showGhost.value,
                          edgesOnly: widget.controller.edgesOnly.value,
                          hintPieceKey: widget.controller.hintPieceKey.value,
                          backgroundStyle: bgStyle,
                        ),
                      );
                    });
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopBar({bool isLandscape = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.black.withValues(alpha: 0.2),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 22),
            onPressed: widget.onBack,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatPill(
                  icon: Icons.timer_outlined,
                  value: _formatTime(widget.controller.elapsedSeconds.value),
                ),
                _buildStatPill(
                  icon: Icons.touch_app_outlined,
                  value: '${widget.controller.moves.value} moves',
                ),
                _buildStatPill(
                  icon: Icons.extension_outlined,
                  value: '${widget.controller.lockedPiecesCount.value}/${widget.controller.actualPieceCount}',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatPill({required IconData icon, required String value}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white70, size: 16),
          const SizedBox(width: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomToolbar({required bool isLandscape}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: Colors.black.withValues(alpha: 0.3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildToolButton(
            icon: widget.controller.showGhost.value ? Icons.visibility : Icons.visibility_off_outlined,
            label: 'Preview',
            isActive: widget.controller.showGhost.value,
            onTap: widget.controller.toggleGhost,
          ),
          _buildToolButton(
            icon: Icons.lightbulb_outline,
            label: 'Hint (15)',
            onTap: _handleHintPress,
          ),
          _buildToolButton(
            icon: Icons.border_clear,
            label: 'Edges',
            isActive: widget.controller.edgesOnly.value,
            onTap: widget.controller.toggleEdges,
          ),
          _buildToolButton(
            icon: Icons.fit_screen_outlined,
            label: 'Fit',
            onTap: () {
              final size = MediaQuery.of(context).size;
              _resetZoomFit(
                Size(widget.controller.boardW, widget.controller.boardH),
                size,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLandscapeSideToolbar() {
    return Container(
      color: Colors.black.withValues(alpha: 0.35),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
            onPressed: widget.onBack,
          ),
          _buildToolButton(
            icon: widget.controller.showGhost.value ? Icons.visibility : Icons.visibility_off_outlined,
            label: 'Ghost',
            isActive: widget.controller.showGhost.value,
            onTap: widget.controller.toggleGhost,
          ),
          _buildToolButton(
            icon: Icons.lightbulb_outline,
            label: 'Hint',
            onTap: _handleHintPress,
          ),
          _buildToolButton(
            icon: Icons.border_clear,
            label: 'Edges',
            isActive: widget.controller.edgesOnly.value,
            onTap: widget.controller.toggleEdges,
          ),
          _buildToolButton(
            icon: Icons.fit_screen_outlined,
            label: 'Fit',
            onTap: () {
              final size = MediaQuery.of(context).size;
              _resetZoomFit(
                Size(widget.controller.boardW, widget.controller.boardH),
                size,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildToolButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.accentAmber.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive ? AppTheme.accentAmber : Colors.white24,
            width: 1.2,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isActive ? AppTheme.accentAmber : Colors.white, size: 22),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: isActive ? AppTheme.accentAmber : Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleHintPress() {
    final success = widget.controller.requestHint();
    if (!success) {
      Get.snackbar(
        'Not enough coins',
        'Hints cost 15 coins. Watch an ad or get more in the Shop.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xDD000000),
        colorText: Colors.white,
        mainButton: TextButton(
          onPressed: () {
            final monetization = Get.find<MonetizationController>();
            monetization.showRewardedAd(
              onRewardEarned: () {
                widget.controller.triggerRewardedHint();
              },
            );
          },
          child: const Text('Watch Ad', style: TextStyle(color: AppTheme.accentAmber)),
        ),
      );
    }
  }

  Widget _buildLoadingScreen(double progress) {
    return Scaffold(
      backgroundColor: const Color(0xFF14171A),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.extension, size: 64, color: AppTheme.accentAmber),
              const SizedBox(height: 24),
              const Text(
                'Cutting pieces...',
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: Colors.white12,
                  valueColor: const AlwaysStoppedAnimation(AppTheme.accentAmber),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '${(progress * 100).toInt()}%',
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorScreen() {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 56, color: Colors.redAccent),
            const SizedBox(height: 16),
            const Text('Could not load puzzle'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: widget.onBack,
              child: const Text('Back to Home'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(int totalSeconds) {
    final m = totalSeconds ~/ 60;
    final s = totalSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}
