import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:jigsaw_pro/core/config/app_config.dart';
import 'package:jigsaw_pro/core/theme/app_theme.dart';
import 'package:jigsaw_pro/core/widgets/casual_game_background.dart';
import 'package:jigsaw_pro/features/settings/presentation/controllers/settings_controller.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Get.find<SettingsController>();

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
                    const Text(
                      'Audio & Haptics',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        shadows: [
                          Shadow(color: Color(0xFF0D2544), offset: Offset(0, 2), blurRadius: 0),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: const [
                          BoxShadow(color: Color(0x200D2544), blurRadius: 10, offset: Offset(0, 4)),
                        ],
                      ),
                      child: Column(
                        children: [
                          Obx(() => SwitchListTile(
                            title: const Text('Sound Effects', style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF0E2A47))),
                            subtitle: const Text('Soft snap and victory chimes', style: TextStyle(color: Color(0xFF78909C), fontSize: 12.5)),
                            secondary: const Icon(Icons.volume_up_rounded, color: Color(0xFF0288D1)),
                            value: settings.soundEnabled.value,
                            activeThumbColor: const Color(0xFFFFB300),
                            onChanged: (_) => settings.toggleSound(),
                          )),
                          const Divider(height: 1, indent: 56),
                          Obx(() => SwitchListTile(
                            title: const Text('Haptic Vibration', style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF0E2A47))),
                            subtitle: const Text('Tactile feedback when pieces snap', style: TextStyle(color: Color(0xFF78909C), fontSize: 12.5)),
                            secondary: const Icon(Icons.vibration_rounded, color: Color(0xFF7E57C2)),
                            value: settings.vibrationEnabled.value,
                            activeThumbColor: const Color(0xFFFFB300),
                            onChanged: (_) => settings.toggleVibration(),
                          )),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    const Text(
                      'Appearance',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        shadows: [
                          Shadow(color: Color(0xFF0D2544), offset: Offset(0, 2), blurRadius: 0),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: const [
                          BoxShadow(color: Color(0x200D2544), blurRadius: 10, offset: Offset(0, 4)),
                        ],
                      ),
                      child: Column(
                        children: [
                          Obx(() => ListTile(
                            leading: const Icon(Icons.brightness_medium_rounded, color: Color(0xFFFF8F00)),
                            title: const Text('Theme Mode', style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF0E2A47))),
                            trailing: DropdownButton<String>(
                              value: settings.themeModeString.value,
                              underline: const SizedBox.shrink(),
                              items: const [
                                DropdownMenuItem(value: 'system', child: Text('System')),
                                DropdownMenuItem(value: 'light', child: Text('Light')),
                                DropdownMenuItem(value: 'dark', child: Text('Dark')),
                              ],
                              onChanged: (val) {
                                if (val != null) settings.setThemeMode(val);
                              },
                            ),
                          )),
                          const Divider(height: 1, indent: 56),
                          ListTile(
                            leading: const Icon(Icons.texture_rounded, color: Color(0xFF00897B)),
                            title: const Text('Board Background', style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF0E2A47))),
                            subtitle: Obx(() => Text(settings.boardBackground.value.label, style: const TextStyle(color: Color(0xFF78909C), fontSize: 12.5))),
                            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Color(0xFF78909C)),
                            onTap: () => _showBackgroundPicker(context, settings),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    const Text(
                      'About & Privacy',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        shadows: [
                          Shadow(color: Color(0xFF0D2544), offset: Offset(0, 2), blurRadius: 0),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: const [
                          BoxShadow(color: Color(0x200D2544), blurRadius: 10, offset: Offset(0, 4)),
                        ],
                      ),
                      child: Column(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.privacy_tip_rounded, color: Color(0xFF1E88E5)),
                            title: const Text('Privacy Policy', style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF0E2A47))),
                            subtitle: const Text('Zero personal data collected', style: TextStyle(color: Color(0xFF78909C), fontSize: 12.5)),
                            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Color(0xFF78909C)),
                            onTap: () => _showPrivacyPolicy(context),
                          ),
                          const Divider(height: 1, indent: 56),
                          ListTile(
                            leading: const Icon(Icons.info_outline_rounded, color: Color(0xFF5E35B1)),
                            title: const Text('Version', style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF0E2A47))),
                            subtitle: Text('${AppConfig.appName} v${AppConfig.appVersion}', style: const TextStyle(color: Color(0xFF78909C), fontSize: 12.5)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
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

  void _showBackgroundPicker(BuildContext context, SettingsController settings) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Select Board Background',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0E2A47)),
                ),
                const SizedBox(height: 16),
                ...BoardBackgroundStyle.values.map((style) {
                  return Obx(() {
                    final isSelected = settings.boardBackground.value == style;
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: style.primaryColor,
                        radius: 16,
                      ),
                      title: Text(style.label, style: const TextStyle(fontWeight: FontWeight.w700)),
                      trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: Color(0xFFFFB300), size: 24) : null,
                      onTap: () {
                        settings.setBoardBackground(style);
                        Navigator.pop(ctx);
                      },
                    );
                  });
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showPrivacyPolicy(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Privacy Policy', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0E2A47))),
        content: const SingleChildScrollView(
          child: Text(
            'Jigsaw Puzzle: Offline Game respects your privacy. We collect zero personal data, '
            'financial information, or precise location.\n\n'
            'The game operates completely offline. All puzzle progress, scores, '
            'and coin balances are stored strictly on your local device.\n\n'
            'Optional third-party Google Mobile Ads may collect device identifiers '
            'for ad delivery in accordance with standard Google policies.',
            style: TextStyle(fontSize: 14, height: 1.5, color: Color(0xFF455A64)),
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFB300),
              foregroundColor: const Color(0xFF0E2A47),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close', style: TextStyle(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }
}
