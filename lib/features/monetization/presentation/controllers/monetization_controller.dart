import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:jigsaw_pro/core/audio/audio_service.dart';
import 'package:jigsaw_pro/core/config/app_config.dart';
import 'package:jigsaw_pro/core/haptics/haptic_service.dart';
import 'package:jigsaw_pro/core/router/app_router.dart';
import 'package:jigsaw_pro/core/storage/hive_storage.dart';
import 'package:jigsaw_pro/features/economy/presentation/controllers/economy_controller.dart';

class MonetizationController extends GetxController {
  final HiveStorage _storage;
  final EconomyController _economy;

  MonetizationController(this._storage, this._economy);

  late final RxBool isRemoveAdsPurchased;
  late final RxInt removeAdsProgress;
  final RxBool isRewardedAdReady = false.obs;

  bool get isMobilePlatform => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  // Interstitial frequency tracking
  static int _sessionCompletedCount = 0;
  static bool _isFirstSession = true;

  RewardedAd? _rewardedAd;
  InterstitialAd? _interstitialAd;

  @override
  void onInit() {
    super.onInit();
    isRemoveAdsPurchased = _storage.removeAds.obs;
    removeAdsProgress = _storage.removeAdsProgress.obs;
    _initMobileAds();
  }

  Future<void> _initMobileAds() async {
    if (!AppConfig.enableAds) {
      debugPrint('MobileAds disabled: AppConfig.enableAds is false.');
      return;
    }
    if (!isMobilePlatform) {
      debugPrint('MobileAds skipped: running on non-mobile platform.');
      return;
    }
    try {
      await MobileAds.instance.initialize();
      loadRewardedAd();
      _preloadInterstitial();
    } catch (e) {
      debugPrint('MobileAds init error: $e');
    }
  }

  String get _rewardedAdUnitId =>
      kDebugMode ? AppConfig.testRewardedId : AppConfig.rewardedAdUnitId;

  String get _interstitialAdUnitId =>
      kDebugMode ? AppConfig.testInterstitialId : AppConfig.interstitialAdUnitId;

  void loadRewardedAd() {
    if (!isMobilePlatform) return;
    debugPrint('Loading Rewarded Ad with unit ID: $_rewardedAdUnitId (debugMode: $kDebugMode)');
    RewardedAd.load(
      adUnitId: _rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          isRewardedAdReady.value = true;
          debugPrint('AdMob Rewarded Ad loaded successfully.');
        },
        onAdFailedToLoad: (error) {
          debugPrint('Rewarded ad failed to load: $error');
          _rewardedAd = null;
          isRewardedAdReady.value = false;
          // Retry loading after a delay
          Future.delayed(const Duration(seconds: 20), () {
            if (_rewardedAd == null && isMobilePlatform) {
              loadRewardedAd();
            }
          });
        },
      ),
    );
  }

  void _pauseBgm() {
    if (Get.isRegistered<AudioService>()) {
      Get.find<AudioService>().pauseBgm();
    }
  }

  void _resumeBgm() {
    if (Get.isRegistered<AudioService>()) {
      Get.find<AudioService>().resumeBgm();
    }
  }

  /// Displays real Google AdMob Rewarded Ad on mobile devices,
  /// or opens an authentic interactive Video Ad player simulation dialog on desktop/test mode.
  void showRewardedAd({
    BuildContext? context,
    required void Function() onRewardEarned,
    String rewardTitle = 'Reward',
  }) {
    if (!AppConfig.enableAds) {
      HapticFeedback.lightImpact();
      onRewardEarned();
      Get.snackbar(
        'Reward Granted! 🎁',
        '$rewardTitle claimed successfully.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xEE112238),
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
      return;
    }

    _pauseBgm();

    // 1. If mobile and real ad is ready, show Google Mobile Ads
    if (isMobilePlatform && _rewardedAd != null) {
      _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _rewardedAd = null;
          isRewardedAdReady.value = false;
          _resumeBgm();
          loadRewardedAd();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          ad.dispose();
          _rewardedAd = null;
          isRewardedAdReady.value = false;
          _resumeBgm();
          loadRewardedAd();
          onRewardEarned();
        },
      );

      _rewardedAd!.show(
        onUserEarnedReward: (ad, reward) {
          onRewardEarned();
        },
      );
      return;
    }

    // 2. Otherwise (Desktop, Simulator, or Ad currently loading):
    _showSimulatedRewardedAdDialog(context, () {
      _resumeBgm();
      onRewardEarned();
    }, rewardTitle);
  }

  void _showSimulatedRewardedAdDialog(
    BuildContext? context,
    void Function() onRewardEarned,
    String rewardTitle,
  ) {
    final ctx = context ?? AppRouter.navigatorKey.currentContext;
    if (ctx == null) {
      onRewardEarned();
      return;
    }

    var countdown = 5;
    Timer? timer;
    final rxCountdown = 5.obs;
    final rxCanClose = false.obs;

    showDialog(
      context: ctx,
      barrierDismissible: false,
      builder: (dialogCtx) => PopScope(
        canPop: false,
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF111E2E),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: const Color(0xFFFFB300), width: 2),
              boxShadow: const [
                BoxShadow(color: Color(0x66000000), blurRadius: 24, offset: Offset(0, 10)),
              ],
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Ad Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFB300),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'AdMob Video Sponsor',
                        style: TextStyle(color: Color(0xFF0E2A47), fontSize: 11, fontWeight: FontWeight.w900),
                      ),
                    ),
                    Obx(() {
                      if (!rxCanClose.value) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white12,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            'Reward in ${rxCountdown.value}s',
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        );
                      }
                      return GestureDetector(
                        onTap: () {
                          timer?.cancel();
                          Get.back();
                          onRewardEarned();
                        },
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Color(0xFF00E676),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.check_rounded, color: Color(0xFF0E2A47), size: 18),
                        ),
                      );
                    }),
                  ],
                ),
                const SizedBox(height: 18),

                // Video Ad Screen Simulation
                Container(
                  height: 170,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0288D1), Color(0xFF5C6BC0)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.ondemand_video_rounded, color: Colors.white, size: 54),
                          const SizedBox(height: 10),
                          const Text(
                            'High Earning Video Sponsor',
                            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Watch full video to claim $rewardTitle',
                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                      Positioned(
                        bottom: 12,
                        left: 16,
                        right: 16,
                        child: Obx(() => ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: (5 - rxCountdown.value) / 5.0,
                                minHeight: 6,
                                backgroundColor: Colors.white24,
                                valueColor: const AlwaysStoppedAnimation(Color(0xFFFFB300)),
                              ),
                            )),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Bottom Callout
                Obx(() {
                  if (!rxCanClose.value) {
                    return Text(
                      'Watching sponsor video... (${rxCountdown.value}s)',
                      style: const TextStyle(color: Colors.white60, fontSize: 13, fontWeight: FontWeight.w600),
                    );
                  }
                  return ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFB300),
                      foregroundColor: const Color(0xFF0E2A47),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    icon: const Icon(Icons.card_giftcard_rounded),
                    label: Text('Claim $rewardTitle', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                    onPressed: () {
                      timer?.cancel();
                      Navigator.pop(dialogCtx);
                      onRewardEarned();
                    },
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );

    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      countdown--;
      rxCountdown.value = countdown;
      if (countdown <= 0) {
        t.cancel();
        rxCanClose.value = true;
      }
    });

    if (isMobilePlatform) loadRewardedAd();
  }

  void _preloadInterstitial() {
    if (!isMobilePlatform || isRemoveAdsPurchased.value) return;

    debugPrint('Loading Interstitial Ad with unit ID: $_interstitialAdUnitId (debugMode: $kDebugMode)');
    InterstitialAd.load(
      adUnitId: _interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          debugPrint('AdMob Interstitial Ad loaded.');
        },
        onAdFailedToLoad: (error) {
          debugPrint('Interstitial failed to load: $error');
          _interstitialAd = null;
          // Retry loading after a delay
          Future.delayed(const Duration(seconds: 30), () {
            if (_interstitialAd == null && isMobilePlatform && !isRemoveAdsPurchased.value) {
              _preloadInterstitial();
            }
          });
        },
      ),
    );
  }

  void onPuzzleCompleted() {
    if (!AppConfig.enableAds) return;
    _sessionCompletedCount++;

    if (isRemoveAdsPurchased.value) return;
    if (_isFirstSession) {
      _isFirstSession = false;
      return;
    }

    if (_sessionCompletedCount % AppConfig.interstitialPuzzleFrequency == 0) {
      _showInterstitial();
    }
  }

  void _showInterstitial() {
    if (isMobilePlatform && _interstitialAd != null) {
      _pauseBgm();
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _interstitialAd = null;
          _resumeBgm();
          _preloadInterstitial();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          ad.dispose();
          _interstitialAd = null;
          _resumeBgm();
          _preloadInterstitial();
        },
      );
      _interstitialAd!.show();
    }
  }

  /// Claim Coin Pack by watching a high-reward AdMob video ad (100% Free, NO payment!)
  void claimCoinPackViaAd(
    BuildContext context, {
    required int coins,
    required String packTitle,
  }) {
    showRewardedAd(
      context: context,
      rewardTitle: '+$coins Coins ($packTitle)',
      onRewardEarned: () {
        _economy.addCoins(coins);
        if (Get.isRegistered<AudioService>()) {
          Get.find<AudioService>().playWin();
        }
        if (Get.isRegistered<HapticService>()) {
          Get.find<HapticService>().win();
        }
        Get.snackbar(
          '🎉 +$coins Coins Received!',
          '$packTitle has been added to your balance for free!',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFF00C853),
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
      },
    );
  }

  /// Watch High-Reward Video Ad to unlock Remove Ads permanently!
  /// Requires 3 video views, generating maximum revenue for the developer without any payments.
  void watchAdForRemoveAds(BuildContext context) {
    if (isRemoveAdsPurchased.value) return;

    final current = removeAdsProgress.value;
    final next = current + 1;

    showRewardedAd(
      context: context,
      rewardTitle: 'Ad-Free Progress ($next/3)',
      onRewardEarned: () {
        removeAdsProgress.value = next;
        _storage.setRemoveAdsProgress(next);

        if (next >= 3) {
          isRemoveAdsPurchased.value = true;
          _storage.setRemoveAds(true);
          if (Get.isRegistered<AudioService>()) {
            Get.find<AudioService>().playWin();
          }
          if (Get.isRegistered<HapticService>()) {
            Get.find<HapticService>().win();
          }
          Get.snackbar(
            '🌟 Ad-Free VIP Unlocked!',
            'Congratulations! All interstitial ads have been permanently removed.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: const Color(0xFF00C853),
            colorText: Colors.white,
            duration: const Duration(seconds: 4),
          );
        } else {
          if (Get.isRegistered<AudioService>()) {
            Get.find<AudioService>().playClick();
          }
          if (Get.isRegistered<HapticService>()) {
            Get.find<HapticService>().snap();
          }
          Get.snackbar(
            '🎬 Video Watched ($next/3)!',
            'Watch ${3 - next} more high-reward video(s) to unlock Ad-Free mode permanently!',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: const Color(0xEE112238),
            colorText: Colors.white,
            duration: const Duration(seconds: 3),
          );
        }
      },
    );
  }
}
