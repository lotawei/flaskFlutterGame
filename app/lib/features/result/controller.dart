import 'package:get/get.dart';
import 'package:meme_game/core/content/meme_quotes.dart';

/// 结算页控制器。
class ResultController extends GetxController {
  final RxString reason = 'victory'.obs;
  final RxString levelId = ''.obs;
  final RxString levelName = ''.obs;
  final RxInt coins = 0.obs;
  final RxInt totalCoins = 0.obs;
  final RxDouble seconds = 0.0.obs;
  final RxString traceId = ''.obs;
  final RxString memeQuote = ''.obs;

  @override
  void onInit() {
    super.onInit();
    final Map<String, dynamic>? args =
        Get.arguments as Map<String, dynamic>?;
    reason.value = args?['reason'] as String? ?? 'victory';
    levelId.value = args?['levelId'] as String? ?? '';
    levelName.value = args?['levelName'] as String? ?? '';
    coins.value = args?['coins'] as int? ?? 0;
    totalCoins.value = args?['totalCoins'] as int? ?? 0;
    seconds.value = (args?['seconds'] as num?)?.toDouble() ?? 0;
    traceId.value = args?['traceId'] as String? ?? '';
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
    return '搞事失败…';
  }

  void replay() {
    Get.offNamed<void>('/gameplay?levelId=${levelId.value}');
  }

  void goHome() {
    Get.offAllNamed<void>('/');
  }
}
