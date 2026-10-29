import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:jigsaw_pro/core/audio/audio_service.dart';
import 'package:jigsaw_pro/core/config/app_config.dart';
import 'package:jigsaw_pro/core/haptics/haptic_service.dart';
import 'package:jigsaw_pro/core/widgets/app_bottom_nav_bar.dart';
import 'package:jigsaw_pro/core/widgets/casual_game_background.dart';
import 'package:jigsaw_pro/features/economy/presentation/controllers/economy_controller.dart';
import 'package:jigsaw_pro/features/monetization/presentation/controllers/monetization_controller.dart';

class ShopPage extends StatelessWidget {
  const ShopPage({super.key});

  @override
  Widget build(BuildContext context) {
    final monetization = Get.find<MonetizationController>();
    final economy = Get.find<EconomyController>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      bottomNavigationBar: const AppBottomNavBar(currentTab: AppTab.shop),
      body: CasualGameBackground(
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 8),
              _buildTopBar(context, economy),
              const SizedBox(height: 12),
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  children: [
                    // Quick Free Coins via Rewarded Ad
                    _buildAdRewardCard(context, monetization, economy),
                    const SizedBox(height: 18),

                    // Remove Ads via 3 High-Reward Sponsor Videos
                    _buildRemoveAdsCard(context, monetization),
                    const SizedBox(height: 22),

                    // Section Title: Free Coin Stashes via Ads
                    Row(
                      children: [
                        const Icon(Icons.stars_rounded, color: Color(0xFFFFB300), size: 24),
                        const SizedBox(width: 8),
                        const Text(
                          'Bonus Coin Stashes',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            shadows: [
                              Shadow(color: Color(0xFF0D2544), offset: Offset(0, 2), blurRadius: 0),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Watch sponsor videos to collect infinite free coins without paying real money!',
                      style: TextStyle(color: Colors.white70, fontSize: 12.5),
                    ),
                    const SizedBox(height: 14),

                    _buildCoinPackTile(
                      context,
                      title: 'Small Stash',
                      coins: 100,
                      badge: 'Instant',
                      icon: Icons.toll_rounded,
                      onClaim: () {
                        Get.find<HapticService>().click();
                        monetization.claimCoinPackViaAd(
                          context,
                          coins: 100,
                          packTitle: 'Small Stash',
                        );
                      },
                    ),
                    const SizedBox(height: 14),

                    _buildCoinPackTile(
                      context,
                      title: 'Super Stash',
                      coins: 250,
                      badge: 'Most Popular',
                      icon: Icons.monetization_on_rounded,
                      isPopular: true,
                      onClaim: () {
                        Get.find<HapticService>().click();
                        monetization.claimCoinPackViaAd(
                          context,
                          coins: 250,
                          packTitle: 'Super Stash',
                        );
                      },
                    ),
                    const SizedBox(height: 14),

                    _buildCoinPackTile(
                      context,
                      title: 'Mega Treasure',
                      coins: 600,
                      badge: 'Mega Bonus',
                      icon: Icons.savings_rounded,
                      onClaim: () {
                        Get.find<HapticService>().click();
                        monetization.claimCoinPackViaAd(
                          context,
                          coins: 600,
                          packTitle: 'Mega Treasure',
                        );
                      },
                    ),
                    const SizedBox(height: 24),

                    // 100% Free Gaming Guarantee Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.verified_user_rounded, color: Color(0xFF00E676), size: 24),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '100% Free Offline Gaming — No real payments or credit cards required anywhere!',
                              style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
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
  }

  Widget _buildTopBar(BuildContext context, EconomyController economy) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Circular Back Button
          GestureDetector(
            onTap: () {
              if (Get.isRegistered<HapticService>()) Get.find<HapticService>().click();
              if (Get.isRegistered<AudioService>()) Get.find<AudioService>().playClick();
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

          // 3D Bubble Title
          const Text(
            'Shop',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.6,
              shadows: [
                Shadow(color: Color(0xFF0D2544), offset: Offset(0, 3), blurRadius: 0),
              ],
            ),
          ),

          // Current Coins Pill
          Obx(() => Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFF16355C),
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(color: Color(0x33000000), blurRadius: 6, offset: Offset(0, 3)),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🪙', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 6),
                Text(
                  '${economy.coins.value}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildAdRewardCard(BuildContext context, MonetizationController monetization, EconomyController economy) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF132238) : Colors.white;
    final titleColor = isDark ? Colors.white : const Color(0xFF0E2A47);
    final subColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF546E7A);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        border: isDark ? Border.all(color: Colors.white.withValues(alpha: 0.08), width: 1.2) : null,
        boxShadow: const [
          BoxShadow(color: Color(0x250D2544), blurRadius: 14, offset: Offset(0, 6)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
              color: Color(0xFFFFB300),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(Icons.ondemand_video_rounded, color: Color(0xFF0E2A47), size: 28),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Daily Video Reward',
                  style: TextStyle(color: titleColor, fontWeight: FontWeight.w900, fontSize: 16),
                ),
                const SizedBox(height: 2),
                Text(
                  'Earn +${AppConfig.coinsRewardedAd} free coins immediately',
                  style: TextStyle(color: subColor, fontSize: 12.5, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFB300),
              foregroundColor: const Color(0xFF0E2A47),
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            onPressed: () {
              if (Get.isRegistered<HapticService>()) Get.find<HapticService>().click();
              monetization.showRewardedAd(
                context: context,
                rewardTitle: '+${AppConfig.coinsRewardedAd} Coins',
                onRewardEarned: () {
                  economy.addCoins(AppConfig.coinsRewardedAd);
                  if (Get.isRegistered<AudioService>()) Get.find<AudioService>().playWin();
                  if (Get.isRegistered<HapticService>()) Get.find<HapticService>().win();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('🎉 +${AppConfig.coinsRewardedAd} coins added to your balance!'),
                      backgroundColor: const Color(0xFF00C853),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  );
                },
              );
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.play_arrow_rounded, size: 20),
                SizedBox(width: 4),
                Text('Watch', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRemoveAdsCard(BuildContext context, MonetizationController monetization) {
    return Obx(() {
      final isPurchased = monetization.isRemoveAdsPurchased.value;
      final progress = monetization.removeAdsProgress.value.clamp(0, 3);

      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFF00E676), width: 1.8),
          boxShadow: const [
            BoxShadow(color: Color(0x250D2544), blurRadius: 14, offset: Offset(0, 6)),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: isPurchased ? const Color(0xFF00E676).withValues(alpha: 0.15) : const Color(0xFFE8F5E9),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      isPurchased ? Icons.check_circle_rounded : Icons.block_rounded,
                      color: const Color(0xFF00C853),
                      size: 28,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Flexible(
                            child: Text(
                              'Remove All Ads',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF0E2A47)),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00C853),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'VIP FREE',
                              style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        isPurchased
                            ? 'Permanent Ad-Free VIP is Active! 🎉'
                            : 'Watch 3 sponsor videos to remove ads forever without paying!',
                        style: const TextStyle(color: Color(0xFF546E7A), fontSize: 12.5, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            if (isPurchased)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF00E676).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.verified_rounded, color: Color(0xFF00C853), size: 20),
                    SizedBox(width: 8),
                    Text(
                      'All Interstitial Ads Disabled Permanently',
                      style: TextStyle(color: Color(0xFF00897B), fontWeight: FontWeight.w900, fontSize: 13),
                    ),
                  ],
                ),
              )
            else ...[
              // Progress Bar
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: progress / 3.0,
                        minHeight: 9,
                        backgroundColor: const Color(0xFFECEFF1),
                        valueColor: const AlwaysStoppedAnimation(Color(0xFF00C853)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '$progress / 3 Watched',
                    style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0E2A47), fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Button to watch video for Remove Ads
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00C853),
                  foregroundColor: Colors.white,
                  elevation: 3,
                  minimumSize: const Size(double.infinity, 44),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                icon: const Icon(Icons.ondemand_video_rounded, size: 20),
                label: Flexible(
                  child: Text(
                    'Watch Video (${progress + 1}/3) to Unlock Ad-Free',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                  ),
                ),
                onPressed: () {
                  if (Get.isRegistered<HapticService>()) Get.find<HapticService>().click();
                  monetization.watchAdForRemoveAds(context);
                },
              ),
            ],
          ],
        ),
      );
    });
  }

  Widget _buildCoinPackTile(
    BuildContext context, {
    required String title,
    required int coins,
    required String badge,
    required IconData icon,
    required VoidCallback onClaim,
    bool isPopular = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: isPopular ? Border.all(color: const Color(0xFFFFB300), width: 2) : null,
        boxShadow: const [
          BoxShadow(color: Color(0x200D2544), blurRadius: 12, offset: Offset(0, 5)),
        ],
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8E1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Icon(icon, color: const Color(0xFFFF8F00), size: 30),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF0E2A47)),
                      ),
                      const SizedBox(height: 2),
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 4,
                        children: [
                          const Text('🪙', style: TextStyle(fontSize: 13)),
                          Text(
                            '+$coins',
                            style: const TextStyle(
                              color: Color(0xFFF57C00),
                              fontWeight: FontWeight.w900,
                              fontSize: 13,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00E676).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: const Text(
                              'FREE',
                              style: TextStyle(color: Color(0xFF00C853), fontSize: 9.5, fontWeight: FontWeight.w900),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isPopular ? const Color(0xFFFFB300) : const Color(0xFF1E88E5),
                    foregroundColor: isPopular ? const Color(0xFF0E2A47) : Colors.white,
                    elevation: 3,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                  onPressed: onClaim,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.ondemand_video_rounded, size: 16),
                      SizedBox(width: 4),
                      Text('Watch', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12.5)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (isPopular)
            Positioned(
              top: 0,
              right: 18,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: const BoxDecoration(
                  color: Color(0xFFFFB300),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(10),
                    bottomRight: Radius.circular(10),
                  ),
                ),
                child: Text(
                  badge,
                  style: const TextStyle(
                    color: Color(0xFF0E2A47),
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
