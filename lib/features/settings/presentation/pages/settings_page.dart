import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jigsaw_pro/core/config/app_config.dart';
import 'package:jigsaw_pro/core/theme/app_theme.dart';
import 'package:jigsaw_pro/features/settings/presentation/controllers/settings_controller.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Get.find<SettingsController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            const Text(
              'Audio & Haptics',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primaryTeal),
            ),
            const SizedBox(height: 8),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  Obx(() => SwitchListTile(
                    title: const Text('Sound Effects'),
                    subtitle: const Text('Soft snap and victory chimes'),
                    secondary: const Icon(Icons.volume_up_outlined),
                    value: settings.soundEnabled.value,
                    activeThumbColor: AppTheme.accentAmber,
                    onChanged: (_) => settings.toggleSound(),
                  )),
                  const Divider(height: 1, indent: 56),
                  Obx(() => SwitchListTile(
                    title: const Text('Haptic Vibration'),
                    subtitle: const Text('Tactile feedback when pieces snap'),
                    secondary: const Icon(Icons.vibration),
                    value: settings.vibrationEnabled.value,
                    activeThumbColor: AppTheme.accentAmber,
                    onChanged: (_) => settings.toggleVibration(),
                  )),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              'Appearance',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primaryTeal),
            ),
            const SizedBox(height: 8),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  Obx(() => ListTile(
                    leading: const Icon(Icons.brightness_medium_outlined),
                    title: const Text('Theme Mode'),
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
                    leading: const Icon(Icons.texture_outlined),
                    title: const Text('Board Background'),
                    subtitle: Obx(() => Text(settings.boardBackground.value.label)),
                    onTap: () => _showBackgroundPicker(context, settings),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              'About & Privacy',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primaryTeal),
            ),
            const SizedBox(height: 8),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.privacy_tip_outlined),
                    title: const Text('Privacy Policy'),
                    subtitle: const Text('Zero personal data collected'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () => _showPrivacyPolicy(context),
                  ),
                  const Divider(height: 1, indent: 56),
                  const ListTile(
                    leading: Icon(Icons.info_outline),
                    title: Text('Version'),
                    subtitle: Text('${AppConfig.appName} v${AppConfig.appVersion}'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBackgroundPicker(BuildContext context, SettingsController settings) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Select Board Background',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                      title: Text(style.label),
                      trailing: isSelected ? const Icon(Icons.check, color: AppTheme.accentAmber) : null,
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Privacy Policy'),
        content: const SingleChildScrollView(
          child: Text(
            'Jigsaw Pro respects your privacy. We collect zero personal data, '
            'financial information, or precise location.\n\n'
            'The game operates completely offline. All puzzle progress, scores, '
            'and coin balances are stored strictly on your local device.\n\n'
            'Optional third-party Google Mobile Ads may collect device identifiers '
            'for ad delivery in accordance with standard Google policies.',
            style: TextStyle(fontSize: 14, height: 1.5),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
