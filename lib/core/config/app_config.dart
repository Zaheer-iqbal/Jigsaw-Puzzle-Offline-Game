/// Global application configuration and tuneable game parameters.
/// Everything is centralized here for easy tuning per PRD & TRD specs.
class AppConfig {
  AppConfig._();

  static const String appName = 'Jigsaw Puzzle: Offline Game';
  static const String appVersion = '1.0.0';

  // Economy tuning values
  static const int startingCoins = 50;
  static const int coinsFinish12or24 = 10;
  static const int coinsFinish48or100 = 25;
  static const int coinsFinish200 = 50;
  static const int coinsFinish400 = 100;
  static const int coinsDailyBonus = 20;
  static const int coinsRewardedAd = 30;
  static const int coinsHintCost = 15;
  static const int coinsUnlockPremium = 50;

  // Snapping & Puzzle Engine parameters
  static const double snapThresholdRatio = 0.28; // ~28% of min(pieceW, pieceH)
  static const double minZoomScale = 0.2;
  static const double maxZoomScale = 4.0;
  static const double tabOverhangRatio = 1.33;
  static const double tabHeightRatio = 0.95;
  static const int hintDurationMs = 2500;

  // Monetization & Ads capping (Disabled for 100% clean experience and Play Store compliance)
  static const bool enableAds = false;

  // Interstitial: at most once every 3 completed puzzles, never in session 1
  static const int interstitialPuzzleFrequency = 3;

  // Google AdMob Production IDs
  static const String adMobAppId = 'ca-app-pub-4263353235645949~8949678814';
  static const String rewardedAdUnitId = 'ca-app-pub-4263353235645949/3976553734';
  static const String interstitialAdUnitId = 'ca-app-pub-4263353235645949/5840299748';
  static const String bannerAdUnitId = 'ca-app-pub-4263353235645949/1410100144';

  // Google Test Ad Unit IDs (fallback during development)
  static const String testBannerId = 'ca-app-pub-3940256099942544/6300978111';
  static const String testInterstitialId = 'ca-app-pub-3940256099942544/1033173712';
  static const String testRewardedId = 'ca-app-pub-3940256099942544/5224354917';

  // In-App Purchase Product IDs
  static const String iapRemoveAds = 'remove_ads';
  static const String iapCoinsSmall = 'coins_small';     // +200 coins
  static const String iapCoinsMedium = 'coins_medium';   // +600 coins
  static const String iapCoinsLarge = 'coins_large';     // +1500 coins

  static const int coinsPackSmallAmount = 200;
  static const int coinsPackMediumAmount = 600;
  static const int coinsPackLargeAmount = 1500;

  // Fixed epoch for deterministic offline daily puzzle
  static final DateTime dailyEpoch = DateTime(2025, 1, 1);
}
