import 'package:get/get.dart';
import 'package:meme_game/core/observability/app_logger.dart';
import 'package:meme_game/core/observability/trace_context.dart';
import 'package:meme_game/data/models/manifest_model.dart';
import 'package:meme_game/data/repositories/content_repository.dart';
import 'package:meme_game/features/auth/auth_controller.dart';

/// 首页 Demo 关卡入口。
class DemoLevelEntry {
  const DemoLevelEntry({
    required this.levelId,
    required this.title,
    required this.subtitle,
  });

  final String levelId;
  final String title;
  final String subtitle;
}

/// 首页控制器：manifest + 账号 + 试玩入口。
class HomeController extends GetxController {
  HomeController({
    required ContentRepository contentRepository,
    required AuthController authController,
    required AppLogger logger,
    this.shouldAutoLoad = true,
  })  : _contentRepository = contentRepository,
        _authController = authController,
        _logger = logger;

  final ContentRepository _contentRepository;
  final AuthController _authController;
  final AppLogger _logger;

  final RxBool isLoading = false.obs;
  final RxBool hasError = false.obs;
  final RxString errorMessage = ''.obs;
  final RxString serverVersion = ''.obs;
  final RxList<MemePackModel> packs = <MemePackModel>[].obs;
  final RxString lastTraceId = ''.obs;
  final bool shouldAutoLoad;

  static const List<DemoLevelEntry> demoLevels = <DemoLevelEntry>[
    DemoLevelEntry(
      levelId: 'demo_haqi',
      title: '哈基高原',
      subtitle: '先跑起来！冲过陷阱，摸到旗子就赢',
    ),
    DemoLevelEntry(
      levelId: 'timed_rush_demo',
      title: '读秒冲刺',
      subtitle: '60 秒内必须到终点，晚一秒都不行',
    ),
    DemoLevelEntry(
      levelId: 'reversal_trap_demo',
      title: '假旗反转',
      subtitle: '路上旗帜可能是假的，找到真终点',
    ),
    DemoLevelEntry(
      levelId: 'greed_tax_demo',
      title: '来财税局',
      subtitle: '金币拿太多？难度也会跟着涨',
    ),
    DemoLevelEntry(
      levelId: 'lie_flat_demo',
      title: '躺平计量',
      subtitle: '走停节奏，别急着送人头',
    ),
  ];

  AuthController get authController => _authController;

  @override
  void onInit() {
    super.onInit();
    if (shouldAutoLoad) {
      loadManifest();
    }
  }

  void openLogin() {
    Get.toNamed<void>('/login');
  }

  Future<void> logout() async {
    await _authController.logout();
    await loadManifest();
  }

  void startLevel(String levelId) {
    Get.toNamed<void>('/gameplay?levelId=$levelId');
  }

  void startDemoLevel() {
    startLevel('demo_haqi');
  }

  Future<void> loadManifest() async {
    isLoading.value = true;
    hasError.value = false;
    errorMessage.value = '';
    final TraceContext traceContext = TraceContext.create();
    lastTraceId.value = traceContext.traceId;
    _logger.info(
      module: 'features.home',
      event: 'home.manifest.load.started',
      message: '首页开始拉取 manifest',
      traceContext: traceContext,
    );
    try {
      final ManifestModel manifest = await _contentRepository.fetchManifest(
        traceContext: traceContext,
        clientVersion: '1.0.0',
      );
      serverVersion.value = manifest.serverVersion;
      packs.assignAll(manifest.packs);
      await _authController.applyManifestUser(manifest.user);
      if (_authController.isLoggedIn.value) {
        await _authController.refreshProgress(traceContext: traceContext);
      }
      _logger.info(
        module: 'features.home',
        event: 'home.manifest.load.completed',
        message: '首页 manifest 拉取成功',
        traceContext: traceContext,
        extra: <String, Object?>{
          'pack_count': manifest.packs.length,
          'is_logged_in': _authController.isLoggedIn.value,
        },
      );
    } catch (err) {
      hasError.value = true;
      errorMessage.value = err.toString();
      _logger.error(
        module: 'features.home',
        event: 'home.manifest.load.failed',
        message: '首页 manifest 拉取失败',
        traceContext: traceContext,
        extra: <String, Object?>{'error_message': err.toString()},
      );
    } finally {
      isLoading.value = false;
    }
  }
}
