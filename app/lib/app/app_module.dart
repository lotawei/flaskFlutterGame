import 'package:get/get.dart';
import 'package:meme_game/core/config/app_config.dart';
import 'package:meme_game/core/network/api_client.dart';
import 'package:meme_game/core/observability/app_logger.dart';
import 'package:meme_game/features/home/binding.dart';
import 'package:meme_game/features/home/view.dart';

/// 应用路由与全局依赖。
class AppModule {
  static Future<void> init() async {
    final AppConfig config = AppConfig.fromEnvironment();
    final AppLogger logger = AppLogger(config);
    final ApiClient apiClient = ApiClient(config: config, logger: logger);
    Get.put<AppConfig>(config, permanent: true);
    Get.put<AppLogger>(logger, permanent: true);
    Get.put<ApiClient>(apiClient, permanent: true);
    logger.info(
      module: 'app.bootstrap',
      event: 'app.startup.completed',
      message: '客户端基座初始化完成',
      extra: <String, Object?>{
        'api_base_url': config.apiBaseUrl,
        'log_level': config.logLevel,
      },
    );
  }

  static List<GetPage<dynamic>> get pages => <GetPage<dynamic>>[
        GetPage<dynamic>(
          name: '/',
          page: () => const HomeView(),
          binding: HomeBinding(),
        ),
      ];
}
