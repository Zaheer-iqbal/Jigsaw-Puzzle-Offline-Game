import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:jigsaw_pro/core/config/app_config.dart';
import 'package:jigsaw_pro/core/storage/hive_storage.dart';
import 'package:jigsaw_pro/core/theme/app_theme.dart';
import 'package:jigsaw_pro/core/widgets/casual_game_background.dart';
import 'package:jigsaw_pro/core/widgets/clay_container.dart';
import 'package:jigsaw_pro/features/settings/presentation/controllers/settings_controller.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Get.find<SettingsController>();

    return Obx(() {
      // Force rebuild on theme change so colors immediately update
      final _ = settings.themeModeString.value;
      final isDark = Theme.of(context).brightness == Brightness.dark;

      final cardBg = isDark ? const Color(0xFF132238) : Colors.white;
      final cardBevel = isDark ? const Color(0xFF091322) : const Color(0xFFCBD5E1);
      final titleColor = isDark ? Colors.white : const Color(0xFF0E2A47);
      final subtitleColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
      final dividerColor = isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFF0F4F8);

      return Scaffold(
        backgroundColor: Colors.transparent,
        body: CasualGameBackground(
          child: SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 8),
                _buildTopBar(context),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    children: [
                      // 1. Audio & Haptics Clay Card
                      ClayContainer(
                        color: cardBg,
                        depth: 4.5,
                        bevelColor: cardBevel,
                        borderRadius: BorderRadius.circular(24),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Column(
                          children: [
                            // Sound FX
                            _buildSwitchTile(
                              icon: Icons.volume_up_rounded,
                              iconColor: const Color(0xFF00B0FF),
                              title: 'Sound Effects',
                              subtitle: 'Puzzle snap and click sounds',
                              value: settings.soundEnabled.value,
                              onChanged: (_) {
                                HapticFeedback.lightImpact();
                                settings.toggleSound();
                              },
                              titleColor: titleColor,
                              subtitleColor: subtitleColor,
                            ),
                            Divider(height: 1, indent: 56, endIndent: 18, color: dividerColor),
                            // Background Music
                            _buildSwitchTile(
                              icon: Icons.music_note_rounded,
                              iconColor: const Color(0xFFFF9100),
                              title: 'Background Music',
                              subtitle: 'Calm ambient puzzle music',
                              value: settings.musicEnabled.value,
                              onChanged: (_) {
                                HapticFeedback.lightImpact();
                                settings.toggleMusic();
                              },
                              titleColor: titleColor,
                              subtitleColor: subtitleColor,
                            ),
                            Divider(height: 1, indent: 56, endIndent: 18, color: dividerColor),
                            // Haptics / Vibration
                            _buildSwitchTile(
                              icon: Icons.vibration_rounded,
                              iconColor: const Color(0xFF00E676),
                              title: 'Haptic Feedback',
                              subtitle: 'Vibrations on piece snaps',
                              value: settings.vibrationEnabled.value,
                              onChanged: (_) {
                                HapticFeedback.lightImpact();
                                settings.toggleVibration();
                              },
                              titleColor: titleColor,
                              subtitleColor: subtitleColor,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 2. Theme Card (Light / Dark / System 3D Tactile Pills)
                      ClayContainer(
                        color: cardBg,
                        depth: 4.5,
                        bevelColor: cardBevel,
                        borderRadius: BorderRadius.circular(24),
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.palette_rounded, color: Color(0xFFFFB300), size: 22),
                                const SizedBox(width: 8),
                                Text(
                                  'App Theme',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 16,
                                    color: titleColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildThemePill(
                                    label: 'Light',
                                    icon: Icons.wb_sunny_rounded,
                                    value: 'light',
                                    current: settings.themeModeString.value,
                                    settings: settings,
                                    isDark: isDark,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _buildThemePill(
                                    label: 'Dark',
                                    icon: Icons.nightlight_round,
                                    value: 'dark',
                                    current: settings.themeModeString.value,
                                    settings: settings,
                                    isDark: isDark,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _buildThemePill(
                                    label: 'System',
                                    icon: Icons.brightness_auto_rounded,
                                    value: 'system',
                                    current: settings.themeModeString.value,
                                    settings: settings,
                                    isDark: isDark,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 3. Board Background Swatch Card (6 Options)
                      ClayContainer(
                        color: cardBg,
                        depth: 4.5,
                        bevelColor: cardBevel,
                        borderRadius: BorderRadius.circular(24),
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.dashboard_customize_rounded, color: Color(0xFF26A69A), size: 22),
                                const SizedBox(width: 8),
                                Text(
                                  'Board Background',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 16,
                                    color: titleColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Obx(() {
                              final currentBg = settings.boardBackground.value;
                              final styles = [
                                BoardBackgroundStyle.teal,
                                BoardBackgroundStyle.midnightNavy,
                                BoardBackgroundStyle.feltGreen,
                                BoardBackgroundStyle.classicWood,
                                BoardBackgroundStyle.royalPurple,
                                BoardBackgroundStyle.cleanLight,
                              ];
                              return Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: styles.map((st) {
                                  final isSelected = currentBg == st;
                                  return GestureDetector(
                                    onTap: () {
                                      HapticFeedback.lightImpact();
                                      settings.setBoardBackground(st);
                                    },
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: isSelected
                                            ? Border.all(color: const Color(0xFFFFB300), width: 3.5)
                                            : Border.all(
                                                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                                                width: 2,
                                              ),
                                        boxShadow: [
                                          if (isSelected)
                                            BoxShadow(
                                              color: const Color(0xFFFFB300).withValues(alpha: 0.50),
                                              blurRadius: 10,
                                              offset: const Offset(0, 3),
                                            ),
                                        ],
                                      ),
                                      padding: const EdgeInsets.all(2.5),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: st.primaryColor,
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              );
                            }),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Section Header: About & Privacy
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          'About & Privacy',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            shadows: [
                              Shadow(color: Color(0xFF0D2544), offset: Offset(0, 2), blurRadius: 0),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // 4. About & Privacy Card
                      ClayContainer(
                        color: cardBg,
                        depth: 4.5,
                        bevelColor: cardBevel,
                        borderRadius: BorderRadius.circular(24),
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Column(
                          children: [
                            // About Jigsaw Pro
                            ListTile(
                              leading: _buildIconBubble(Icons.info_rounded, const Color(0xFF00BCD4)),
                              title: Text('About Jigsaw Pro', style: TextStyle(fontWeight: FontWeight.w800, color: titleColor)),
                              subtitle: Text('Version ${AppConfig.appVersion} • Features & Offline Philosophy', style: TextStyle(color: subtitleColor, fontSize: 12)),
                              trailing: Icon(Icons.arrow_forward_ios_rounded, size: 15, color: subtitleColor),
                              onTap: () {
                                if (Get.isRegistered<HapticService>()) Get.find<HapticService>().click();
                                if (Get.isRegistered<AudioService>()) Get.find<AudioService>().playClick();
                                _showAboutDialog(context, isDark);
                              },
                            ),
                            Divider(height: 1, indent: 56, endIndent: 16, color: dividerColor),

                            // Privacy Policy
                            ListTile(
                              leading: _buildIconBubble(Icons.privacy_tip_rounded, const Color(0xFF1E88E5)),
                              title: Text('Privacy Policy', style: TextStyle(fontWeight: FontWeight.w800, color: titleColor)),
                              subtitle: Text('Zero personal data tracking & 100% offline', style: TextStyle(color: subtitleColor, fontSize: 12)),
                              trailing: Icon(Icons.arrow_forward_ios_rounded, size: 15, color: subtitleColor),
                              onTap: () {
                                if (Get.isRegistered<HapticService>()) Get.find<HapticService>().click();
                                if (Get.isRegistered<AudioService>()) Get.find<AudioService>().playClick();
                                _showPrivacyPolicy(context, isDark);
                              },
                            ),
                            Divider(height: 1, indent: 56, endIndent: 16, color: dividerColor),

                            // Terms of Service
                            ListTile(
                              leading: _buildIconBubble(Icons.description_rounded, const Color(0xFFFF9800)),
                              title: Text('Terms of Service', style: TextStyle(fontWeight: FontWeight.w800, color: titleColor)),
                              subtitle: Text('Fair offline play & game guidelines', style: TextStyle(color: subtitleColor, fontSize: 12)),
                              trailing: Icon(Icons.arrow_forward_ios_rounded, size: 15, color: subtitleColor),
                              onTap: () => _showTermsOfService(context, isDark),
                            ),
                            Divider(height: 1, indent: 56, endIndent: 16, color: dividerColor),

                            // Data & Ad Consent (GDPR / CCPA)
                            ListTile(
                              leading: _buildIconBubble(Icons.security_rounded, const Color(0xFF00C853)),
                              title: Text('Data & Ad Consent (GDPR)', style: TextStyle(fontWeight: FontWeight.w800, color: titleColor)),
                              subtitle: Text('Manage your advertising preferences', style: TextStyle(color: subtitleColor, fontSize: 12)),
                              trailing: Icon(Icons.arrow_forward_ios_rounded, size: 15, color: subtitleColor),
                              onTap: () => _showConsentManagement(context, isDark),
                            ),
                            Divider(height: 1, indent: 56, endIndent: 16, color: dividerColor),

                            // Contact Support & Feedback
                            ListTile(
                              leading: _buildIconBubble(Icons.headset_mic_rounded, const Color(0xFF9C27B0)),
                              title: Text('Contact Support & Feedback', style: TextStyle(fontWeight: FontWeight.w800, color: titleColor)),
                              subtitle: Text('Suggestions or need help? Reach out', style: TextStyle(color: subtitleColor, fontSize: 12)),
                              trailing: Icon(Icons.arrow_forward_ios_rounded, size: 15, color: subtitleColor),
                              onTap: () => _showSupportDialog(context, isDark),
                            ),
                            Divider(height: 1, indent: 56, endIndent: 16, color: dividerColor),

                            // Reset All Game Data (GDPR Right to Erasure)
                            ListTile(
                              leading: _buildIconBubble(Icons.delete_forever_rounded, const Color(0xFFE53935)),
                              title: const Text(
                                'Reset All Game Data',
                                style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFFE53935)),
                              ),
                              subtitle: Text('Clear progress, coins & start fresh', style: TextStyle(color: subtitleColor, fontSize: 12)),
                              trailing: Icon(Icons.arrow_forward_ios_rounded, size: 15, color: subtitleColor),
                              onTap: () => _showResetDataDialog(context, settings, isDark),
                            ),
                            Divider(height: 1, indent: 56, endIndent: 16, color: dividerColor),

                            // App Version
                            ListTile(
                              leading: _buildIconBubble(Icons.info_outline_rounded, const Color(0xFF00897B)),
                              title: Text('Version', style: TextStyle(fontWeight: FontWeight.w800, color: titleColor)),
                              subtitle: Text(
                                '${AppConfig.appName} v${AppConfig.appVersion} (Offline Edition)',
                                style: TextStyle(color: subtitleColor, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildIconBubble(IconData icon, Color color) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required Color titleColor,
    required Color subtitleColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          _buildIconBubble(icon, iconColor),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15.5,
                    color: titleColor,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: subtitleColor,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            activeTrackColor: const Color(0xFF00E676),
            activeThumbColor: Colors.white,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildThemePill({
    required String label,
    required IconData icon,
    required String value,
    required String current,
    required SettingsController settings,
    required bool isDark,
  }) {
    final isSelected = current == value;
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        settings.setThemeMode(value);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 44,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: isSelected
              ? const LinearGradient(
                  colors: [
                    Color(0xFFFFCA28),
                    Color(0xFFFFA000),
                    Color(0xFFFF8F00),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                )
              : null,
          color: isSelected
              ? null
              : (isDark ? const Color(0xFF1E2D44) : const Color(0xFFEEF3FB)),
          border: isSelected
              ? Border.all(color: Colors.white.withValues(alpha: 0.6), width: 1.2)
              : Border.all(
                  color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.transparent,
                  width: 1,
                ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFFD87C00).withValues(alpha: 0.85),
                    offset: const Offset(0, 3),
                    blurRadius: 0,
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected
                  ? const Color(0xFF3E2723)
                  : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? const Color(0xFF3E2723)
                    : (isDark ? Colors.white : const Color(0xFF0E2A47)),
                fontWeight: FontWeight.w900,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Circular Back Button
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/home');
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
          const SizedBox(width: 16),
          const Text(
            'Settings',
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w900,
              shadows: [
                Shadow(color: Color(0xFF0D2544), offset: Offset(0, 3), blurRadius: 0),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Professional Dialogs & Bottom Sheets ---

  void _showAboutDialog(BuildContext context, bool isDark) {
    final sheetBg = isDark ? const Color(0xFF101B2B) : Colors.white;
    final cardBg = isDark ? const Color(0xFF16253B) : const Color(0xFFF8FAFC);
    final borderColor = isDark ? Colors.white12 : const Color(0xFFE2E8F0);
    final titleColor = isDark ? Colors.white : const Color(0xFF0E2A47);
    final subColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
        decoration: BoxDecoration(
          color: sheetBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          boxShadow: const [
            BoxShadow(color: Color(0x66000000), blurRadius: 28, offset: Offset(0, -8)),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(22, 14, 22, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Header Banner
            Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00BCD4), Color(0xFF1E88E5)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: const [
                      BoxShadow(color: Color(0x4000BCD4), blurRadius: 12, offset: Offset(0, 4)),
                    ],
                  ),
                  child: const Center(
                    child: Icon(Icons.extension_rounded, color: Colors.white, size: 30),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Jigsaw Pro: Offline Game',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: titleColor),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00E676).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'v1.0.0 Pro',
                              style: TextStyle(color: Color(0xFF00C853), fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Calm & Casual Experience',
                            style: TextStyle(fontSize: 12, color: subColor, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(ctx),
                  icon: Icon(Icons.close_rounded, color: subColor),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Divider(height: 1, color: borderColor),
            const SizedBox(height: 16),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    _buildFeatureCard(
                      icon: Icons.wifi_off_rounded,
                      iconColor: const Color(0xFF00BCD4),
                      title: '100% Offline Gaming',
                      description: 'No internet connection, mobile data, or account login is ever needed. Play peacefully anywhere anytime.',
                      cardBg: cardBg,
                      borderColor: borderColor,
                      titleColor: titleColor,
                      subColor: subColor,
                    ),
                    const SizedBox(height: 10),
                    _buildFeatureCard(
                      icon: Icons.money_off_rounded,
                      iconColor: const Color(0xFF00E676),
                      title: 'Zero In-App Payments',
                      description: 'All puzzles, themes, and coin packs are 100% free! No credit cards or real money purchases exist in the app.',
                      cardBg: cardBg,
                      borderColor: borderColor,
                      titleColor: titleColor,
                      subColor: subColor,
                    ),
                    const SizedBox(height: 10),
                    _buildFeatureCard(
                      icon: Icons.auto_awesome_rounded,
                      iconColor: const Color(0xFFFFB300),
                      title: 'Calming Atmosphere',
                      description: 'Smooth soothing background melodies, crisp tactile sound effects, and gentle haptic feedback for relaxation.',
                      cardBg: cardBg,
                      borderColor: borderColor,
                      titleColor: titleColor,
                      subColor: subColor,
                    ),
                    const SizedBox(height: 10),
                    _buildFeatureCard(
                      icon: Icons.shield_rounded,
                      iconColor: const Color(0xFF7E57C2),
                      title: 'Privacy Guaranteed',
                      description: 'Your game saves, coins, and high scores stay strictly on your device. We respect your complete digital privacy.',
                      cardBg: cardBg,
                      borderColor: borderColor,
                      titleColor: titleColor,
                      subColor: subColor,
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFB300),
                foregroundColor: const Color(0xFF0E2A47),
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 3,
              ),
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Awesome!', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
            ),
          ],
        ),
      ),
    );
  }

  void _showPrivacyPolicy(BuildContext context, bool isDark) {
    final sheetBg = isDark ? const Color(0xFF101B2B) : Colors.white;
    final cardBg = isDark ? const Color(0xFF16253B) : const Color(0xFFF8FAFC);
    final borderColor = isDark ? Colors.white12 : const Color(0xFFE2E8F0);
    final titleColor = isDark ? Colors.white : const Color(0xFF0E2A47);
    final subColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
        decoration: BoxDecoration(
          color: sheetBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          boxShadow: const [
            BoxShadow(color: Color(0x66000000), blurRadius: 28, offset: Offset(0, -8)),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(22, 14, 22, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 18),

            Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1E88E5), Color(0xFF43A047)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: const [
                      BoxShadow(color: Color(0x401E88E5), blurRadius: 12, offset: Offset(0, 4)),
                    ],
                  ),
                  child: const Center(
                    child: Icon(Icons.privacy_tip_rounded, color: Colors.white, size: 28),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Privacy Policy',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: titleColor),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Zero Tracking • Local Storage First',
                        style: TextStyle(fontSize: 12, color: subColor, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(ctx),
                  icon: Icon(Icons.close_rounded, color: subColor),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Divider(height: 1, color: borderColor),
            const SizedBox(height: 16),

            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    _buildFeatureCard(
                      icon: Icons.person_off_rounded,
                      iconColor: const Color(0xFF1E88E5),
                      title: 'Zero Personal Data Collection',
                      description: 'No names, phone numbers, email addresses, or contacts are ever requested or collected.',
                      cardBg: cardBg,
                      borderColor: borderColor,
                      titleColor: titleColor,
                      subColor: subColor,
                    ),
                    const SizedBox(height: 10),
                    _buildFeatureCard(
                      icon: Icons.storage_rounded,
                      iconColor: const Color(0xFF00C853),
                      title: 'Local Device Storage',
                      description: 'All your puzzle progress, pieces state, coins, and high scores stay 100% on your local phone storage.',
                      cardBg: cardBg,
                      borderColor: borderColor,
                      titleColor: titleColor,
                      subColor: subColor,
                    ),
                    const SizedBox(height: 10),
                    _buildFeatureCard(
                      icon: Icons.ads_click_rounded,
                      iconColor: const Color(0xFFFFB300),
                      title: 'Family Safe Google AdMob',
                      description: 'Rewarded video ads are served in compliance with Google Play Family Policy and GDPR standards for optional hints.',
                      cardBg: cardBg,
                      borderColor: borderColor,
                      titleColor: titleColor,
                      subColor: subColor,
                    ),
                    const SizedBox(height: 10),
                    _buildFeatureCard(
                      icon: Icons.verified_user_rounded,
                      iconColor: const Color(0xFF8E24AA),
                      title: 'GDPR & CCPA Rights',
                      description: 'You maintain full control of your advertising preferences and can reset all game data at any time from this settings page.',
                      cardBg: cardBg,
                      borderColor: borderColor,
                      titleColor: titleColor,
                      subColor: subColor,
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFB300),
                foregroundColor: const Color(0xFF0E2A47),
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 3,
              ),
              onPressed: () => Navigator.pop(ctx),
              child: const Text('I Agree & Understand', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
    required Color cardBg,
    required Color borderColor,
    required Color titleColor,
    required Color subColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14.5, color: titleColor),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: TextStyle(fontSize: 12.5, height: 1.4, color: subColor, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showTermsOfService(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: isDark ? const Color(0xFF132238) : Colors.white,
        title: Row(
          children: [
            const Icon(Icons.description_rounded, color: Color(0xFFFF9800), size: 24),
            const SizedBox(width: 10),
            Text(
              'Terms of Service',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : const Color(0xFF0E2A47),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'By downloading and playing ${AppConfig.appName}, you agree to the following terms:',
                style: TextStyle(
                  fontSize: 13.5,
                  height: 1.5,
                  fontWeight: FontWeight.w600,
                  color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                ),
              ),
              const SizedBox(height: 12),
              _buildBullet(
                'Casual Entertainment',
                'This game is designed solely for personal offline casual entertainment and mental recreation.',
                isDark,
              ),
              _buildBullet(
                'Virtual Items & Coins',
                'In-game coins, hints, and rewards are virtual items with no real monetary value. They cannot be refunded or exchanged for real currency.',
                isDark,
              ),
              _buildBullet(
                'Intellectual Property',
                'All puzzle designs, UI graphics, sound effects, and software code are the intellectual property of Always Company.',
                isDark,
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFB300),
              foregroundColor: const Color(0xFF3E2723),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('I Understand', style: TextStyle(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  void _showConsentManagement(BuildContext context, bool isDark) {
    final storage = Get.find<HiveStorage>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: isDark ? const Color(0xFF132238) : Colors.white,
        title: Row(
          children: [
            const Icon(Icons.security_rounded, color: Color(0xFF00C853), size: 24),
            const SizedBox(width: 10),
            Text(
              'Ad & Data Consent (GDPR)',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : const Color(0xFF0E2A47),
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your privacy choice determines how Google AdMob serves rewarded ads for hints and coins.\n\n'
              '• Status: Consent Granted\n'
              '• Personalized Ads: Active\n'
              '• Device Identifiers: Used solely for ad verification and frequency capping.',
              style: TextStyle(
                fontSize: 13.5,
                color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF455A64),
                height: 1.45,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'You can reset your consent choice at any time:',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF0E2A47),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              storage.setPrivacyConsent(false);
              Navigator.pop(ctx);
              Get.snackbar(
                'Consent Reset',
                'Your ad consent choice has been reset.',
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: const Color(0xEE112238),
                colorText: Colors.white,
              );
            },
            child: const Text('Reset Consent', style: TextStyle(color: Color(0xFFE53935), fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFB300),
              foregroundColor: const Color(0xFF3E2723),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Keep Active', style: TextStyle(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  void _showSupportDialog(BuildContext context, bool isDark) {
    const supportEmail = 'alwayscompany.support@gmail.com';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: isDark ? const Color(0xFF132238) : Colors.white,
        title: Row(
          children: [
            const Icon(Icons.headset_mic_rounded, color: Color(0xFF9C27B0), size: 24),
            const SizedBox(width: 10),
            Text(
              'Support & Feedback',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : const Color(0xFF0E2A47),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'We are committed to giving you the most calming puzzle experience. If you have suggestions, feature requests, or encountered an issue, we would love to hear from you!',
              style: TextStyle(
                fontSize: 13.5,
                height: 1.45,
                color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF455A64),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E2D44) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark ? Colors.white.withValues(alpha: 0.10) : const Color(0xFFE2E8F0),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.email_outlined, color: Color(0xFF9C27B0), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      supportEmail,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: isDark ? Colors.white : const Color(0xFF0E2A47),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Close',
              style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
            ),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFB300),
              foregroundColor: const Color(0xFF3E2723),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            icon: const Icon(Icons.copy_rounded, size: 18),
            label: const Text('Copy Email', style: TextStyle(fontWeight: FontWeight.w900)),
            onPressed: () {
              HapticFeedback.mediumImpact();
              Clipboard.setData(const ClipboardData(text: supportEmail));
              Navigator.pop(ctx);
              Get.snackbar(
                'Email Copied',
                'Support email address copied to clipboard.',
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: const Color(0xEE112238),
                colorText: Colors.white,
              );
            },
          ),
        ],
      ),
    );
  }

  void _showResetDataDialog(BuildContext context, SettingsController settings, bool isDark) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: isDark ? const Color(0xFF132238) : Colors.white,
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFE53935), size: 26),
            SizedBox(width: 10),
            Text(
              'Reset Game Data?',
              style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFFE53935)),
            ),
          ],
        ),
        content: Text(
          'This will permanently reset all your unlocked pictures, completed puzzles, streak count, and coin balance back to the starting default.\n\n'
          'This action cannot be undone. Are you sure?',
          style: TextStyle(
            fontSize: 13.5,
            height: 1.5,
            color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF455A64),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE53935),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: () async {
              HapticFeedback.heavyImpact();
              await settings.resetAllGameData();
              if (context.mounted) {
                Navigator.pop(ctx);
                Get.snackbar(
                  'Data Reset Successful',
                  'All puzzle progress has been reset to starting state.',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: const Color(0xEE112238),
                  colorText: Colors.white,
                );
              }
            },
            child: const Text('Reset Everything', style: TextStyle(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  Widget _buildBullet(String title, String body, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFFFFB300))),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF455A64),
                ),
                children: [
                  TextSpan(
                    text: '$title: ',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0E2A47),
                    ),
                  ),
                  TextSpan(text: body),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
