import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:jigsaw_pro/core/config/app_config.dart';
import 'package:jigsaw_pro/core/storage/hive_storage.dart';

class EconomyController extends GetxController {
  final HiveStorage _storage;

  EconomyController(this._storage);

  late final RxInt coins;
  late final RxInt streak;
  late final RxBool canClaimDaily;

  @override
  void onInit() {
    super.onInit();
    coins = _storage.coins.obs;
    streak = _storage.streak.obs;
    canClaimDaily = _checkCanClaimDaily().obs;
  }

  bool _checkCanClaimDaily() {
    final lastClaim = _storage.lastDailyClaim;
    if (lastClaim == null) return true;

    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return lastClaim != today;
  }

  bool spendCoins(int amount) {
    if (coins.value >= amount) {
      coins.value -= amount;
      _storage.setCoins(coins.value);
      return true;
    }
    return false;
  }

  void addCoins(int amount) {
    coins.value += amount;
    _storage.setCoins(coins.value);
  }

  bool claimDailyBonus() {
    if (!canClaimDaily.value) return false;

    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    _storage.setLastDailyClaim(today);

    // Increment streak
    streak.value += 1;
    _storage.setStreak(streak.value);

    addCoins(AppConfig.coinsDailyBonus);
    canClaimDaily.value = false;
    return true;
  }

  void rewardPuzzleComplete(int pieceCount, {bool isDaily = false}) {
    int reward;
    if (pieceCount <= 24) {
      reward = AppConfig.coinsFinish12or24;
    } else if (pieceCount <= 100) {
      reward = AppConfig.coinsFinish48or100;
    } else if (pieceCount <= 200) {
      reward = AppConfig.coinsFinish200;
    } else {
      reward = AppConfig.coinsFinish400;
    }

    if (isDaily) {
      reward += AppConfig.coinsDailyBonus;
    }

    addCoins(reward);
  }
}
