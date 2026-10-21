import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:jigsaw_pro/core/config/app_config.dart';
import 'package:jigsaw_pro/core/theme/app_theme.dart';
import 'package:jigsaw_pro/features/content/domain/entities/puzzle_level.dart';
import 'package:jigsaw_pro/features/content/domain/entities/puzzle_picture.dart';
import 'package:jigsaw_pro/features/content/presentation/controllers/content_controller.dart';
import 'package:jigsaw_pro/features/economy/presentation/controllers/economy_controller.dart';

class GalleryPage extends StatefulWidget {
  final String? initialCategory;

  const GalleryPage({super.key, this.initialCategory});

  @override
  State<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ContentController _content = Get.find<ContentController>();
  final EconomyController _economy = Get.find<EconomyController>();

  late List<String> _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = ['All', ..._content.categories];
    var initialIndex = 0;
    if (widget.initialCategory != null) {
      final idx = _tabs.indexWhere((t) => t.toLowerCase() == widget.initialCategory!.toLowerCase());
      if (idx != -1) initialIndex = idx;
    }
    _tabController = TabController(length: _tabs.length, vsync: this, initialIndex: initialIndex);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  int _calculateColumnCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= 1000) return 5;
    if (width >= 700) return 4;
    if (width >= 500) return 3;
    return 2;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Puzzle Gallery'),
        actions: [
          Obx(() => Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppTheme.accentAmber.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.monetization_on, color: AppTheme.accentAmber, size: 18),
                const SizedBox(width: 4),
                Text(
                  '${_economy.coins.value}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          )),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: AppTheme.accentAmber,
          labelColor: AppTheme.accentAmber,
          unselectedLabelColor: Colors.grey,
          tabs: _tabs.map((tab) => Tab(text: tab[0].toUpperCase() + tab.substring(1))).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _tabs.map((tab) => _buildCategoryView(tab)).toList(),
      ),
    );
  }

  Widget _buildCategoryView(String category) {
    if (category == 'All') {
      return Obx(() {
        final pictures = _content.allPictures;
        if (pictures.isEmpty) {
          return const Center(child: Text('No pictures found.'));
        }

        final cols = _calculateColumnCount(context);

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: pictures.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 1.0,
          ),
          itemBuilder: (context, index) {
            final pic = pictures[index];
            return _buildThumbnailCard(pic);
          },
        );
      });
    }

    // 100-level progressive view for each specific category
    return FutureBuilder<List<PuzzleLevel>>(
      future: _content.getLevels(category),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(color: AppTheme.accentAmber));
        }

        final levels = snapshot.data!;
        final cols = _calculateColumnCount(context);

        return GetBuilder<ContentController>(
          builder: (ctrl) {
            final highestUnlocked = ctrl.getHighestLevel(category);

            return Column(
              children: [
                // Category Level Progress Bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  color: Colors.black.withValues(alpha: 0.25),
                  child: Row(
                    children: [
                      const Icon(Icons.military_tech, color: AppTheme.accentAmber, size: 24),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Level $highestUnlocked / 100',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                Text(
                                  '$highestUnlocked% Unlocked',
                                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: highestUnlocked / 100.0,
                                minHeight: 6,
                                backgroundColor: Colors.white12,
                                valueColor: const AlwaysStoppedAnimation(AppTheme.accentAmber),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Grid of 100 Progressive Levels
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: levels.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: cols,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      childAspectRatio: 0.95,
                    ),
                    itemBuilder: (context, index) {
                      final level = levels[index];
                      return _buildLevelCard(level, highestUnlocked);
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildLevelCard(PuzzleLevel level, int highestUnlocked) {
    final isUnlocked = level.levelNumber <= highestUnlocked;
    final isCompleted = _content.isPictureCompleted(level.id);

    return Card(
      elevation: isUnlocked ? 3 : 1,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: level.levelNumber == highestUnlocked ? AppTheme.accentAmber : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: () {
          if (isUnlocked) {
            context.push('/difficulty/${level.id}?defaultCount=${level.defaultPieceCount}');
          } else {
            Get.snackbar(
              'Level Locked',
              'Complete Level ${level.levelNumber - 1} to unlock this level!',
              snackPosition: SnackPosition.BOTTOM,
            );
          }
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Thumbnail
            Image.asset(
              level.imagePath,
              cacheWidth: 400,
              fit: BoxFit.cover,
            ),
            // Gradient
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.black54, Colors.transparent, Colors.black87],
                  stops: [0.0, 0.4, 1.0],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            // Top Level Badge
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isUnlocked ? AppTheme.primaryTeal : Colors.black54,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Lvl ${level.levelNumber}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
            // Bottom Info: Piece count & Difficulty label
            Positioned(
              left: 8,
              right: 8,
              bottom: 8,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${level.defaultPieceCount} Pieces',
                    style: const TextStyle(
                      color: AppTheme.accentAmber,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    PuzzleLevel.getDifficultyLabel(level.defaultPieceCount),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            // Locked Overlay if level not reached
            if (!isUnlocked)
              Container(
                color: Colors.black.withValues(alpha: 0.65),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.lock, color: Colors.white70, size: 24),
                      const SizedBox(height: 4),
                      Text(
                        'Lvl ${level.levelNumber}',
                        style: const TextStyle(color: Colors.white60, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ),
            // Completed Checkmark
            if (isCompleted)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 14),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnailCard(PuzzlePicture pic) {
    final isUnlocked = _content.isPictureUnlocked(pic);
    final isCompleted = _content.isPictureCompleted(pic.id);

    return Card(
      elevation: 3,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _handlePictureTap(pic, isUnlocked),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Thumbnail with cacheWidth for memory efficiency
            Image.asset(
              pic.path,
              cacheWidth: 400,
              fit: BoxFit.cover,
            ),
            // Dark gradient overlay
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.transparent, Colors.black54],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            // Title at bottom
            Positioned(
              left: 10,
              right: 10,
              bottom: 8,
              child: Text(
                pic.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                ),
              ),
            ),
            // Lock icon on premium pictures
            if (!isUnlocked)
              Container(
                color: Colors.black.withValues(alpha: 0.55),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.accentAmber,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.lock, size: 16, color: Colors.black),
                        const SizedBox(width: 4),
                        Text(
                          '${AppConfig.coinsUnlockPremium}',
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            // Checkmark if completed
            if (isCompleted)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 16),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _handlePictureTap(PuzzlePicture pic, bool isUnlocked) {
    if (isUnlocked) {
      context.push('/difficulty/${pic.id}');
    } else {
      _showUnlockDialog(pic);
    }
  }

  void _showUnlockDialog(PuzzlePicture pic) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Unlock ${pic.title}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(pic.path, cacheWidth: 400, height: 160, fit: BoxFit.cover),
            ),
            const SizedBox(height: 16),
            Text(
              'Unlock this premium puzzle for ${AppConfig.coinsUnlockPremium} coins?',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentAmber,
              foregroundColor: Colors.black,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              if (_economy.spendCoins(AppConfig.coinsUnlockPremium)) {
                await _content.unlockPicture(pic);
                setState(() {});
                if (mounted) context.push('/difficulty/${pic.id}');
              } else {
                Get.snackbar(
                  'Not enough coins',
                  'You need ${AppConfig.coinsUnlockPremium} coins to unlock this picture.',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.black87,
                  colorText: Colors.white,
                );
              }
            },
            child: const Text('Unlock', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
