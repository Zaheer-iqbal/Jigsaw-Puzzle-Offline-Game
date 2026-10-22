import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:jigsaw_pro/core/theme/app_theme.dart';
import 'package:jigsaw_pro/features/economy/presentation/controllers/economy_controller.dart';
import 'package:jigsaw_pro/features/monetization/presentation/controllers/monetization_controller.dart';
import 'package:jigsaw_pro/features/puzzle/presentation/canvas/board_painter.dart';
import 'package:jigsaw_pro/features/puzzle/presentation/canvas/piece_image_pre_renderer.dart';
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

class _PuzzleBoardViewState extends State<PuzzleBoardView> with SingleTickerProviderStateMixin {
  final GlobalKey _boardKey = GlobalKey();
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
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
      final isLight = bgStyle == BoardBackgroundStyle.cleanLight;

      return Scaffold(
        backgroundColor: isLight ? const Color(0xFFEEF2F6) : const Color(0xFF131B26),
        body: Container(
          // Clean tabletop ambient illumination
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isLight
                  ? [
                      const Color(0xFFF7FAFD),
                      const Color(0xFFEEF3F8),
                      const Color(0xFFDFE6EE),
                    ]
                  : [
                      const Color(0xFF1E2838),
                      const Color(0xFF131B26),
                      const Color(0xFF0C1118),
                    ],
            ),
          ),
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Calculate responsive board dimensions
                final maxW = constraints.maxWidth - 24; // 12px padding on each side
                final maxH = constraints.maxHeight - 210; // Reserve for top HUD and bottom tray
                final aspect = widget.controller.boardW / (widget.controller.boardH > 0 ? widget.controller.boardH : 1.0);

                double renderW, renderH;
                if (maxW / maxH > aspect) {
                  renderH = maxH;
                  renderW = renderH * aspect;
                } else {
                  renderW = maxW;
                  renderH = renderW / aspect;
                }

                return Column(
                  children: [
                    // 1. Floating Top HUD
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
                      child: _buildFloatingTopBar(isLight, settings),
                    ),

                    // 2. Center Assembly Board (responsive for every mobile screen)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: Center(
                          child: SizedBox(
                            width: renderW,
                            height: renderH,
                            child: _buildBoardDropZone(renderW, renderH, bgStyle),
                          ),
                        ),
                      ),
                    ),

                    // 3. Bottom Scrollable Piece Tray (Carousel)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                      child: _buildBottomPieceTray(isLight, renderW),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );
    });
  }

  // --- Center Board Drop Target Area ---
  Widget _buildBoardDropZone(double renderW, double renderH, BoardBackgroundStyle bgStyle) {
    return DragTarget<String>(
      onWillAcceptWithDetails: (details) => true,
      onAcceptWithDetails: (details) {
        final box = _boardKey.currentContext?.findRenderObject() as RenderBox?;
        if (box != null) {
          final localDrop = box.globalToLocal(details.offset);
          final pieceKey = details.data;
          final prePiece = widget.controller.preRenderedPieces[pieceKey];
          if (prePiece == null) return;

          final screenScale = renderW / (widget.controller.boardW > 0 ? widget.controller.boardW : 750.0);
          final feedbackW = (widget.controller.pieceW + 2 * prePiece.margin) * screenScale;
          final feedbackH = (widget.controller.pieceH + 2 * prePiece.margin) * screenScale;

          // localDrop is the top-left of the feedback widget on screen relative to the board
          final droppedCenterScreen = localDrop + Offset(feedbackW / 2, feedbackH / 2);

          // Convert screen drop center to virtual board coordinates
          final droppedCenter = Offset(
            droppedCenterScreen.dx / screenScale,
            droppedCenterScreen.dy / screenScale,
          );

          final didSnap = widget.controller.trySnapPiece(pieceKey, droppedCenter);
          if (!didSnap) {
            HapticFeedback.lightImpact();
          }
        }
      },
      builder: (context, candidateData, rejectedData) {
        return RepaintBoundary(
          key: _boardKey,
          child: AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return CustomPaint(
                size: Size(renderW, renderH),
                painter: BoardPainter(
                  pieces: widget.controller.pieces,
                  lockedPieceKeys: widget.controller.lockedPieceKeys.toSet(),
                  preRenderedPieces: widget.controller.preRenderedPieces,
                  boardSize: Size(widget.controller.boardW, widget.controller.boardH),
                  rows: widget.controller.rows,
                  cols: widget.controller.cols,
                  fullImage: widget.controller.decodedSourceImage,
                  showGhost: widget.controller.showGhost.value,
                  hintPieceKey: widget.controller.hintPieceKey.value,
                  backgroundStyle: bgStyle,
                  hintPulse: _pulseController.value,
                ),
              );
            },
          ),
        );
      },
    );
  }

  // --- Bottom Scrollable Piece Tray (Carousel Dock) ---
  Widget _buildBottomPieceTray(bool isLight, double renderW) {
    final screenScale = renderW / (widget.controller.boardW > 0 ? widget.controller.boardW : 750.0);

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          height: 140,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isLight
                  ? [const Color(0xF8FFFFFF), const Color(0xF2EAEFF5)]
                  : [const Color(0xF21E2838), const Color(0xF2101722)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isLight ? Colors.black.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.16),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: isLight ? Colors.black.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.50),
                blurRadius: 18,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Obx(() {
            final trayKeys = widget.controller.visibleTrayPieceKeys;

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Tray status header: remaining count + edges toggle + shuffle
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                  child: Row(
                    children: [
                      const Icon(Icons.extension_rounded, size: 14, color: AppTheme.accentAmber),
                      const SizedBox(width: 5),
                      Text(
                        '${trayKeys.length} pieces remaining',
                        style: TextStyle(
                          color: isLight ? const Color(0xFF4A5568) : Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      // Edges filter pill
                      InkWell(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          widget.controller.toggleEdges();
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: widget.controller.edgesOnly.value
                                ? AppTheme.accentAmber.withValues(alpha: 0.28)
                                : (isLight ? Colors.black.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.08)),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: widget.controller.edgesOnly.value
                                  ? AppTheme.accentAmber
                                  : (isLight ? Colors.black.withValues(alpha: 0.10) : Colors.white.withValues(alpha: 0.14)),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.crop_square_rounded,
                                size: 13,
                                color: widget.controller.edgesOnly.value
                                    ? AppTheme.accentAmber
                                    : (isLight ? const Color(0xFF4A5568) : Colors.white70),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Edges',
                                style: TextStyle(
                                  color: widget.controller.edgesOnly.value
                                      ? AppTheme.accentAmber
                                      : (isLight ? const Color(0xFF4A5568) : Colors.white70),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Shuffle button
                      InkWell(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          widget.controller.shuffleTrayPieces();
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: isLight ? Colors.black.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isLight ? Colors.black.withValues(alpha: 0.10) : Colors.white.withValues(alpha: 0.14),
                            ),
                          ),
                          child: Icon(
                            Icons.shuffle_rounded,
                            size: 14,
                            color: isLight ? const Color(0xFF4A5568) : Colors.white70,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),

                // Horizontal Carousel of Pure Jigsaw Pieces (No button cards!)
                Expanded(
                  child: trayKeys.isEmpty
                      ? Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.check_circle_rounded, color: AppTheme.accentAmber, size: 22),
                              const SizedBox(width: 8),
                              Text(
                                'All pieces assembled!',
                                style: TextStyle(
                                  color: isLight ? const Color(0xFF2D3748) : Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          // Half-inch gap (~28px) between pieces as requested
                          separatorBuilder: (_, __) => const SizedBox(width: 28),
                          itemCount: trayKeys.length,
                          itemBuilder: (context, index) {
                            final key = trayKeys[index];
                            final prePiece = widget.controller.preRenderedPieces[key];
                            if (prePiece == null) return const SizedBox.shrink();

                            final isHint = key == widget.controller.hintPieceKey.value;

                            // Feedback size matches the exact on-screen size of the board slot (1:1 scale)
                            final feedbackW = (widget.controller.pieceW + 2 * prePiece.margin) * screenScale;
                            final feedbackH = (widget.controller.pieceH + 2 * prePiece.margin) * screenScale;

                            // Tray resting display size: proportional to aspect ratio, height 72px
                            const trayH = 72.0;
                            final pieceAspect = (widget.controller.pieceW + 2 * prePiece.margin) /
                                (widget.controller.pieceH + 2 * prePiece.margin);
                            final trayW = (trayH * pieceAspect).clamp(52.0, 96.0);

                            return GestureDetector(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                if (widget.controller.hintPieceKey.value == key) {
                                  // Tapped again: auto snap directly to its slot!
                                  widget.controller.autoSnapPiece(key);
                                } else {
                                  // Select piece & highlight its exact target slot on the board!
                                  widget.controller.hintPieceKey.value = key;
                                }
                              },
                              onDoubleTap: () {
                                widget.controller.autoSnapPiece(key);
                              },
                              child: Draggable<String>(
                                data: key,
                                // CRITICAL: vertical affinity allows horizontal swipes to scroll the ListView!
                                affinity: Axis.vertical,
                                dragAnchorStrategy: (draggable, context, position) {
                                  return Offset(feedbackW / 2, feedbackH / 2);
                                },
                                feedback: Material(
                                  color: Colors.transparent,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: isLight ? 0.35 : 0.65),
                                          blurRadius: 18,
                                          offset: const Offset(0, 8),
                                        ),
                                      ],
                                    ),
                                    child: CustomPaint(
                                      size: Size(feedbackW, feedbackH),
                                      painter: _PieceCardPainter(prePiece: prePiece),
                                    ),
                                  ),
                                ),
                                childWhenDragging: Opacity(
                                  opacity: 0.18,
                                  child: SizedBox(
                                    width: trayW,
                                    height: trayH,
                                    child: CustomPaint(
                                      size: Size(trayW, trayH),
                                      painter: _PieceCardPainter(prePiece: prePiece),
                                    ),
                                  ),
                                ),
                                child: Container(
                                  width: trayW,
                                  height: trayH,
                                  alignment: Alignment.center,
                                  decoration: isHint
                                      ? BoxDecoration(
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: AppTheme.accentAmber.withValues(alpha: 0.60),
                                              blurRadius: 16,
                                              spreadRadius: 3,
                                            ),
                                          ],
                                        )
                                      : null,
                                  child: CustomPaint(
                                    size: Size(trayW, trayH),
                                    painter: _PieceCardPainter(prePiece: prePiece),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  // --- Floating Top HUD Bar ---
  Widget _buildFloatingTopBar(bool isLight, SettingsController settings) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: isLight ? const Color(0xF2FFFFFF) : const Color(0xE0131924),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isLight ? Colors.black.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.16),
            ),
            boxShadow: [
              BoxShadow(
                color: isLight ? Colors.black.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.35),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Circular Back Button
              Material(
                color: isLight ? Colors.black.withValues(alpha: 0.06) : Colors.white.withValues(alpha: 0.10),
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () {
                    HapticFeedback.lightImpact();
                    widget.onBack();
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(7),
                    child: Icon(
                      Icons.arrow_back_ios_new,
                      color: isLight ? const Color(0xFF2D3748) : Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Level Title & Mini Progress
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (widget.controller.currentSagaLevel != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.accentAmber.withValues(alpha: 0.22),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppTheme.accentAmber.withValues(alpha: 0.5)),
                            ),
                            child: Text(
                              'LVL ${widget.controller.currentSagaLevel}',
                              style: const TextStyle(
                                color: AppTheme.accentAmber,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        Flexible(
                          child: Text(
                            _getDisplayTitle(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: isLight ? const Color(0xFF1A202C) : Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Mini gold progress bar
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: widget.controller.actualPieceCount > 0
                                  ? widget.controller.lockedPieceKeys.length / widget.controller.actualPieceCount
                                  : 0,
                              minHeight: 5,
                              backgroundColor: isLight ? Colors.black12 : Colors.white12,
                              valueColor: const AlwaysStoppedAnimation(AppTheme.accentAmber),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${widget.controller.lockedPieceKeys.length}/${widget.controller.actualPieceCount}',
                          style: TextStyle(
                            color: isLight ? const Color(0xFF4A5568) : Colors.white70,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Timer chip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                decoration: BoxDecoration(
                  color: isLight ? Colors.black.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.timer_outlined,
                      size: 12,
                      color: isLight ? const Color(0xFF4A5568) : Colors.white70,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      _formatTime(widget.controller.elapsedSeconds.value),
                      style: TextStyle(
                        color: isLight ? const Color(0xFF1A202C) : Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),

              // Ghost Preview Toggle
              _buildTopIconButton(
                icon: widget.controller.showGhost.value
                    ? Icons.visibility_rounded
                    : Icons.visibility_off_outlined,
                isActive: widget.controller.showGhost.value,
                isLight: isLight,
                tooltip: 'Preview Ghost',
                onTap: () {
                  HapticFeedback.lightImpact();
                  widget.controller.toggleGhost();
                },
              ),
              const SizedBox(width: 6),

              // Free Hints Button
              Obx(() {
                final freeHints = settings.freeHints.value;
                return InkWell(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    _handleHintPress();
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppTheme.accentAmber.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.accentAmber.withValues(alpha: 0.6)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.lightbulb_rounded, color: AppTheme.accentAmber, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '$freeHints',
                          style: TextStyle(
                            color: isLight ? const Color(0xFF1A202C) : Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopIconButton({
    required IconData icon,
    required VoidCallback onTap,
    required bool isLight,
    String? tooltip,
    bool isActive = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: isActive
              ? AppTheme.accentAmber.withValues(alpha: 0.28)
              : (isLight ? Colors.black.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.08)),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isActive
                ? AppTheme.accentAmber
                : (isLight ? Colors.black.withValues(alpha: 0.10) : Colors.white.withValues(alpha: 0.12)),
          ),
        ),
        child: Icon(
          icon,
          color: isActive ? AppTheme.accentAmber : (isLight ? const Color(0xFF2D3748) : Colors.white),
          size: 17,
        ),
      ),
    );
  }

  void _handleHintPress() {
    final success = widget.controller.requestHint();
    if (!success) {
      _showOutOfHintsSheet();
    }
  }

  void _showOutOfHintsSheet() {
    final monetization = Get.find<MonetizationController>();
    final economy = Get.find<EconomyController>();

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Color(0xFF1B2332),
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.accentAmber.withValues(alpha: 0.22),
              ),
              child: const Icon(Icons.lightbulb_rounded, color: AppTheme.accentAmber, size: 34),
            ),
            const SizedBox(height: 14),
            const Text(
              'Need More Hints?',
              style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'You have used your 3 free hints! Watch a quick video to earn +1 Free Hint, or use coins.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentAmber,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                icon: const Icon(Icons.play_circle_filled_rounded),
                label: const Text('Watch Video for +1 Hint', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                onPressed: () {
                  Get.back();
                  monetization.showRewardedAd(
                    onRewardEarned: () {
                      widget.controller.triggerRewardedHint();
                      Get.snackbar(
                        'Hint Unlocked!',
                        '+1 Free Hint received!',
                        backgroundColor: const Color(0xDD000000),
                        colorText: Colors.white,
                        snackPosition: SnackPosition.BOTTOM,
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            if (economy.coins.value >= 15) ...[
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white24),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: const Icon(Icons.monetization_on, color: AppTheme.accentAmber),
                  label: const Text('Spend 15 Coins'),
                  onPressed: () {
                    Get.back();
                    if (economy.spendCoins(15)) {
                      widget.controller.triggerRewardedHint();
                    }
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String _getDisplayTitle() {
    if (widget.controller.isDaily) {
      return 'Daily Puzzle';
    }
    if (widget.controller.currentSagaLevel != null) {
      return 'Level ${widget.controller.currentSagaLevel}';
    }
    var title = widget.controller.pictureTitle;
    title = title.replaceAll(RegExp(r'\.(bpm|png|jpg|jpeg)$', caseSensitive: false), '').trim();
    if (RegExp(r'^[a-z]+[0-9]+$', caseSensitive: false).hasMatch(title)) {
      final numStr = title.replaceAll(RegExp(r'[^0-9]'), '').replaceFirst(RegExp(r'^0+'), '');
      return 'Level ${numStr.isEmpty ? "1" : numStr}';
    }
    return title.isNotEmpty ? title : 'Puzzle Level';
  }

  Widget _buildLoadingScreen(double progress) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F141B),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.accentAmber.withValues(alpha: 0.15),
                  border: Border.all(color: AppTheme.accentAmber.withValues(alpha: 0.4), width: 1.5),
                ),
                child: const Icon(Icons.extension, size: 54, color: AppTheme.accentAmber),
              ),
              const SizedBox(height: 24),
              const Text(
                'Cutting puzzle pieces...',
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 0.3),
              ),
              const SizedBox(height: 8),
              const Text(
                'Real tabs & blanks precision cut',
                style: TextStyle(color: Colors.white60, fontSize: 13),
              ),
              const SizedBox(height: 24),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 10,
                  backgroundColor: Colors.white12,
                  valueColor: const AlwaysStoppedAnimation(AppTheme.accentAmber),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '${(progress * 100).toInt()}%',
                style: const TextStyle(color: AppTheme.accentAmber, fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFF0F141B),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 56, color: Colors.redAccent),
            const SizedBox(height: 16),
            const Text(
              'Could not load puzzle',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentAmber,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              onPressed: widget.onBack,
              child: const Text('Back to Home', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}

class _PieceCardPainter extends CustomPainter {
  final PreRenderedPiece prePiece;

  _PieceCardPainter({required this.prePiece});

  @override
  void paint(Canvas canvas, Size size) {
    final srcRect = Rect.fromLTWH(0, 0, prePiece.image.width.toDouble(), prePiece.image.height.toDouble());
    final dstRect = Rect.fromLTWH(0, 0, size.width, size.height);
    final paint = Paint()..filterQuality = FilterQuality.high;
    canvas.drawImageRect(prePiece.image, srcRect, dstRect, paint);
  }

  @override
  bool shouldRepaint(covariant _PieceCardPainter oldDelegate) => false;
}
