import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:jigsaw_pro/core/theme/app_theme.dart';
import 'package:jigsaw_pro/core/widgets/casual_game_background.dart';
import 'package:jigsaw_pro/core/widgets/clay_container.dart';
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
  final ScrollController _trayScrollController = ScrollController();
  late final AnimationController _pulseController;
  Worker? _hintWorker;
  Worker? _stateWorker;
  Timer? _previewTimer;
  bool _showInitialPreview = true;
  double _previewOpacity = 1.0;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);

    _hintWorker = ever(widget.controller.hintPieceKey, (key) {
      if (key != null && _trayScrollController.hasClients) {
        _trayScrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
      }
    });

    _stateWorker = ever(widget.controller.state, (state) {
      if (state == PuzzleState.playing && _showInitialPreview) {
        _startInitialPreviewTimer();
      }
    });

    if (widget.controller.state.value == PuzzleState.playing) {
      _startInitialPreviewTimer();
    }
  }

  void _startInitialPreviewTimer() {
    _previewTimer?.cancel();
    _previewTimer = Timer(const Duration(milliseconds: 2200), () {
      _dismissInitialPreview();
    });
  }

  void _dismissInitialPreview() {
    if (!_showInitialPreview || _previewOpacity == 0.0) return;
    _previewTimer?.cancel();
    if (!mounted) return;
    setState(() {
      _previewOpacity = 0.0;
    });
    Future.delayed(const Duration(milliseconds: 350), () {
      if (mounted) {
        setState(() {
          _showInitialPreview = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _previewTimer?.cancel();
    _stateWorker?.dispose();
    _hintWorker?.dispose();
    _trayScrollController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = Get.find<SettingsController>();

    return Obx(() {
      final state = widget.controller.state.value;

      if (state == PuzzleState.initial || state == PuzzleState.preparing) {
        return _buildLoadingScreen(widget.controller.prepareProgress.value);
      }

      if (state == PuzzleState.error) {
        return _buildErrorScreen();
      }

      final bgStyle = settings.boardBackground.value;
      final isLight = bgStyle == BoardBackgroundStyle.cleanLight;

      return Scaffold(
        backgroundColor: Colors.transparent,
        body: CasualGameBackground(
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Calculate responsive board dimensions
                final isDailyMode = widget.controller.isDaily;
                final hasTrayPieces = widget.controller.trayPieceKeys.isNotEmpty;
                final showTray = !isDailyMode && hasTrayPieces;
                final maxW = constraints.maxWidth - 16; // 8px margin each side
                final maxH = showTray
                    ? (constraints.maxHeight - 165) // Reserve for top HUD (~60px) + slim bottom tray (~95px)
                    : (constraints.maxHeight - 85); // Full vertical expansion when tray is empty or Daily!
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
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        child: Center(
                          child: SizedBox(
                            width: renderW,
                            height: renderH,
                            child: _buildBoardDropZone(renderW, renderH, bgStyle),
                          ),
                        ),
                      ),
                    ),

                    // 3. Bottom Scrollable Piece Tray (Only in Standard Mode when tray has pieces!)
                    if (showTray)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 2, 14, 14),
                        child: _buildBottomPieceTray(isLight, renderW),
                      )
                    else
                      const SizedBox(height: 10),
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
    final screenScale = renderW / (widget.controller.boardW > 0 ? widget.controller.boardW : 750.0);

    return DragTarget<String>(
      onWillAcceptWithDetails: (details) => true,
      onAcceptWithDetails: (details) {
        final box = _boardKey.currentContext?.findRenderObject() as RenderBox?;
        if (box != null) {
          final localDrop = box.globalToLocal(details.offset);
          final pieceKey = details.data;
          final prePiece = widget.controller.preRenderedPieces[pieceKey];
          if (prePiece == null) return;

          final feedbackW = (widget.controller.pieceW + 2 * prePiece.margin) * screenScale;
          final feedbackH = (widget.controller.pieceH + 2 * prePiece.margin) * screenScale;

          // localDrop is the top-left of the feedback widget on screen relative to the board
          final droppedCenterScreen = localDrop + Offset(feedbackW / 2, feedbackH / 2);

          // Convert screen drop center to virtual board coordinates
          final droppedCenter = Offset(
            droppedCenterScreen.dx / screenScale,
            droppedCenterScreen.dy / screenScale,
          );

          widget.controller.trySnapPiece(pieceKey, droppedCenter);
        }
      },
      builder: (context, candidateData, rejectedData) {
        return RepaintBoundary(
          key: _boardKey,
          child: SizedBox(
            width: renderW,
            height: renderH,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // 1. Board canvas: frame, mat, empty slots, and locked pieces
                Positioned.fill(
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
                          showGhost: false,
                          hintPieceKey: widget.controller.hintPieceKey.value,
                          backgroundStyle: bgStyle,
                          hintPulse: _pulseController.value,
                        ),
                      );
                    },
                  ),
                ),

                // 2. Unlocked pieces resting on the board (freely movable by user!)
                Obx(() {
                  final _ = widget.controller.boardPieceKeys.length;
                  final activeBoardKeys = widget.controller.boardPieceKeys.toList();
                  return Stack(
                    clipBehavior: Clip.none,
                    children: activeBoardKeys.map((key) {
                      final piece = widget.controller.pieces[key];
                      final prePiece = widget.controller.preRenderedPieces[key];
                      if (piece == null || prePiece == null) return const SizedBox.shrink();

                      final pieceScreenX = (piece.pos.dx - prePiece.margin) * screenScale;
                      final pieceScreenY = (piece.pos.dy - prePiece.margin) * screenScale;
                      final pieceW = (widget.controller.pieceW + 2 * prePiece.margin) * screenScale;
                      final pieceH = (widget.controller.pieceH + 2 * prePiece.margin) * screenScale;

                      final isHint = key == widget.controller.hintPieceKey.value;
                      final isSelected = widget.controller.isDaily && (key == widget.controller.selectedDailyPieceKey.value);

                      return Positioned(
                        left: pieceScreenX,
                        top: pieceScreenY,
                        width: pieceW,
                        height: pieceH,
                        child: Draggable<String>(
                          data: key,
                          dragAnchorStrategy: (draggable, context, position) {
                            return Offset(pieceW / 2, pieceH / 2);
                          },
                          feedback: Material(
                            color: Colors.transparent,
                            child: CustomPaint(
                              size: Size(pieceW, pieceH),
                              painter: _PieceCardPainter(prePiece: prePiece),
                            ),
                          ),
                          childWhenDragging: widget.controller.isDaily
                              ? Opacity(
                                  opacity: 0.35,
                                  child: CustomPaint(
                                    size: Size(pieceW, pieceH),
                                    painter: _PieceCardPainter(prePiece: prePiece),
                                  ),
                                )
                              : const SizedBox.shrink(),
                          child: GestureDetector(
                            onTap: widget.controller.isDaily
                                ? () => widget.controller.onDailyPieceTapped(key)
                                : null,
                            onDoubleTap: widget.controller.isDaily
                                ? null
                                : () => widget.controller.returnPieceToTray(key),
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Container(
                                  width: pieceW,
                                  height: pieceH,
                                  decoration: isSelected
                                      ? BoxDecoration(
                                          border: Border.all(color: const Color(0xFF00E5FF), width: 3),
                                          borderRadius: BorderRadius.circular(6),
                                          boxShadow: const [
                                            BoxShadow(
                                              color: Color(0x9900E5FF),
                                              blurRadius: 10,
                                              spreadRadius: 2,
                                            ),
                                          ],
                                        )
                                      : (isHint
                                          ? BoxDecoration(
                                              border: Border.all(color: const Color(0xFFFF9100), width: 3),
                                              borderRadius: BorderRadius.circular(6),
                                              boxShadow: const [
                                                BoxShadow(
                                                  color: Color(0x99FFA000),
                                                  blurRadius: 12,
                                                  spreadRadius: 2,
                                                ),
                                              ],
                                            )
                                          : null),
                                  child: CustomPaint(
                                    size: Size(pieceW, pieceH),
                                    painter: _PieceCardPainter(prePiece: prePiece),
                                  ),
                                ),
                                if (isHint)
                                  Positioned(
                                    top: -6,
                                    left: 0,
                                    right: 0,
                                    child: Center(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFF9100),
                                          borderRadius: BorderRadius.circular(8),
                                          boxShadow: const [
                                            BoxShadow(
                                              color: Colors.black26,
                                              blurRadius: 4,
                                              offset: Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: const Text(
                                          'THIS PIECE 👆',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 9,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  );
                }),

                // 3. Pre-Game Picture Preview Overlay (Shows full image for ~2s before scattering into pieces)
                if (_showInitialPreview)
                  Positioned.fill(
                    child: AnimatedOpacity(
                      opacity: _previewOpacity,
                      duration: const Duration(milliseconds: 350),
                      curve: Curves.easeOut,
                      child: GestureDetector(
                        onTap: _dismissInitialPreview,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.asset(
                                widget.controller.picturePath,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  color: const Color(0xFF1E293B),
                                  child: const Center(
                                    child: Icon(Icons.image_rounded, size: 48, color: Colors.white54),
                                  ),
                                ),
                              ),

                              // Bottom gradient shadow for readable badge
                              Positioned(
                                bottom: 0,
                                left: 0,
                                right: 0,
                                height: 68,
                                child: Container(
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [Colors.transparent, Color(0xD9000000)],
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                    ),
                                  ),
                                ),
                              ),

                              // Floating interactive pill: "Memorize Image • Tap to Start"
                              Positioned(
                                bottom: 12,
                                left: 16,
                                right: 16,
                                child: Center(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                                    decoration: BoxDecoration(
                                      color: const Color(0xEE0E2A47),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: const Color(0xFFFFB300), width: 1.5),
                                      boxShadow: const [
                                        BoxShadow(color: Color(0x40000000), blurRadius: 8, offset: Offset(0, 3)),
                                      ],
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.visibility_rounded, color: Color(0xFFFFB300), size: 16),
                                        SizedBox(width: 6),
                                        Text(
                                          'Memorize Image • Tap to Start',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 0.3,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- Bottom Scrollable Piece Tray (Claymorphic 3D Dock & Drop Target) ---
  Widget _buildBottomPieceTray(bool isLight, double renderW) {
    final screenScale = renderW / (widget.controller.boardW > 0 ? widget.controller.boardW : 750.0);

    return DragTarget<String>(
      onWillAcceptWithDetails: (details) => true,
      onAcceptWithDetails: (details) {
        widget.controller.returnPieceToTray(details.data);
      },
      builder: (context, candidateData, rejectedData) {
        return Obx(() {
          final trayKeys = widget.controller.trayPieceKeys;
          if (trayKeys.isEmpty) return const SizedBox.shrink();

          return ClayContainer(
            height: 92,
            padding: const EdgeInsets.symmetric(vertical: 4),
            color: Colors.white,
            depth: 4.5,
            bevelColor: candidateData.isNotEmpty ? const Color(0xFFFF8F00) : const Color(0xFFCBD5E1),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: candidateData.isNotEmpty ? const Color(0xFFFFB300) : Colors.white.withValues(alpha: 0.90),
              width: candidateData.isNotEmpty ? 2.5 : 1.2,
            ),
            child: ListView.separated(
              controller: _trayScrollController,
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemCount: trayKeys.length,
              itemBuilder: (context, index) {
                final key = trayKeys[index];
                final prePiece = widget.controller.preRenderedPieces[key];
                if (prePiece == null) return const SizedBox.shrink();

                final isHint = key == widget.controller.hintPieceKey.value;

                final feedbackW = (widget.controller.pieceW + 2 * prePiece.margin) * screenScale;
                final feedbackH = (widget.controller.pieceH + 2 * prePiece.margin) * screenScale;

                const trayH = 64.0;
                final pieceAspect = (widget.controller.pieceW + 2 * prePiece.margin) /
                    (widget.controller.pieceH + 2 * prePiece.margin);
                final trayW = (trayH * pieceAspect).clamp(46.0, 84.0);

                return Draggable<String>(
                  data: key,
                  affinity: Axis.vertical,
                  dragAnchorStrategy: (draggable, context, position) {
                    return Offset(feedbackW / 2, feedbackH / 2);
                  },
                  feedback: Material(
                    color: Colors.transparent,
                    child: CustomPaint(
                      size: Size(feedbackW, feedbackH),
                      painter: _PieceCardPainter(prePiece: prePiece),
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
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        width: trayW,
                        height: trayH,
                        alignment: Alignment.center,
                        decoration: isHint
                            ? BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFFFF9100), width: 3),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x99FFA000),
                                    blurRadius: 14,
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
                      if (isHint)
                        Positioned(
                          top: -6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF9100),
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Text(
                              'THIS PIECE 👆',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            )
          );
        });
      },
    );
  }

  // --- Floating Top HUD Bar (Claymorphic 3D Floating Pill) ---
  Widget _buildFloatingTopBar(bool isLight, SettingsController settings) {
    return ClayContainer(
      color: Colors.white,
      depth: 4.5,
      bevelColor: const Color(0xFFCBD5E1),
      borderRadius: BorderRadius.circular(24),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      border: Border.all(
        color: Colors.white.withValues(alpha: 0.90),
        width: 1.2,
      ),
        child: Row(
          children: [
            // Circular Back / Pause Button
            Material(
              color: const Color(0xFF16355C),
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () {
                  HapticFeedback.lightImpact();
                  _showPauseMenuDialog(context, settings);
                },
                child: const Padding(
                  padding: EdgeInsets.all(7),
                  child: Icon(
                    Icons.arrow_back_ios_new,
                    color: Colors.white,
                    size: 15,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),

            // Level Title & Mini Progress (Reactive with Obx)
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
                            color: const Color(0xFFFFF3E0),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFFFB300)),
                          ),
                          child: Text(
                            'LVL ${widget.controller.currentSagaLevel}',
                            style: const TextStyle(
                              color: Color(0xFFE65100),
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
                          style: const TextStyle(
                            color: Color(0xFF0E2A47),
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Mini gold progress bar (Reactive Obx)
                  Obx(() {
                    final locked = widget.controller.lockedPieceKeys.length;
                    final total = widget.controller.actualPieceCount;
                    return Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: total > 0 ? locked / total : 0,
                              minHeight: 5,
                              backgroundColor: const Color(0xFFECEFF1),
                              valueColor: const AlwaysStoppedAnimation(Color(0xFFFFB300)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$locked/$total',
                          style: const TextStyle(
                            color: Color(0xFF607D8B),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Timer chip (Reactive Obx - ticks every second)
            Obx(() => Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF3FB),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFCFD8DC)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.timer_outlined,
                    size: 13,
                    color: Color(0xFF0E2A47),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatTime(widget.controller.elapsedSeconds.value),
                    style: const TextStyle(
                      color: Color(0xFF0E2A47),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            )),
            const SizedBox(width: 8),

            // Preview Target Picture Button (Eye)
            ClayButton(
              onTap: _showPreviewDialog,
              padding: const EdgeInsets.all(7),
              borderRadius: BorderRadius.circular(14),
              depth: 3.5,
              color: Colors.white,
              bevelColor: const Color(0xFFCBD5E1),
              child: const Icon(Icons.visibility_rounded, color: Color(0xFF16355C), size: 16),
            ),
            const SizedBox(width: 8),

            // Free Hints Button (Claymorphic 3D press-down depth)
            Obx(() {
              final freeHints = settings.freeHints.value;
              return ClayButton(
                onTap: _handleHintPress,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                borderRadius: BorderRadius.circular(14),
                depth: 3.5,
                color: const Color(0xFFFFB300),
                bevelColor: const Color(0xFFD87C00),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.lightbulb_rounded, color: Color(0xFF3E2723), size: 16),
                    const SizedBox(width: 4),
                    Text(
                      freeHints > 0 ? '$freeHints' : '+ AD',
                      style: const TextStyle(
                        color: Color(0xFF3E2723),
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      );
    }

  void _handleHintPress() {
    final settings = Get.find<SettingsController>();
    if (settings.useFreeHint()) {
      widget.controller.triggerHintAnimation();
    } else {
      _showOutOfHintsSheet();
    }
  }

  void _showPreviewDialog() {
    HapticFeedback.lightImpact();
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF111E2E),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFFFB300), width: 1.5),
            boxShadow: const [
              BoxShadow(color: Color(0x66000000), blurRadius: 20, offset: Offset(0, 8)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.visibility_rounded, color: Color(0xFFFFB300), size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Target Picture',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  widget.controller.picturePath,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const SizedBox(
                    height: 180,
                    child: Center(
                      child: Icon(Icons.image_not_supported_rounded, color: Colors.white38, size: 40),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFB300),
                  foregroundColor: const Color(0xFF0E2A47),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  minimumSize: const Size(double.infinity, 42),
                ),
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Back to Solving', style: TextStyle(fontWeight: FontWeight.w900)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPauseMenuDialog(BuildContext context, SettingsController settings) {
    widget.controller.pauseTimer();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return PopScope(
          canPop: false,
          child: Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x350D2544),
                    blurRadius: 24,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Top Pause Badge
                  Container(
                    width: 66,
                    height: 66,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF29B6F6), Color(0xFF1E88E5)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1E88E5).withValues(alpha: 0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(Icons.pause_rounded, size: 38, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 14),

                  const Text(
                    'Game Paused',
                    style: TextStyle(
                      color: Color(0xFF0E2A47),
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_getDisplayTitle()} • ${widget.controller.lockedPieceKeys.length}/${widget.controller.actualPieceCount} Pieces',
                    style: const TextStyle(
                      color: Color(0xFF607D8B),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Quick Sound / Vibration Settings Row
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Obx(() {
                      final sound = settings.soundEnabled.value;
                      final vib = settings.vibrationEnabled.value;
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildSettingToggle(
                            icon: sound ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                            label: 'Sound',
                            isActive: sound,
                            onTap: settings.toggleSound,
                          ),
                          Container(width: 1, height: 32, color: const Color(0xFFCBD5E1)),
                          _buildSettingToggle(
                            icon: vib ? Icons.vibration_rounded : Icons.smartphone_rounded,
                            label: 'Haptics',
                            isActive: vib,
                            onTap: settings.toggleVibration,
                          ),
                        ],
                      );
                    }),
                  ),
                  const SizedBox(height: 20),

                  // Big 3D Tactile Claymorphic RESUME Button
                  ClayButton(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.pop(ctx);
                      widget.controller.resumeTimer();
                    },
                    width: double.infinity,
                    height: 52,
                    depth: 4.5,
                    borderRadius: BorderRadius.circular(26),
                    color: const Color(0xFFFFB300),
                    bevelColor: const Color(0xFFD87C00),
                    child: const Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.play_arrow_rounded, color: Color(0xFF3E2723), size: 28),
                          SizedBox(width: 6),
                          Text(
                            'RESUME',
                            style: TextStyle(
                              color: Color(0xFF3E2723),
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Restart Puzzle Button
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF0E2A47),
                      side: const BorderSide(color: Color(0xFFCFD8DC), width: 1.5),
                      minimumSize: const Size(double.infinity, 46),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(23)),
                    ),
                    icon: const Icon(Icons.refresh_rounded, size: 20, color: Color(0xFF0E2A47)),
                    label: const Text(
                      'Restart Puzzle',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                    ),
                    onPressed: () {
                      _showRestartConfirmation(ctx);
                    },
                  ),
                  const SizedBox(height: 8),

                  // Back to Home Button
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF546E7A),
                      minimumSize: const Size(double.infinity, 42),
                    ),
                    icon: const Icon(Icons.home_rounded, size: 20),
                    label: const Text(
                      'Exit to Home',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      widget.onBack();
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showRestartConfirmation(BuildContext parentCtx) {
    showDialog(
      context: parentCtx,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text(
          'Restart Puzzle?',
          style: TextStyle(color: Color(0xFF0E2A47), fontWeight: FontWeight.w900, fontSize: 18),
        ),
        content: const Text(
          'All placed pieces will be returned to the tray. Are you sure?',
          style: TextStyle(color: Color(0xFF546E7A), fontSize: 13.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF78909C))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFB300),
              foregroundColor: const Color(0xFF0E2A47),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(parentCtx);
              widget.controller.restartPuzzle();
            },
            child: const Text('Restart', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingToggle({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 20,
            color: isActive ? const Color(0xFF1E88E5) : const Color(0xFF90A4AE),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: isActive ? const Color(0xFF0E2A47) : const Color(0xFF90A4AE),
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  void _showOutOfHintsSheet() {
    final monetization = Get.find<MonetizationController>();
    final economy = Get.find<EconomyController>();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(color: Color(0x350D2544), blurRadius: 20, offset: Offset(0, -6)),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(22, 16, 22, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top drag indicator
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFCFD8DC),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(height: 18),

              // Lightbulb / Coins icon
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFD54F), Color(0xFFFFB300)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF8F00).withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(Icons.lightbulb_rounded, color: Colors.white, size: 36),
                ),
              ),
              const SizedBox(height: 14),

              const Text(
                'Need More Hints or Coins?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF0E2A47),
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Watch a video ad to get a free hint, earn +30 coins, or visit the coin shop!',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF607D8B), fontSize: 13, height: 1.3),
              ),
              const SizedBox(height: 20),

              // Option 1: Watch Video for +1 Free Hint
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFB300),
                  foregroundColor: const Color(0xFF0E2A47),
                  minimumSize: const Size(double.infinity, 50),
                  elevation: 3,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                ),
                icon: const Icon(Icons.ondemand_video_rounded, size: 22),
                label: const Text('Watch Video for +1 Hint', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                onPressed: () {
                  Navigator.pop(ctx);
                  monetization.showRewardedAd(
                    context: context,
                    rewardTitle: '+1 Free Hint',
                    onRewardEarned: () {
                      widget.controller.triggerRewardedHint();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('+1 Free Hint received!'),
                          backgroundColor: const Color(0xEE112238),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 10),

              // Option 2: Watch Video for +30 Coins
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF0E2A47),
                  side: const BorderSide(color: Color(0xFFFFB300), width: 1.8),
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                ),
                icon: const Icon(Icons.monetization_on_rounded, color: Color(0xFFFF8F00), size: 22),
                label: const Text('Watch Video for +30 Coins', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                onPressed: () {
                  Navigator.pop(ctx);
                  monetization.showRewardedAd(
                    context: context,
                    rewardTitle: '+30 Coins',
                    onRewardEarned: () {
                      economy.addCoins(30);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('+30 coins added to your stash!'),
                          backgroundColor: const Color(0xEE112238),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 10),

              // Option 3: If coins >= 15, spend 15 coins
              Obx(() {
                final c = economy.coins.value;
                if (c >= 15) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF0E2A47),
                        side: const BorderSide(color: Color(0xFFCFD8DC), width: 1.5),
                        minimumSize: const Size(double.infinity, 46),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      ),
                      icon: const Text('🪙', style: TextStyle(fontSize: 16)),
                      label: Text('Use 15 Coins ($c available)', style: const TextStyle(fontWeight: FontWeight.w800)),
                      onPressed: () {
                        Navigator.pop(ctx);
                        if (economy.spendCoins(15)) {
                          widget.controller.triggerRewardedHint();
                        }
                      },
                    ),
                  );
                }
                return const SizedBox.shrink();
              }),

              // Option 4: Visit Shop
              TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF16355C),
                  minimumSize: const Size(double.infinity, 40),
                ),
                icon: const Icon(Icons.shopping_bag_rounded, size: 18),
                label: const Text('Visit Coin Shop', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                onPressed: () {
                  Navigator.pop(ctx);
                  context.push('/shop');
                },
              ),
            ],
          ),
        );
      },
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
      backgroundColor: Colors.transparent,
      body: CasualGameBackground(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x2E0D2544),
                    blurRadius: 20,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFD54F), Color(0xFFFFB300)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF8F00).withValues(alpha: 0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(Icons.extension_rounded, size: 42, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Preparing Puzzle...',
                    style: TextStyle(
                      color: Color(0xFF0E2A47),
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Precision cutting tabs & blanks',
                    style: TextStyle(
                      color: Color(0xFF607D8B),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 10,
                      backgroundColor: const Color(0xFFECEFF1),
                      valueColor: const AlwaysStoppedAnimation(Color(0xFFFFB300)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${(progress * 100).toInt()}%',
                    style: const TextStyle(
                      color: Color(0xFF0E2A47),
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorScreen() {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CasualGameBackground(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x2E0D2544),
                    blurRadius: 20,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFFFEBEE),
                      border: Border.all(color: const Color(0xFFFFCDD2), width: 2),
                    ),
                    child: const Center(
                      child: Icon(Icons.error_outline_rounded, size: 40, color: Color(0xFFE53935)),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Could not load puzzle',
                    style: TextStyle(
                      color: Color(0xFF0E2A47),
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Please try again or select another image.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFF607D8B), fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 22),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFB300),
                      foregroundColor: const Color(0xFF0E2A47),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      elevation: 3,
                    ),
                    onPressed: widget.onBack,
                    child: const Text('Back to Home', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                  ),
                ],
              ),
            ),
          ),
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
