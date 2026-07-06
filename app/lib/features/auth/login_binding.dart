import 'package:get/get.dart';
import 'package:meme_game/core/observability/app_logger.dart';
import 'package:meme_game/data/repositories/auth_repository.dart';
import 'package:meme_game/features/auth/auth_controller.dart';
import 'package:meme_game/features/auth/login_controller.dart';

/// 登录页依赖注入。
class LoginBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<LoginController>(
      () => LoginController(
        authRepository: Get.find<AuthRepository>(),
        authController: Get.find<AuthController>(),
      ),
    );
  }
}
