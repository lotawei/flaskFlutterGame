import 'package:get/get.dart';
import 'package:meme_game/features/result/controller.dart';

/// 结算页依赖注入。
class ResultBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ResultController>(ResultController.new);
  }
}
