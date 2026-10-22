import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:jigsaw_pro/core/config/app_config.dart';
import 'package:jigsaw_pro/core/storage/hive_storage.dart';
import 'package:jigsaw_pro/core/widgets/casual_game_background.dart';
import 'package:jigsaw_pro/features/content/domain/entities/puzzle_picture.dart';
import 'package:jigsaw_pro/features/content/presentation/controllers/content_controller.dart';
import 'package:jigsaw_pro/features/economy/presentation/controllers/economy_controller.dart';

class GalleryPage extends StatefulWidget {
  final String? initialCategory;

  const GalleryPage({super.key, this.initialCategory});

  @override
  State<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {
  final ContentController _content = Get.find<ContentController>();
  final EconomyController _economy = Get.find<EconomyController>();
  final HiveStorage _storage = Get.find<HiveStorage>();

  late String _selectedCategory;
  late List<String> _categories;

  @override
  void initState() {
    super.initState();
    _categories = ['All', ..._content.categories];
    _selectedCategory = 'All';

    if (widget.initialCategory != null) {
      final match = _categories.firstWhereOrNull(
        (c) => c.toLowerCase() == widget.initialCategory!.toLowerCase(),
      );
      if (match != null) {
        _selectedCategory = match;
      }
    }
  }

  int _calculateColumnCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= 1050) return 5;
    if (width >= 750) return 4;
    if (width >= 550) return 3;
    return 2;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CasualGameBackground(
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 8),
              // Top Bar: Back Circle, 3D Gallery Title, Coins Pill
              _buildTopBar(context),
              const SizedBox(height: 14),
              // Filter Category Pills
              _buildCategoryPills(),
              const SizedBox(height: 14),
              // 2-Column Grid of Casual Puzzle Cards
              Expanded(
                child: _buildGalleryGrid(context),
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Circular Dark Back Button
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
                  BoxShadow(
                    color: Color(0x33000000),
                    blurRadius: 6,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
              ),
            ),
          ),

          // Playful 3D Bubble "Gallery" Title
          const Text(
            'Gallery',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.6,
              shadows: [
                Shadow(
                  color: Color(0xFF0D2544),
                  offset: Offset(0, 3),
                  blurRadius: 0,
                ),
              ],
            ),
          ),

          // Coins Capsule Pill
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              context.push('/shop');
            },
            child: Obx(() => Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFF16355C),
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x33000000),
                    blurRadius: 6,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🪙', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 6),
                  Text(
                    '${_economy.coins.value}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            )),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryPills() {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final isSelected = cat.toLowerCase() == _selectedCategory.toLowerCase();
          final displayName = cat[0].toUpperCase() + cat.substring(1);

          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() {
                _selectedCategory = cat;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.symmetric(
                horizontal: isSelected ? 20 : 18,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFFFB300) : const Color(0xFF142E52),
                borderRadius: BorderRadius.circular(22),
                boxShadow: isSelected
                    ? const [
                        BoxShadow(
                          color: Color(0x40000000),
                          blurRadius: 6,
                          offset: Offset(0, 3),
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: Text(
                  displayName,
                  style: TextStyle(
                    color: isSelected ? const Color(0xFF0E2A47) : Colors.white,
                    fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGalleryGrid(BuildContext context) {
    return Obx(() {
      final allPics = _content.allPictures;
      final filteredPics = _selectedCategory.toLowerCase() == 'all'
          ? allPics
          : allPics.where((p) => p.category.toLowerCase() == _selectedCategory.toLowerCase()).toList();

      if (filteredPics.isEmpty) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.photo_library_outlined, size: 54, color: Colors.white70),
              SizedBox(height: 12),
              Text(
                'No puzzles found in this category',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        );
      }

      final activeSession = _storage.getActiveSession();
      final cols = _calculateColumnCount(context);

      return GridView.builder(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        itemCount: filteredPics.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: cols,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: 0.82,
        ),
        itemBuilder: (context, index) {
          final pic = filteredPics[index];
          return _buildPuzzleCard(pic, activeSession);
        },
      );
    });
  }

  Widget _buildPuzzleCard(PuzzlePicture pic, Map<String, dynamic>? activeSession) {
    final isUnlocked = _content.isPictureUnlocked(pic);
    final isCompleted = _content.isPictureCompleted(pic.id);

    // Compute status text & color (matching reference design)
    String statusText;
    Color statusColor;

    if (isCompleted) {
      statusText = 'Completed';
      statusColor = const Color(0xFF00C853);
    } else if (activeSession != null && activeSession['pictureId'] == pic.id) {
      final total = (activeSession['totalPieces'] as int? ?? 1).clamp(1, 400);
      final placed = ((activeSession['placedPieceIds'] as List?)?.length ?? 0).clamp(0, total);
      final pct = ((placed / total) * 100).round();
      statusText = 'In progress $pct%';
      statusColor = const Color(0xFF0288D1);
    } else if (!isUnlocked) {
      statusText = 'Premium';
      statusColor = const Color(0xFFFF9800);
    } else {
      statusText = 'New';
      statusColor = const Color(0xFF78909C);
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x30091E36),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () => _handlePictureTap(pic, isUnlocked),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Photo Thumbnail with Rounded Top & Badges
              Expanded(
                flex: 12,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                      child: Image.asset(
                        pic.path,
                        cacheWidth: 400,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: const Color(0xFFCFD8DC),
                            child: const Center(
                              child: Icon(Icons.image_outlined, color: Colors.blueGrey, size: 36),
                            ),
                          );
                        },
                      ),
                    ),

                    // Top Right Badges
                    if (isCompleted)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: const BoxDecoration(
                            color: Color(0xFF00E676),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(color: Color(0x33000000), blurRadius: 4, offset: Offset(0, 2)),
                            ],
                          ),
                          child: const Center(
                            child: Icon(Icons.check_rounded, color: Color(0xFF0D2544), size: 18, weight: 800),
                          ),
                        ),
                      )
                    else if (!isUnlocked)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xEE112238),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: const [
                              BoxShadow(color: Color(0x33000000), blurRadius: 4, offset: Offset(0, 2)),
                            ],
                          ),
                          child: const Text(
                            'Unlock 50',
                            style: TextStyle(
                              color: Color(0xFFFFC107),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Bottom Info Portion (White card body)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      pic.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF0E2A47),
                        fontWeight: FontWeight.w800,
                        fontSize: 13.5,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handlePictureTap(PuzzlePicture pic, bool isUnlocked) {
    HapticFeedback.lightImpact();
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        title: Text(
          'Unlock ${pic.title}',
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 18,
            color: Color(0xFF0E2A47),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(pic.path, cacheWidth: 400, height: 150, fit: BoxFit.cover),
            ),
            const SizedBox(height: 16),
            Text(
              'Unlock this premium puzzle picture for ${AppConfig.coinsUnlockPremium} coins?',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF4A5568), fontSize: 13.5, height: 1.3),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF718096), fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFB300),
              foregroundColor: const Color(0xFF0E2A47),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 3,
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
                  backgroundColor: const Color(0xEE112238),
                  colorText: Colors.white,
                );
              }
            },
            child: const Text('Unlock 50 🪙', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
          ),
        ],
      ),
    );
  }
}
