import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:jigsaw_pro/core/audio/audio_service.dart';
import 'package:jigsaw_pro/core/config/app_config.dart';
import 'package:jigsaw_pro/core/haptics/haptic_service.dart';
import 'package:jigsaw_pro/core/widgets/casual_game_background.dart';
import 'package:jigsaw_pro/features/content/presentation/controllers/content_controller.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with TickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final AnimationController _pulseController;
  late final AnimationController _progressController;

  late final Animation<double> _fadeAnim;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _slideAnim;

  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();

    // 1. Smooth entrance animation (Fade + Gentle scale-up)
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _fadeAnim = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.0, 0.75, curve: Curves.easeOut),
    );

    _scaleAnim = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.9, curve: Curves.easeOutCubic),
      ),
    );

    _slideAnim = Tween<double>(begin: 18.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.1, 0.95, curve: Curves.easeOutCubic),
      ),
    );

    // 2. Gentle ambient glow breathing (Calm & premium, subtle pulse)
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    // 3. Smooth progress bar animation
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..forward();

    _entranceController.forward();

    // Play subtle tactile feedback on launch
    Future.delayed(const Duration(milliseconds: 250), () {
      if (mounted) {
        if (Get.isRegistered<AudioService>()) Get.find<AudioService>().playSnap();
        if (Get.isRegistered<HapticService>()) Get.find<HapticService>().light();
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _bootstrap();
    });
  }

  void _navigateToHome() {
    if (_hasNavigated || !mounted) return;
    _hasNavigated = true;
    context.go('/home');
  }

  Future<void> _bootstrap() async {
    // Guaranteed failsafe timer: maximum 1.6 seconds on splash
    Future.delayed(const Duration(milliseconds: 1600), () {
      if (mounted) _navigateToHome();
    });

    try {
      final content = Get.find<ContentController>();

      await Future.any([
        Future.wait([
          Future.delayed(const Duration(milliseconds: 950)),
          _waitForContentLoaded(content),
        ]),
        Future.delayed(const Duration(milliseconds: 1400)),
      ]);
    } catch (e) {
      debugPrint('Bootstrap notice: $e');
    }

    if (mounted) {
      _navigateToHome();
    }
  }

  Future<void> _waitForContentLoaded(ContentController content) async {
    while (content.isLoading.value) {
      await Future.delayed(const Duration(milliseconds: 80));
    }
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _pulseController.dispose();
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
                // Soft cinematic radial background glow
                Positioned.fill(
                  child: Center(
                    child: AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        final pulse = _pulseController.value;
                        return Container(
                          width: 320 + (pulse * 30),
                          height: 320 + (pulse * 30),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                const Color(0xFF38BDF8).withValues(alpha: 0.12 + (pulse * 0.05)),
                                const Color(0xFFFFB300).withValues(alpha: 0.05),
                                Colors.transparent,
                              ],
                              stops: const [0.0, 0.55, 1.0],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                // Main Content
                Center(
                  child: Obx(() {
                    if (content.errorMessage.isNotEmpty) {
                      return _buildErrorView(content);
                    }

                    return AnimatedBuilder(
                      animation: Listenable.merge([_entranceController, _pulseController]),
                      builder: (context, child) {
                        final pulse = _pulseController.value;
                        final subtleGlowScale = 1.0 + (pulse * 0.015);

                        return FadeTransition(
                          opacity: _fadeAnim,
                          child: Transform.translate(
                            offset: Offset(0, _slideAnim.value),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Spacer(flex: 3),

                                // Premium Glowing Game Logo Emblem
                                Transform.scale(
                                  scale: _scaleAnim.value * subtleGlowScale,
                                  child: _buildPremiumLogoEmblem(pulse),
                                ),

                                const SizedBox(height: 32),

                                // Sleek Game Title
                                _buildGameTitle(),

                                const SizedBox(height: 12),

                                // Refined Tagline Pill
                                _buildTaglinePill(),

                                const Spacer(flex: 3),

                                // Modern Sleek Progress Bar
                                _buildModernProgressBar(),

                                const SizedBox(height: 14),

                                // Loading Status Text
                                _buildLoadingStatusText(),

                                const Spacer(flex: 1),

                                // App Version Footer
                                Text(
                                  'v${AppConfig.appVersion} • Calm & Offline',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.5),
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: 0.8,
                                  ),
                                ),

                                const SizedBox(height: 16),
                              ],
                            ),
                          ),
                        );
                      },
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

  /// Premium Logo Emblem featuring the real `assets/jigsaw.logo.png`
  Widget _buildPremiumLogoEmblem(double pulse) {
    return Container(
      width: 175,
      height: 175,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(38),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1E3A5F),
            Color(0xFF10233B),
            Color(0xFF0A182A),
          ],
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.22 + (pulse * 0.12)),
          width: 2.2,
        ),
        boxShadow: [
          // Soft ambient outer glow
          BoxShadow(
            color: const Color(0xFF38BDF8).withValues(alpha: 0.25 + (pulse * 0.15)),
            offset: const Offset(0, 8),
            blurRadius: 28 + (pulse * 10),
            spreadRadius: 2,
          ),
          // Deep drop shadow
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            offset: const Offset(0, 16),
            blurRadius: 30,
          ),
          // Top light rim reflection
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.2),
            offset: const Offset(0, -2),
            blurRadius: 6,
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Gentle radial glow under the logo image
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFFFFD54F).withValues(alpha: 0.18),
                  Colors.transparent,
                ],
              ),
            ),
          ),

          // Official Game Logo
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Image.asset(
              'assets/jigsaw.logo.png',
              width: 130,
              height: 130,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                // Graceful fallback if image has issue
                return const Icon(
                  Icons.extension_rounded,
                  size: 80,
                  color: Color(0xFFFFB300),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Clean, modern game title typography
  Widget _buildGameTitle() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Colors.white, Color(0xFFE2E8F0)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ).createShader(bounds),
          child: const Text(
            'Jigsaw Puzzle',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
              color: Colors.white,
              shadows: [
                Shadow(
                  offset: Offset(0, 4),
                  blurRadius: 12,
                  color: Color(0x99000000),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 22,
              height: 1.5,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.transparent, const Color(0xFFFFB300).withValues(alpha: 0.7)],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                'PRO EDITION',
                style: TextStyle(
                  color: Color(0xFFFFB300),
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 4.0,
                  shadows: [
                    Shadow(
                      offset: Offset(0, 2),
                      blurRadius: 8,
                      color: Color(0x66FFB300),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              width: 22,
              height: 1.5,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [const Color(0xFFFFB300).withValues(alpha: 0.7), Colors.transparent],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Refined calm & offline tagline
  Widget _buildTaglinePill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Color(0xFF10B981),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Color(0xFF10B981),
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Calm & Offline Puzzle Experience',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  /// Modern sleek progress bar
  Widget _buildModernProgressBar() {
    return Container(
      width: 210,
      height: 5.5,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x44000000),
            offset: Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child: AnimatedBuilder(
        animation: _progressController,
        builder: (context, child) {
          final progress = _progressController.value.clamp(0.04, 1.0);
          return Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: progress,
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFFFD54F),
                      Color(0xFFFFB300),
                      Color(0xFFFF8F00),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFB300).withValues(alpha: 0.6),
                      blurRadius: 8,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Loading status text
  Widget _buildLoadingStatusText() {
    return AnimatedBuilder(
      animation: _progressController,
      builder: (context, child) {
        final progress = _progressController.value;
        String label = 'Loading puzzles...';
        if (progress > 0.7) {
          label = 'Starting journey...';
        } else if (progress > 0.4) {
          label = 'Preparing gallery...';
        }

        return Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.65),
            fontSize: 12,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.4,
          ),
        );
      },
    );
  }

  /// Clean error state with retry and skip
  Widget _buildErrorView(ContentController content) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.redAccent.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.info_outline_rounded,
              size: 44,
              color: Color(0xFFFF6B6B),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            content.errorMessage.value,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFB300),
                  foregroundColor: const Color(0xFF0E2A47),
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                ),
                onPressed: () {
                  content.loadContent();
                  _bootstrap();
                },
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Retry', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.4)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                ),
                onPressed: _navigateToHome,
                child: const Text('Continue', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
