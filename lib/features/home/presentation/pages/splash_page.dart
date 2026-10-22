import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:jigsaw_pro/core/config/app_config.dart';
import 'package:jigsaw_pro/core/widgets/casual_game_background.dart';
import 'package:jigsaw_pro/features/content/presentation/controllers/content_controller.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with TickerProviderStateMixin {
  late final AnimationController _assembleController;
  late final AnimationController _floatController;
  late final AnimationController _progressController;

  late final Animation<double> _slideAnim;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _opacityAnim;

  @override
  void initState() {
    super.initState();

    // 1. Pieces Assemble Animation (explode-in to lock together)
    _assembleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _slideAnim = CurvedAnimation(
      parent: _assembleController,
      curve: Curves.easeOutBack,
    );

    _scaleAnim = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _assembleController, curve: Curves.easeOutBack),
    );

    _opacityAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _assembleController, curve: const Interval(0.0, 0.4, curve: Curves.easeIn)),
    );

    // 2. Gentle Floating/Breathing Animation
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    // 3. Smooth progress bar fill
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..forward();

    _assembleController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _bootstrap();
    });
  }

  Future<void> _bootstrap() async {
    final content = Get.find<ContentController>();

    // Minimum splash duration so the user enjoys the animation
    final minSplashFuture = Future.delayed(const Duration(milliseconds: 2200));

    // Wait until content manifest is loaded
    while (content.isLoading.value) {
      await Future.delayed(const Duration(milliseconds: 100));
    }

    await minSplashFuture;

    if (!mounted) return;

    if (content.errorMessage.isNotEmpty) {
      return; // Error screen handles retry
    }

    // Safe transition to Home Page
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.go('/home');
      }
    });
  }

  @override
  void dispose() {
    _assembleController.dispose();
    _floatController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final content = Get.find<ContentController>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CasualGameBackground(
        child: SafeArea(
          child: Center(
            child: Obx(() {
              if (content.errorMessage.isNotEmpty) {
                return _buildErrorView(content);
              }

              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 2),

                  // 1. Central Animated Emblem with Nature, Animals, Flowers, Art Photos
                  AnimatedBuilder(
                    animation: Listenable.merge([_assembleController, _floatController]),
                    builder: (context, child) {
                      final floatOffset = math.sin(_floatController.value * math.pi) * 6.0;
                      return Transform.translate(
                        offset: Offset(0, floatOffset),
                        child: Transform.scale(
                          scale: _scaleAnim.value,
                          child: Opacity(
                            opacity: _opacityAnim.value,
                            child: _buildQuadJigsawEmblem(),
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 32),

                  // 2. Playful Casual Game Titles
                  const Text(
                    'Jigsaw Puzzle',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                      shadows: [
                        Shadow(
                          color: Color(0xFF0D2544),
                          offset: Offset(0, 3.5),
                          blurRadius: 0,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Offline Game',
                    style: TextStyle(
                      color: Color(0xFFFFC107),
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                      shadows: [
                        Shadow(
                          color: Color(0x664E342E),
                          offset: Offset(0, 2),
                          blurRadius: 0,
                        ),
                      ],
                    ),
                  ),

                  const Spacer(flex: 2),

                  // 3. Loading Puzzles Section
                  const Text(
                    'Loading puzzles...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Smooth Golden Amber Progress Capsule
                  Container(
                    width: 220,
                    height: 12,
                    decoration: BoxDecoration(
                      color: const Color(0xFF142B4E),
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x22000000),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: AnimatedBuilder(
                      animation: _progressController,
                      builder: (context, child) {
                        return FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: _progressController.value,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFFD54F), Color(0xFFFFB300)],
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 22),

                  // Version text at bottom
                  Text(
                    'Version ${AppConfig.appVersion}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.4,
                    ),
                  ),

                  const Spacer(flex: 1),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }

  /// 4 Interlocking Jigsaw quadrants with REAL photos for Nature, Animals, Flowers, and Art!
  Widget _buildQuadJigsawEmblem() {
    final slide = (1.0 - _slideAnim.value) * 24.0; // Distance pieces slide in from

    return Container(
      width: 172,
      height: 172,
      decoration: BoxDecoration(
        color: const Color(0xFF10233D),
        borderRadius: BorderRadius.circular(38),
        border: Border.all(color: const Color(0xFF1C3B63), width: 3.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x44081628),
            blurRadius: 22,
            offset: Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Stack(
          children: [
            // Top-Left: Nature Photo (Slide from top-left)
            Positioned(
              left: -slide,
              top: -slide,
              width: 72,
              height: 72,
              child: _buildQuadrantPiece(
                'assets/puzzles/nature/n001.bpm.jpg',
                const Color(0xFF4CAF50),
                BorderRadius.only(
                  topLeft: const Radius.circular(22),
                  topRight: const Radius.circular(8),
                  bottomLeft: const Radius.circular(8),
                  bottomRight: const Radius.circular(16),
                ),
              ),
            ),

            // Top-Right: Animals Photo (Slide from top-right)
            Positioned(
              right: -slide,
              top: -slide,
              width: 72,
              height: 72,
              child: _buildQuadrantPiece(
                'assets/puzzles/animals/a001.bmp',
                const Color(0xFFFF9800),
                BorderRadius.only(
                  topRight: const Radius.circular(22),
                  topLeft: const Radius.circular(8),
                  bottomRight: const Radius.circular(8),
                  bottomLeft: const Radius.circular(16),
                ),
              ),
            ),

            // Bottom-Left: Flowers Photo (Slide from bottom-left)
            Positioned(
              left: -slide,
              bottom: -slide,
              width: 72,
              height: 72,
              child: _buildQuadrantPiece(
                'assets/puzzles/flowers/f001.bpm.jpg',
                const Color(0xFFE91E63),
                BorderRadius.only(
                  bottomLeft: const Radius.circular(22),
                  topLeft: const Radius.circular(8),
                  bottomRight: const Radius.circular(8),
                  topRight: const Radius.circular(16),
                ),
              ),
            ),

            // Bottom-Right: Art Photo (Slide from bottom-right)
            Positioned(
              right: -slide,
              bottom: -slide,
              width: 72,
              height: 72,
              child: _buildQuadrantPiece(
                'assets/puzzles/art/art001.bmp',
                const Color(0xFF7E57C2),
                BorderRadius.only(
                  bottomRight: const Radius.circular(22),
                  topRight: const Radius.circular(8),
                  bottomLeft: const Radius.circular(8),
                  topLeft: const Radius.circular(16),
                ),
              ),
            ),

            // Center Interlocking Jigsaw Hub Accent
            Center(
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFB300),
                  shape: BoxShape.circle,
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x66000000),
                      blurRadius: 4,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(Icons.extension_rounded, size: 13, color: Color(0xFF0E2A47)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuadrantPiece(String imagePath, Color fallbackColor, BorderRadius radius) {
    return Container(
      decoration: BoxDecoration(
        color: fallbackColor,
        borderRadius: radius,
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 3,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Image.asset(
          imagePath,
          cacheWidth: 200,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: fallbackColor,
              child: const Center(
                child: Icon(Icons.extension, color: Colors.white, size: 28),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildErrorView(ContentController content) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.error_outline_rounded, size: 64, color: Colors.redAccent),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            content.errorMessage.value,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFFB300),
            foregroundColor: const Color(0xFF0E2A47),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          onPressed: () {
            content.loadContent();
            _bootstrap();
          },
          child: const Text('Retry Loading', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
