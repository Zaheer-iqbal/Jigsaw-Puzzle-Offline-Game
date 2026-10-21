import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:jigsaw_pro/core/config/app_config.dart';
import 'package:jigsaw_pro/core/storage/hive_storage.dart';
import 'package:jigsaw_pro/core/theme/app_theme.dart';
import 'package:jigsaw_pro/core/utils/responsive.dart';
import 'package:jigsaw_pro/features/content/presentation/controllers/content_controller.dart';
import 'package:jigsaw_pro/features/economy/presentation/controllers/economy_controller.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final storage = Get.find<HiveStorage>();
    final content = Get.find<ContentController>();
    final economy = Get.find<EconomyController>();

    final activeSession = storage.getActiveSession();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Jigsaw Pro'),
        actions: [
          // Coins indicator
          Obx(() => Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.accentAmber.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.accentAmber.withValues(alpha: 0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.monetization_on, color: AppTheme.accentAmber, size: 20),
                const SizedBox(width: 6),
                Text(
                  '${economy.coins.value}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ],
            ),
          )),
          IconButton(
            icon: const Icon(Icons.shopping_bag_outlined),
            tooltip: 'Shop',
            onPressed: () => context.push('/shop'),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: SafeArea(
        child: Responsive(
          portrait: (context, constraints) => _buildPortraitContent(context, storage, content, economy, activeSession),
          landscape: (context, constraints) => _buildLandscapeContent(context, storage, content, economy, activeSession),
        ),
      ),
    );
  }

  Widget _buildPortraitContent(
    BuildContext context,
    HiveStorage storage,
    ContentController content,
    EconomyController economy,
    Map<String, dynamic>? activeSession,
  ) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      children: [
        if (activeSession != null) ...[
          _buildContinueCard(context, activeSession, content),
          const SizedBox(height: 20),
        ],
        _buildDailyPuzzleCard(context, content, economy),
        const SizedBox(height: 24),
        _buildCategoryHeader(context),
        const SizedBox(height: 12),
        _buildCategoryGrid(context, content, isLandscape: false),
      ],
    );
  }

  Widget _buildLandscapeContent(
    BuildContext context,
    HiveStorage storage,
    ContentController content,
    EconomyController economy,
    Map<String, dynamic>? activeSession,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left Column: Continue & Daily Cards
        Expanded(
          flex: 4,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            children: [
              if (activeSession != null) ...[
                _buildContinueCard(context, activeSession, content),
                const SizedBox(height: 16),
              ],
              _buildDailyPuzzleCard(context, content, economy),
            ],
          ),
        ),
        // Right Column: Categories
        Expanded(
          flex: 6,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            children: [
              _buildCategoryHeader(context),
              const SizedBox(height: 12),
              _buildCategoryGrid(context, content, isLandscape: true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContinueCard(
    BuildContext context,
    Map<String, dynamic> session,
    ContentController content,
  ) {
    final pictureId = session['pictureId'] as String;
    final pieceCount = session['pieceCount'] as int;
    final moves = session['moves'] as int? ?? 0;
    final pic = content.allPictures.firstWhereOrNull((p) => p.id == pictureId);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          context.push('/puzzle?resume=true&id=$pictureId');
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: pic != null
                    ? Image.asset(pic.path, width: 72, height: 72, fit: BoxFit.cover)
                    : Container(width: 72, height: 72, color: Colors.grey.shade800),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.accentAmber.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'CONTINUE PLAYING',
                        style: TextStyle(
                          color: AppTheme.accentAmber,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      pic?.title ?? 'Unfinished Puzzle',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(
                      '$pieceCount pieces • $moves moves made',
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.play_circle_fill, size: 36, color: AppTheme.primaryTeal),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDailyPuzzleCard(
    BuildContext context,
    ContentController content,
    EconomyController economy,
  ) {
    return Obx(() {
      final daily = content.dailyPicture.value;
      if (daily == null) return const SizedBox.shrink();

      return Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [
                AppTheme.primaryTeal.withValues(alpha: 0.85),
                AppTheme.primaryTealDark,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.today, color: Colors.white, size: 22),
                      const SizedBox(width: 8),
                      const Text(
                        'Daily Puzzle',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.accentAmber,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '+${AppConfig.coinsDailyBonus} Coins',
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.asset(daily.path, width: 80, height: 80, fit: BoxFit.cover),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          daily.title,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Streak: ${economy.streak.value} Days',
                          style: const TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.accentAmber,
                            foregroundColor: Colors.black,
                            minimumSize: const Size(110, 36),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                          ),
                          onPressed: () {
                            context.push('/difficulty/${daily.id}');
                          },
                          child: const Text('Play Today', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildCategoryHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Categories',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        TextButton(
          onPressed: () => context.push('/gallery'),
          child: const Text('View All', style: TextStyle(color: AppTheme.primaryTeal)),
        ),
      ],
    );
  }

  Widget _buildCategoryGrid(BuildContext context, ContentController content, {required bool isLandscape}) {
    return Obx(() {
      final categories = content.categories;

      final icons = {
        'nature': Icons.eco,
        'animals': Icons.pets,
        'flowers': Icons.local_florist,
        'landmarks': Icons.location_city,
        'art': Icons.palette,
      };

      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: categories.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: isLandscape ? 3 : 2,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: 1.35,
        ),
        itemBuilder: (context, index) {
          final cat = categories[index];
          final icon = icons[cat.toLowerCase()] ?? Icons.category;

          return Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => context.push('/gallery?category=$cat'),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      backgroundColor: AppTheme.primaryTeal.withValues(alpha: 0.15),
                      radius: 20,
                      child: Icon(icon, color: AppTheme.primaryTeal, size: 22),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      cat[0].toUpperCase() + cat.substring(1),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    });
  }
}
