import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:jigsaw_pro/core/audio/audio_service.dart';
import 'package:jigsaw_pro/core/config/app_config.dart';
import 'package:jigsaw_pro/core/haptics/haptic_service.dart';
import 'package:jigsaw_pro/core/widgets/casual_game_background.dart';
import 'package:jigsaw_pro/core/widgets/clay_container.dart';
import 'package:jigsaw_pro/features/content/presentation/controllers/content_controller.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with TickerProviderStateMixin {
  late final AnimationController _assembleController;
  late final AnimationController _breatheController;
  late final AnimationController _progressController;
  late final AnimationController _driftController;

  late final Animation<double> _assembleAnim;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();

    // 1. Tactile Clay Snap Animation (Assemble & Lock)
    _assembleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );

    _assembleAnim = CurvedAnimation(
      parent: _assembleController,
      curve: Curves.elasticOut,
    );

    _scaleAnim = Tween<double>(begin: 0.65, end: 1.0).animate(
      CurvedAnimation(
        parent: _assembleController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOutBack),
      ),
    );

    // 2. Clay Squash & Stretch Breathing Animation (Organic Clay Physics)
    _breatheController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    // 3. Floating Ambient Clay Confetti / Little Puzzle Pieces
    _driftController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    // 4. Smooth Puffy Progress Bar
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..forward();

    _assembleController.forward();

    // Play subtle tactile snap sound & haptic when clay pieces lock together
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) {
        if (Get.isRegistered<AudioService>()) Get.find<AudioService>().playSnap();
        if (Get.isRegistered<HapticService>()) Get.find<HapticService>().snap();
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _bootstrap();
    });
  }

  bool _hasNavigated = false;

  void _navigateToHome() {
    if (_hasNavigated || !mounted) return;
    _hasNavigated = true;
    context.go('/home');
  }

  Future<void> _bootstrap() async {
    try {
      final content = Get.find<ContentController>();

      await Future.any([
        Future.wait([
          Future.delayed(const Duration(milliseconds: 2200)),
          _waitForContentLoaded(content),
        ]),
        Future.delayed(const Duration(milliseconds: 2700)),
      ]);
    } catch (e) {
      debugPrint('Bootstrap notice: $e');
    }

    _navigateToHome();
  }

  Future<void> _waitForContentLoaded(ContentController content) async {
    while (content.isLoading.value) {
      await Future.delayed(const Duration(milliseconds: 80));
    }
  }

  @override
  void dispose() {
    _assembleController.dispose();
    _breatheController.dispose();
    _driftController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final content = Get.find<ContentController>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _navigateToHome,
        child: CasualGameBackground(
          child: SafeArea(
            child: Stack(
              children: [
                // 1. Floating Ambient 3D Clay Mini Elements
                _buildFloatingClayElements(),

                // 2. Main Content
                Center(
                  child: Obx(() {
                    if (content.errorMessage.isNotEmpty) {
                      return _buildErrorView(content);
                    }

                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Spacer(flex: 2),

                        // 3D Puffy Clay Puzzle Emblem (Squash & Stretch)
                        AnimatedBuilder(
                          animation: Listenable.merge([_assembleController, _breatheController]),
                          builder: (context, child) {
                            // Organic squash & stretch physics
                            final breathe = math.sin(_breatheController.value * math.pi);
                            final floatY = breathe * -8.0;
                            final squashX = 1.0 + (breathe * 0.04);
                            final squashY = 1.0 - (breathe * 0.035);

                            return Transform.translate(
                              offset: Offset(0, floatY),
                              child: Transform.scale(
                                scaleX: _scaleAnim.value * squashX,
                                scaleY: _scaleAnim.value * squashY,
                                child: _buildTactileClayHeroEmblem(),
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 36),

                        // 3D Clay Title Pill
                        _buildClayTitle(),

                        const SizedBox(height: 10),

                        // Clay Badge: "Offline Game • Relax & Play"
                        _buildClaySubtitleBadge(),

                        const Spacer(flex: 3),

                        // Puffy Clay Loading Progress Track
                        _buildClayProgressSection(),

                        const SizedBox(height: 18),

                        // Version Tag
                        Text(
                          'Version ${AppConfig.appVersion} • Calm & Offline',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.65),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),

                        const Spacer(flex: 1),
                      ],
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 3D Tactile Clay Puzzle Hero Emblem
  /// 4 Puffy, colorful, extruded clay interlocking pieces with soft inner highlights and deep bottom bevels!
  Widget _buildTactileClayHeroEmblem() {
    final assembleProgress = _assembleAnim.value;
    final explodeOffset = (1.0 - assembleProgress) * 45.0;

    return Container(
      width: 190,
      height: 190,
      decoration: BoxDecoration(
        color: const Color(0xFF132A4A),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 3),
        boxShadow: const [
          // Soft atmospheric deep shadow
          BoxShadow(
            color: Color(0x66081525),
            offset: Offset(0, 16),
            blurRadius: 32,
          ),
          // Top light rim
          BoxShadow(
            color: Color(0x33FFFFFF),
            offset: Offset(0, -3),
            blurRadius: 8,
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Piece 1: Top-Left (Sunlit Gold Clay)
          Transform.translate(
            offset: Offset(-explodeOffset - 38, -explodeOffset - 38),
            child: _buildClayPiece(
              color: const Color(0xFFFFB300),
              bevelColor: const Color(0xFFC67C00),
              icon: Icons.wb_sunny_rounded,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(28),
                topRight: Radius.circular(12),
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(20),
              ),
            ),
          ),

          // Piece 2: Top-Right (Sky Blue Clay)
          Transform.translate(
            offset: Offset(explodeOffset + 38, -explodeOffset - 38),
            child: _buildClayPiece(
              color: const Color(0xFF29B6F6),
              bevelColor: const Color(0xFF0277BD),
              icon: Icons.pets_rounded,
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(28),
                topLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
                bottomLeft: Radius.circular(20),
              ),
            ),
          ),

          // Piece 3: Bottom-Left (Mint Emerald Clay)
          Transform.translate(
            offset: Offset(-explodeOffset - 38, explodeOffset + 38),
            child: _buildClayPiece(
              color: const Color(0xFF00E676),
              bevelColor: const Color(0xFF00A152),
              icon: Icons.eco_rounded,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(28),
                topLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
                topRight: Radius.circular(20),
              ),
            ),
          ),

          // Piece 4: Bottom-Right (Coral Rose Clay)
          Transform.translate(
            offset: Offset(explodeOffset + 38, explodeOffset + 38),
            child: _buildClayPiece(
              color: const Color(0xFFFF5252),
              bevelColor: const Color(0xFFD32F2F),
              icon: Icons.palette_rounded,
              borderRadius: const BorderRadius.only(
                bottomRight: Radius.circular(28),
                topRight: Radius.circular(12),
                bottomLeft: Radius.circular(12),
                topLeft: Radius.circular(20),
              ),
            ),
          ),

          // Center Puffy Clay Locking Hub
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFF9C4), Color(0xFFFFD54F)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2.2),
              boxShadow: const [
                BoxShadow(
                  color: Color(0xFFB28704),
                  offset: Offset(0, 3.5),
                  blurRadius: 0,
                ),
                BoxShadow(
                  color: Color(0x55000000),
                  offset: Offset(0, 6),
                  blurRadius: 10,
                ),
              ],
            ),
            child: const Center(
              child: Icon(Icons.extension_rounded, size: 20, color: Color(0xFF5D4037)),
            ),
          ),
        ],
      ),
    );
  }

  /// Single Puffy 3D Clay Puzzle Piece
  Widget _buildClayPiece({
    required Color color,
    required Color bevelColor,
    required IconData icon,
    required BorderRadius borderRadius,
  }) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: color,
        borderRadius: borderRadius,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.alphaBlend(Colors.white.withValues(alpha: 0.35), color),
            color,
            Color.alphaBlend(Colors.black.withValues(alpha: 0.12), color),
          ],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1.8),
        boxShadow: [
          // 3D bottom bevel edge
          BoxShadow(
            color: bevelColor,
            offset: const Offset(0, 6),
            blurRadius: 0,
          ),
          // Soft outer drop shadow
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            offset: const Offset(0, 10),
            blurRadius: 14,
          ),
          // Top light reflection highlight
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.4),
            offset: const Offset(0, -1.5),
            blurRadius: 2,
          ),
        ],
      ),
      child: Center(
        child: Icon(
          icon,
          size: 30,
          color: Colors.white.withValues(alpha: 0.95),
          shadows: [
            Shadow(
              color: Colors.black.withValues(alpha: 0.25),
              offset: const Offset(0, 2),
              blurRadius: 3,
            ),
          ],
        ),
      ),
    );
  }

  /// 3D Claymorphic Bubble Title
  Widget _buildClayTitle() {
    return Column(
      children: [
        // "JIGSAW PUZZLE" in puffy 3D clay letters
        const Text(
          'Jigsaw Puzzle',
          style: TextStyle(
            color: Colors.white,
            fontSize: 36,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.0,
            shadows: [
              // Bottom 3D clay extrusion shadow
              Shadow(
                color: Color(0xFF091C36),
                offset: Offset(0, 4.5),
                blurRadius: 0,
              ),
              // Soft atmospheric drop shadow
              Shadow(
                color: Color(0x66000000),
                offset: Offset(0, 8),
                blurRadius: 16,
              ),
            ],
          ),
        ),
        const SizedBox(height: 2),
        // "PRO EDITION" with warm golden clay glow
        Text(
          'PRO EDITION',
          style: TextStyle(
            color: const Color(0xFFFFB300),
            fontSize: 18,
            fontWeight: FontWeight.w900,
            letterSpacing: 3.5,
            shadows: [
              Shadow(
                color: const Color(0xFF7F4B00).withValues(alpha: 0.8),
                offset: const Offset(0, 2.5),
                blurRadius: 0,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Clay Subtitle Badge
  Widget _buildClaySubtitleBadge() {
    return ClayContainer(
      color: const Color(0xFF163259),
      bevelColor: const Color(0xFF0B1B33),
      depth: 3.5,
      borderRadius: BorderRadius.circular(20),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.wifi_off_rounded, color: Color(0xFF00E676), size: 16),
          SizedBox(width: 8),
          Text(
            '100% Offline • Calm & Relaxing',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  /// Puffy Clay Progress Bar Section
  Widget _buildClayProgressSection() {
    return Column(
      children: [
        const Text(
          'Sculpting your puzzles...',
          style: TextStyle(
            color: Colors.white,
            fontSize: 13.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.4,
            shadows: [
              Shadow(color: Color(0xFF091C36), offset: Offset(0, 2), blurRadius: 0),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Indented 3D Clay Track
        Container(
          width: 230,
          height: 18,
          decoration: BoxDecoration(
            color: const Color(0xFF0B192C),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12), width: 1.5),
            boxShadow: const [
              // Inset sunken shadow feeling
              BoxShadow(
                color: Color(0x66000000),
                offset: Offset(0, 3),
                blurRadius: 4,
              ),
            ],
          ),
          padding: const EdgeInsets.all(2.5),
          child: AnimatedBuilder(
            animation: _progressController,
            builder: (context, child) {
              return FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: _progressController.value.clamp(0.05, 1.0),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFD54F), Color(0xFFFFB300), Color(0xFFFF8F00)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 1),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0xFFB26A00),
                        offset: Offset(0, 2),
                        blurRadius: 0,
                      ),
                      BoxShadow(
                        color: Color(0x44FFB300),
                        offset: Offset(0, 1),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// Floating 3D Mini Clay Shapes in the Background
  Widget _buildFloatingClayElements() {
    return AnimatedBuilder(
      animation: _driftController,
      builder: (context, child) {
        final t = _driftController.value;

        return IgnorePointer(
          child: Stack(
            children: [
              // Element 1: Yellow clay sphere top-left
              Positioned(
                left: 30 + math.sin(t * 2 * math.pi) * 12,
                top: 70 + math.cos(t * 2 * math.pi) * 14,
                child: _buildMiniClayBubble(26, const Color(0xFFFFB300), const Color(0xFFC67C00)),
              ),

              // Element 2: Cyan clay sphere top-right
              Positioned(
                right: 36 + math.cos(t * 2 * math.pi) * 14,
                top: 110 + math.sin(t * 2 * math.pi) * 12,
                child: _buildMiniClayBubble(34, const Color(0xFF29B6F6), const Color(0xFF0277BD)),
              ),

              // Element 3: Mint clay star bottom-left
              Positioned(
                left: 45 + math.cos(t * 2 * math.pi) * 10,
                bottom: 120 + math.sin(t * 2 * math.pi) * 16,
                child: _buildMiniClayBubble(28, const Color(0xFF00E676), const Color(0xFF00A152)),
              ),

              // Element 4: Rose clay pill bottom-right
              Positioned(
                right: 40 + math.sin(t * 2 * math.pi) * 12,
                bottom: 95 + math.cos(t * 2 * math.pi) * 14,
                child: _buildMiniClayBubble(24, const Color(0xFFFF5252), const Color(0xFFD32F2F)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMiniClayBubble(double size, Color color, Color bevel) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.alphaBlend(Colors.white.withValues(alpha: 0.4), color),
            color,
            Color.alphaBlend(Colors.black.withValues(alpha: 0.15), color),
          ],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: bevel,
            offset: const Offset(0, 3),
            blurRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            offset: const Offset(0, 6),
            blurRadius: 10,
          ),
        ],
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
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFB300),
                foregroundColor: const Color(0xFF0E2A47),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              ),
              onPressed: () {
                content.loadContent();
                _bootstrap();
              },
              child: const Text('Retry Loading', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 12),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white54),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              ),
              onPressed: _navigateToHome,
              child: const Text('Continue to Game', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ],
    );
  }
}
