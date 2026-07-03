import 'package:get/get.dart';
import 'package:meme_game/core/observability/app_logger.dart';
import 'package:meme_game/core/observability/trace_context.dart';
import 'package:meme_game/data/models/manifest_model.dart';
import 'package:meme_game/data/repositories/content_repository.dart';

/// 首页控制器：演示 manifest 拉取与日志追踪。
class HomeController extends GetxController {
  HomeController({
    required ContentRepository contentRepository,
    required AppLogger logger,
    this.shouldAutoLoad = true,
  })  : _contentRepository = contentRepository,
        _logger = logger;

  final ContentRepository _contentRepository;
  final AppLogger _logger;

  final RxBool isLoading = false.obs;
  final RxBool hasError = false.obs;
  final RxString errorMessage = ''.obs;
  final RxString serverVersion = ''.obs;
  final RxList<MemePackModel> packs = <MemePackModel>[].obs;
  final RxString lastTraceId = ''.obs;
  final bool shouldAutoLoad;

  @override
  void onInit() {
    super.onInit();
    if (shouldAutoLoad) {
      loadManifest();
    }
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
      _logger.info(
        module: 'features.home',
        event: 'home.manifest.load.completed',
        message: '首页 manifest 拉取成功',
        traceContext: traceContext,
        extra: <String, Object?>{'pack_count': manifest.packs.length},
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
