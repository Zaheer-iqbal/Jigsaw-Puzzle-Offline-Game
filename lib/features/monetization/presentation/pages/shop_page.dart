import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:jigsaw_pro/core/config/app_config.dart';
import 'package:jigsaw_pro/core/storage/hive_storage.dart';
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
                    // Free Coins via Rewarded Ad
                    _buildAdRewardCard(context, monetization, economy),
                    const SizedBox(height: 18),

                    // Remove Ads Card
                    _buildRemoveAdsCard(context, monetization),
                    const SizedBox(height: 22),

                    // Section Title
                    const Text(
                      'Coin Packs',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        shadows: [
                          Shadow(color: Color(0xFF0D2544), offset: Offset(0, 2), blurRadius: 0),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    _buildCoinPackTile(
                      context,
                      title: 'Small Pack',
                      coins: AppConfig.coinsPackSmallAmount,
                      price: '\$0.99',
                      icon: Icons.toll_rounded,
                      onBuy: () => _handleCoinBuy(economy, AppConfig.coinsPackSmallAmount),
                    ),
                    const SizedBox(height: 12),

                    _buildCoinPackTile(
                      context,
                      title: 'Medium Pack',
                      coins: AppConfig.coinsPackMediumAmount,
                      price: '\$2.49',
                      icon: Icons.monetization_on_rounded,
                      isPopular: true,
                      onBuy: () => _handleCoinBuy(economy, AppConfig.coinsPackMediumAmount),
                    ),
                    const SizedBox(height: 12),

                    _buildCoinPackTile(
                      context,
                      title: 'Large Pack',
                      coins: AppConfig.coinsPackLargeAmount,
                      price: '\$4.99',
                      icon: Icons.savings_rounded,
                      onBuy: () => _handleCoinBuy(economy, AppConfig.coinsPackLargeAmount),
                    ),
                    const SizedBox(height: 24),

                    Center(
                      child: TextButton.icon(
                        icon: const Icon(Icons.restore_rounded, color: Colors.white70),
                        label: const Text(
                          'Restore Purchases',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        onPressed: () {
                          monetization.restorePurchases();
                          Get.snackbar(
                            'Purchases Restored',
                            'Any existing Google Play entitlements have been restored.',
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: const Color(0xEE112238),
                            colorText: Colors.white,
                          );
                        },
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

  Widget _buildTopBar(BuildContext context, EconomyController economy) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
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
                const Text(
                  'Watch Ad for Coins',
                  style: TextStyle(color: Color(0xFF0E2A47), fontWeight: FontWeight.w900, fontSize: 16),
                ),
                const SizedBox(height: 2),
                Text(
                  'Earn +${AppConfig.coinsRewardedAd} free coins immediately',
                  style: const TextStyle(color: Color(0xFF546E7A), fontSize: 12.5, fontWeight: FontWeight.w600),
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
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            ),
            onPressed: () {
              monetization.showRewardedAd(
                onRewardEarned: () {
                  economy.addCoins(AppConfig.coinsRewardedAd);
                  Get.snackbar(
                    'Reward Claimed!',
                    '+${AppConfig.coinsRewardedAd} coins added to your balance!',
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: const Color(0xEE112238),
                    colorText: Colors.white,
                  );
                },
              );
            },
            child: const Text('Watch', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
          ),
        ],
      ),
    );
  }

  Widget _buildRemoveAdsCard(BuildContext context, MonetizationController monetization) {
    return Obx(() {
      final isPurchased = monetization.isRemoveAdsPurchased.value;

      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
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
                color: Color(0xFFE0E0E0),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(Icons.block_rounded, color: Color(0xFF37474F), size: 28),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Remove Ads',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF0E2A47)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isPurchased ? 'Already purchased! (Ad-free)' : 'Permanently remove interstitial ads',
                    style: const TextStyle(color: Color(0xFF546E7A), fontSize: 12.5, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            if (isPurchased)
              const Icon(Icons.check_circle_rounded, color: Color(0xFF00E676), size: 28)
            else
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF29B6F6),
                  foregroundColor: Colors.white,
                  elevation: 3,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                onPressed: () => _handleRemoveAdsBuy(monetization),
                child: const Text('\$1.99', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
              ),
          ],
        ),
      );
    });
  }

  void _handleRemoveAdsBuy(MonetizationController monetization) {
    monetization.isRemoveAdsPurchased.value = true;
    Get.find<HiveStorage>().setRemoveAds(true);
    Get.snackbar(
      'Ads Removed',
      'All interstitial ads have been disabled permanently!',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xEE112238),
      colorText: Colors.white,
    );
  }

  Widget _buildCoinPackTile(
    BuildContext context, {
    required String title,
    required int coins,
    required String price,
    required IconData icon,
    required VoidCallback onBuy,
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
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8E1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Icon(icon, color: const Color(0xFFFF8F00), size: 28),
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
                      Text(
                        '+$coins Coins',
                        style: const TextStyle(
                          color: Color(0xFF00C853),
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
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
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  ),
                  onPressed: onBuy,
                  child: Text(price, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                ),
              ],
            ),
          ),
          if (isPopular)
            Positioned(
              top: 0,
              right: 28,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: const BoxDecoration(
                  color: Color(0xFFFF8F00),
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(8)),
                ),
                child: const Text(
                  'POPULAR',
                  style: TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.w900),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _handleCoinBuy(EconomyController economy, int amount) {
    economy.addCoins(amount);
    Get.snackbar(
      'Coins Added!',
      '+$amount coins added to your stash!',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xEE112238),
      colorText: Colors.white,
    );
  }
}
