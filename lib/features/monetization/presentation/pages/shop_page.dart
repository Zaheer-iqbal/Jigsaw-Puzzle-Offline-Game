import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jigsaw_pro/core/config/app_config.dart';
import 'package:jigsaw_pro/core/storage/hive_storage.dart';
import 'package:jigsaw_pro/core/theme/app_theme.dart';
import 'package:jigsaw_pro/features/economy/presentation/controllers/economy_controller.dart';
import 'package:jigsaw_pro/features/monetization/presentation/controllers/monetization_controller.dart';

class ShopPage extends StatelessWidget {
  const ShopPage({super.key});

  @override
  Widget build(BuildContext context) {
    final monetization = Get.find<MonetizationController>();
    final economy = Get.find<EconomyController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shop'),
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
                  '${economy.coins.value}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          )),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            // Free Coins via Rewarded Ad
            _buildAdRewardCard(context, monetization, economy),
            const SizedBox(height: 24),

            // Remove Ads card
            _buildRemoveAdsCard(context, monetization),
            const SizedBox(height: 24),

            const Text(
              'Coin Packs',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildCoinPackTile(
              context,
              title: 'Small Pack',
              coins: AppConfig.coinsPackSmallAmount,
              price: '\$0.99',
              icon: Icons.toll,
              onBuy: () => _handleCoinBuy(economy, AppConfig.coinsPackSmallAmount),
            ),
            const SizedBox(height: 10),
            _buildCoinPackTile(
              context,
              title: 'Medium Pack',
              coins: AppConfig.coinsPackMediumAmount,
              price: '\$2.49',
              icon: Icons.monetization_on_outlined,
              isPopular: true,
              onBuy: () => _handleCoinBuy(economy, AppConfig.coinsPackMediumAmount),
            ),
            const SizedBox(height: 10),
            _buildCoinPackTile(
              context,
              title: 'Large Pack',
              coins: AppConfig.coinsPackLargeAmount,
              price: '\$4.99',
              icon: Icons.savings_outlined,
              onBuy: () => _handleCoinBuy(economy, AppConfig.coinsPackLargeAmount),
            ),
            const SizedBox(height: 32),

            Center(
              child: TextButton.icon(
                icon: const Icon(Icons.restore),
                label: const Text('Restore Purchases'),
                onPressed: () {
                  monetization.restorePurchases();
                  Get.snackbar(
                    'Purchases Restored',
                    'Any existing Google Play entitlements have been restored.',
                    snackPosition: SnackPosition.BOTTOM,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdRewardCard(BuildContext context, MonetizationController monetization, EconomyController economy) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(
            colors: [Color(0xFF004D40), Color(0xFF00796B)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 26,
              backgroundColor: AppTheme.accentAmber,
              child: Icon(Icons.video_library, color: Colors.black, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Watch Ad for Coins',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Earn +${AppConfig.coinsRewardedAd} coins immediately',
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentAmber,
                foregroundColor: Colors.black,
              ),
              onPressed: () {
                monetization.showRewardedAd(
                  onRewardEarned: () {
                    economy.addCoins(AppConfig.coinsRewardedAd);
                    Get.snackbar(
                      'Reward Claimed!',
                      '+${AppConfig.coinsRewardedAd} coins added to your balance!',
                      snackPosition: SnackPosition.BOTTOM,
                    );
                  },
                );
              },
              child: const Text('Watch', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRemoveAdsCard(BuildContext context, MonetizationController monetization) {
    return Obx(() {
      final isPurchased = monetization.isRemoveAdsPurchased.value;

      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              const CircleAvatar(
                radius: 24,
                backgroundColor: Colors.blueGrey,
                child: Icon(Icons.block, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Remove Ads',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isPurchased ? 'Already purchased!' : 'Permanently remove interstitial ads',
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: isPurchased ? null : () => _handleRemoveAdsBuy(monetization),
                child: Text(isPurchased ? 'Active' : '\$1.99'),
              ),
            ],
          ),
        ),
      );
    });
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
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: AppTheme.accentAmber.withValues(alpha: 0.2),
          child: Icon(icon, color: AppTheme.accentAmber),
        ),
        title: Row(
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            if (isPopular) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.accentAmber,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'POPULAR',
                  style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ],
        ),
        subtitle: Text('+$coins Coins'),
        trailing: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryTeal,
            foregroundColor: Colors.white,
          ),
          onPressed: onBuy,
          child: Text(price),
        ),
      ),
    );
  }

  void _handleCoinBuy(EconomyController economy, int coins) {
    economy.addCoins(coins);
    Get.snackbar(
      'Purchase Successful',
      '+$coins coins added to your wallet!',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void _handleRemoveAdsBuy(MonetizationController monetization) {
    monetization.isRemoveAdsPurchased.value = true;
    Get.find<HiveStorage>().setRemoveAds(true);
    Get.snackbar(
      'Ads Removed',
      'All interstitial ads have been disabled permanently!',
      snackPosition: SnackPosition.BOTTOM,
    );
  }
}
