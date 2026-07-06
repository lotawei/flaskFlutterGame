import 'package:get/get.dart';
import 'package:meme_game/core/content/meme_quotes.dart';
import 'package:meme_game/core/platform/screen_orientation_service.dart';
import 'package:meme_game/core/ui/app_loading_service.dart';

/// 结算页控制器。
class ResultController extends GetxController {
  final RxString reason = 'victory'.obs;
  final RxString levelId = ''.obs;
  final RxString levelName = ''.obs;
  final RxInt coins = 0.obs;
  final RxInt totalCoins = 0.obs;
  final RxDouble seconds = 0.0.obs;
  final RxInt stars = 0.obs;
  final RxString traceId = ''.obs;
  final RxString memeQuote = ''.obs;
  final RxString syncMessage = ''.obs;
  final RxnInt syncedTotalStars = RxnInt();
  final RxBool isLoggedIn = false.obs;

  @override
  void onInit() {
    super.onInit();
    ScreenOrientationService.lockPortrait();
    final Map<String, dynamic>? args =
        Get.arguments as Map<String, dynamic>?;
    reason.value = args?['reason'] as String? ?? 'victory';
    levelId.value = args?['levelId'] as String? ?? '';
    levelName.value = args?['levelName'] as String? ?? '';
    coins.value = args?['coins'] as int? ?? 0;
    totalCoins.value = args?['totalCoins'] as int? ?? 0;
    seconds.value = (args?['seconds'] as num?)?.toDouble() ?? 0;
    stars.value = args?['stars'] as int? ?? 0;
    traceId.value = args?['traceId'] as String? ?? '';
    syncMessage.value = args?['syncMessage'] as String? ?? '';
    syncedTotalStars.value = args?['syncedTotalStars'] as int?;
    isLoggedIn.value = args?['isLoggedIn'] as bool? ?? false;
    final int seed = DateTime.now().millisecondsSinceEpoch;
    if (isVictory) {
      memeQuote.value = MemeQuotes.pickVictoryQuote(seed);
    } else {
      memeQuote.value = MemeQuotes.pickFailQuote(reason: reason.value, seed: seed);
    }
  }

  bool get isVictory => reason.value == 'victory';

  String get titleText {
    if (isVictory) {
      return '搞事成功！';
    }
    if (reason.value == 'hitByEnemy') {
      return '被敌人搞了…';
    }
    if (reason.value == 'timeUp') {
      return '时间到了…';
    }
    if (reason.value == 'fakeGoal') {
      return '冲到假旗子了…';
    }
    return '搞事失败…';
  }

  void replay() {
    Get.offNamed<void>('/gameplay?levelId=${levelId.value}');
  }

  void goHome() {
    AppLoadingService.to.dismissAll();
    Get.offAllNamed<void>('/');
  }
}
