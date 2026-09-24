import 'package:meme_game/core/level/level_loader.dart';
import 'package:meme_game/core/level/level_model.dart';
import 'package:meme_game/core/network/api_client.dart';
import 'package:meme_game/core/observability/app_logger.dart';
import 'package:meme_game/core/observability/flow_tracer.dart';
import 'package:meme_game/core/observability/trace_context.dart';
import 'package:meme_game/data/services/content_cache_service.dart';

/// 关卡数据仓库：缓存 → 内置资源 → 远程 API。
class LevelRepository {
  LevelRepository({
    required ApiClient apiClient,
    required AppLogger logger,
    required ContentCacheService cacheService,
    LevelLoader? levelLoader,
  })  : _apiClient = apiClient,
        _logger = logger,
        _cacheService = cacheService,
        _levelLoader = levelLoader ?? LevelLoader();

  final ApiClient _apiClient;
  final AppLogger _logger;
  final ContentCacheService _cacheService;
  final LevelLoader _levelLoader;

  static const Map<String, String> _bundledLevels = <String, String>{
    'demo_haqi': 'assets/levels/demo_haqi.json',
    'timed_rush_demo': 'assets/levels/timed_rush_demo.json',
    'reversal_trap_demo': 'assets/levels/reversal_trap_demo.json',
    'greed_tax_demo': 'assets/levels/greed_tax_demo.json',
    'lie_flat_demo': 'assets/levels/lie_flat_demo.json',
  };

  Future<LevelModel> loadLevel({
    required String levelId,
    required TraceContext traceContext,
  }) async {
    final FlowTracer tracer = FlowTracer(
      logger: _logger,
      module: 'data.level',
      flowName: 'game.level.load',
      traceContext: traceContext,
    );
    return tracer.runStep<LevelModel>(
      stepName: 'resolve_source',
      extra: <String, Object?>{'level_id': levelId},
      action: (TraceContext spanContext) async {
        final String? cached = await _readCachedLevel(levelId);
        if (cached != null) {
          return _levelLoader.loadFromJsonString(cached);
        }
        try {
          return await _loadRemoteLevel(
            levelId: levelId,
            traceContext: spanContext,
          );
        } catch (_) {
          final String? bundledPath = _bundledLevels[levelId];
          if (bundledPath == null) {
            rethrow;
          }
          _logger.warn(
            module: 'data.level',
            event: 'game.level.load.fallback_asset',
            message: '远程失败，回退内置关卡',
            traceContext: spanContext,
            extra: <String, Object?>{'level_id': levelId},
          );
          return _levelLoader.loadFromAsset(bundledPath);
        }
      },
    );
  }

  Future<String?> _readCachedLevel(String levelId) async {
    final file = await _cacheService.readLevelFile(levelId);
    if (file == null) {
      return null;
    }
    return file.readAsStringSync();
  }

  Future<LevelModel> _loadRemoteLevel({
    required String levelId,
    required TraceContext traceContext,
  }) async {
    final response = await _apiClient.getJson(
      path: '/api/v1/content/levels/$levelId',
      traceContext: traceContext,
    );
    final Map<String, dynamic>? body = response.data;
    if (body == null || body['code'] != 0) {
      throw StateError('远程关卡加载失败: $levelId');
    }
    final Map<String, dynamic>? data = body['data'] as Map<String, dynamic>?;
    if (data == null) {
      throw StateError('远程关卡 data 为空');
    }
    await _cacheService.saveLevel(
      levelId: levelId,
      rawJson: encodeLevelJson(data),
    );
    return LevelModel.fromJson(data);
  }
}
