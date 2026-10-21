import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:jigsaw_pro/core/config/app_config.dart';
import 'package:jigsaw_pro/core/storage/hive_storage.dart';
import 'package:jigsaw_pro/features/economy/presentation/controllers/economy_controller.dart';

class MonetizationController extends GetxController {
  final HiveStorage _storage;
  final EconomyController _economy;

  MonetizationController(this._storage, this._economy);

  late final RxBool isRemoveAdsPurchased;
  final RxBool isRewardedAdReady = false.obs;
  final RxBool isPurchasing = false.obs;

  bool get isMobilePlatform => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  // Interstitial frequency tracking
  static int _sessionCompletedCount = 0;
  static bool _isFirstSession = true;

  RewardedAd? _rewardedAd;
  InterstitialAd? _interstitialAd;

  final InAppPurchase _iap = InAppPurchase.instance;
  final RxList<ProductDetails> availableProducts = <ProductDetails>[].obs;

  @override
  void onInit() {
    super.onInit();
    isRemoveAdsPurchased = _storage.removeAds.obs;
    _initMobileAds();
    _initInAppPurchases();
  }

  Future<void> _initMobileAds() async {
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

  void loadRewardedAd() {
    if (!isMobilePlatform) return;
    RewardedAd.load(
      adUnitId: AppConfig.testRewardedId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          isRewardedAdReady.value = true;
        },
        onAdFailedToLoad: (error) {
          debugPrint('Rewarded ad failed to load: $error');
          _rewardedAd = null;
          isRewardedAdReady.value = false;
        },
      ),
    );
  }

  void showRewardedAd({required void Function() onRewardEarned}) {
    if (!isMobilePlatform || _rewardedAd == null) {
      // In case ads fail, offline, or running on desktop/web: gracefully deliver reward
      debugPrint('Rewarded ad fallback delivered.');
      onRewardEarned();
      if (isMobilePlatform) loadRewardedAd();
      return;
    }

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewardedAd = null;
        isRewardedAdReady.value = false;
        loadRewardedAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _rewardedAd = null;
        isRewardedAdReady.value = false;
        loadRewardedAd();
      },
    );

    _rewardedAd!.show(
      onUserEarnedReward: (ad, reward) {
        onRewardEarned();
      },
    );
  }

  void _preloadInterstitial() {
    if (!isMobilePlatform || isRemoveAdsPurchased.value) return;

    InterstitialAd.load(
      adUnitId: AppConfig.testInterstitialId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
        },
        onAdFailedToLoad: (error) {
          debugPrint('Interstitial failed to load: $error');
          _interstitialAd = null;
        },
      ),
    );
  }

  /// Evaluates frequency capping:
  /// - At most once every 3 completed puzzles
  /// - Never in session 1
  /// - Never if removeAds is purchased
  void onPuzzleCompleted() {
    _sessionCompletedCount++;

    if (!isMobilePlatform || isRemoveAdsPurchased.value) return;
    if (_isFirstSession) {
      // PRD/TRD rule: never in the first session!
      return;
    }

    if (_sessionCompletedCount % AppConfig.interstitialPuzzleFrequency == 0) {
      _showInterstitial();
    }
  }

  void markSessionOneFinished() {
    _isFirstSession = false;
  }

  void _showInterstitial() {
    if (_interstitialAd != null) {
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _interstitialAd = null;
          _preloadInterstitial();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          ad.dispose();
          _interstitialAd = null;
          _preloadInterstitial();
        },
      );
      _interstitialAd!.show();
    }
  }

  // --- In-App Purchases ---
  Future<void> _initInAppPurchases() async {
    if (!isMobilePlatform) return;
    try {
      final available = await _iap.isAvailable();
      if (!available) return;

      const ids = <String>{
        AppConfig.iapRemoveAds,
        AppConfig.iapCoinsSmall,
        AppConfig.iapCoinsMedium,
        AppConfig.iapCoinsLarge,
      };

      final response = await _iap.queryProductDetails(ids);
      availableProducts.assignAll(response.productDetails);

      _iap.purchaseStream.listen(_handlePurchaseUpdates);
    } catch (e) {
      debugPrint('IAP init error: $e');
    }
  }

  void _handlePurchaseUpdates(List<PurchaseDetails> purchaseDetailsList) {
    for (final purchase in purchaseDetailsList) {
      if (purchase.status == PurchaseStatus.purchased || purchase.status == PurchaseStatus.restored) {
        _deliverProduct(purchase.productID);
        if (purchase.pendingCompletePurchase) {
          _iap.completePurchase(purchase);
        }
      }
    }
  }

  void _deliverProduct(String productId) {
    if (productId == AppConfig.iapRemoveAds) {
      isRemoveAdsPurchased.value = true;
      _storage.setRemoveAds(true);
    } else if (productId == AppConfig.iapCoinsSmall) {
      _economy.addCoins(AppConfig.coinsPackSmallAmount);
    } else if (productId == AppConfig.iapCoinsMedium) {
      _economy.addCoins(AppConfig.coinsPackMediumAmount);
    } else if (productId == AppConfig.iapCoinsLarge) {
      _economy.addCoins(AppConfig.coinsPackLargeAmount);
    }
  }

  Future<void> buyProduct(ProductDetails product) async {
    isPurchasing.value = true;
    try {
      final purchaseParam = PurchaseParam(productDetails: product);
      if (product.id == AppConfig.iapRemoveAds) {
        await _iap.buyNonConsumable(purchaseParam: purchaseParam);
      } else {
        await _iap.buyConsumable(purchaseParam: purchaseParam);
      }
    } catch (e) {
      debugPrint('Purchase error: $e');
    } finally {
      isPurchasing.value = false;
    }
  }

  Future<void> restorePurchases() async {
    try {
      await _iap.restorePurchases();
    } catch (e) {
      debugPrint('Restore error: $e');
    }
  }

  @override
  void onClose() {
    _rewardedAd?.dispose();
    _interstitialAd?.dispose();
    super.onClose();
  }
}
