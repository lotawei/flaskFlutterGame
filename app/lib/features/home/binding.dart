import 'package:get/get.dart';
import 'package:meme_game/core/network/api_client.dart';
import 'package:meme_game/core/observability/app_logger.dart';
import 'package:meme_game/data/repositories/content_repository.dart';
import 'package:meme_game/features/auth/auth_controller.dart';
import 'package:meme_game/features/home/controller.dart';

/// 首页依赖注入。
class HomeBinding extends Bindings {
  @override
  void dependencies() {
    final AppLogger logger = Get.find<AppLogger>();
    final ApiClient apiClient = Get.find<ApiClient>();
    final ContentRepository repository = ContentRepository(
      apiClient: apiClient,
      logger: logger,
    );
    Get.lazyPut<HomeController>(
      () => HomeController(
        contentRepository: repository,
        authController: Get.find<AuthController>(),
        logger: logger,
      ),
    );
  }
}
