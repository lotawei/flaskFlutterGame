import 'package:get/get.dart';

/// 全局 Loading 服务（单例，引用计数支持嵌套 show/dismiss）。
class AppLoadingService extends GetxService {
  static AppLoadingService get to => Get.find<AppLoadingService>();

  final RxBool isVisible = false.obs;
  final RxString message = '加载中…'.obs;
  int _refCount = 0;

  void show({String message = '加载中…'}) {
    _refCount += 1;
    this.message.value = message;
    isVisible.value = true;
  }

  void dismiss() {
    if (_refCount <= 0) {
      return;
    }
    _refCount -= 1;
    if (_refCount == 0) {
      isVisible.value = false;
    }
  }

  void dismissAll() {
    _refCount = 0;
    isVisible.value = false;
  }
}
