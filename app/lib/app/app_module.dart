import 'package:get/get.dart';
import 'package:meme_game/core/config/app_config.dart';
import 'package:meme_game/core/network/api_client.dart';
import 'package:meme_game/core/observability/app_logger.dart';
import 'package:meme_game/data/repositories/auth_repository.dart';
import 'package:meme_game/data/repositories/progress_repository.dart';
import 'package:meme_game/data/services/auth_token_storage.dart';
import 'package:meme_game/features/auth/auth_controller.dart';
import 'package:meme_game/features/auth/login_binding.dart';
import 'package:meme_game/features/auth/login_view.dart';
import 'package:meme_game/features/gameplay/binding.dart';
import 'package:meme_game/features/gameplay/view.dart';
import 'package:meme_game/features/home/binding.dart';
import 'package:meme_game/features/home/view.dart';
import 'package:meme_game/features/result/binding.dart';
import 'package:meme_game/features/result/view.dart';

/// 应用路由与全局依赖。
class AppModule {
  static Future<void> init() async {
    final AppConfig config = AppConfig.fromEnvironment();
    final AppLogger logger = AppLogger(config);
    final AuthTokenStorage tokenStorage = AuthTokenStorage();
    final ApiClient apiClient = ApiClient(config: config, logger: logger);
    final AuthRepository authRepository = AuthRepository(
      apiClient: apiClient,
      tokenStorage: tokenStorage,
      logger: logger,
    );
    final ProgressRepository progressRepository = ProgressRepository(
      apiClient: apiClient,
      logger: logger,
    );
    final AuthController authController = AuthController(
      authRepository: authRepository,
      progressRepository: progressRepository,
      logger: logger,
    );
    Get.put<AppConfig>(config, permanent: true);
    Get.put<AppLogger>(logger, permanent: true);
    Get.put<AuthTokenStorage>(tokenStorage, permanent: true);
    Get.put<ApiClient>(apiClient, permanent: true);
    Get.put<AuthRepository>(authRepository, permanent: true);
    Get.put<ProgressRepository>(progressRepository, permanent: true);
    Get.put<AuthController>(authController, permanent: true);
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
        GetPage<dynamic>(
          name: '/login',
          page: () => const LoginView(),
          binding: LoginBinding(),
        ),
        GetPage<dynamic>(
          name: '/gameplay',
          page: () => const GameplayView(),
          binding: GameplayBinding(),
        ),
        GetPage<dynamic>(
          name: '/result',
          page: () => const ResultView(),
          binding: ResultBinding(),
        ),
      ];
}
