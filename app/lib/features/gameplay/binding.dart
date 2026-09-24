import 'package:get/get.dart';
import 'package:meme_game/core/network/api_client.dart';
import 'package:meme_game/core/observability/app_logger.dart';
import 'package:meme_game/data/repositories/level_repository.dart';
import 'package:meme_game/data/services/content_cache_service.dart';
import 'package:meme_game/features/gameplay/controller.dart';

/// 闯关页依赖注入。
class GameplayBinding extends Bindings {
  @override
  void dependencies() {
    final AppLogger logger = Get.find<AppLogger>();
    final ApiClient apiClient = Get.find<ApiClient>();
    final ContentCacheService cacheService = ContentCacheService(logger: logger);
    final LevelRepository levelRepository = LevelRepository(
      apiClient: apiClient,
      logger: logger,
      cacheService: cacheService,
    );
    Get.lazyPut<GameplayController>(
      () => GameplayController(
        levelRepository: levelRepository,
        logger: logger,
      ),
    );
  }
}
