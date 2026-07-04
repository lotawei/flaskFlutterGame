import 'package:meme_game/core/network/api_client.dart';
import 'package:meme_game/core/observability/app_logger.dart';
import 'package:meme_game/core/observability/trace_context.dart';
import 'package:meme_game/data/models/auth_model.dart';

/// 用户进度仓库。
class ProgressRepository {
  ProgressRepository({
    required ApiClient apiClient,
    required AppLogger logger,
  })  : _apiClient = apiClient,
        _logger = logger;

  final ApiClient _apiClient;
  final AppLogger _logger;

  Future<UserProgressModel> fetchProgress({
    required TraceContext traceContext,
  }) async {
    final response = await _apiClient.getJson(
      path: '/api/v1/users/me/progress',
      traceContext: traceContext,
    );
    final Map<String, dynamic>? body = response.data;
    if (body == null || body['code'] != 0) {
      throw StateError(body?['message'] as String? ?? '进度拉取失败');
    }
    return UserProgressModel.fromJson(
      body['data'] as Map<String, dynamic>? ?? <String, dynamic>{},
    );
  }

  Future<SessionSubmitResultModel> submitSession({
    required TraceContext traceContext,
    required String levelId,
    required String reason,
    required int coins,
    required int totalCoins,
    required double seconds,
    required int stars,
    required int defeatedEnemies,
  }) async {
    final response = await _apiClient.postJson(
      path: '/api/v1/users/me/sessions',
      traceContext: traceContext,
      body: <String, Object?>{
        'level_id': levelId,
        'reason': reason,
        'coins': coins,
        'total_coins': totalCoins,
        'seconds': seconds,
        'stars': stars,
        'defeated_enemies': defeatedEnemies,
        'trace_id': traceContext.traceId,
      },
    );
    final Map<String, dynamic>? body = response.data;
    if (body == null || body['code'] != 0) {
      throw StateError(body?['message'] as String? ?? '对局上报失败');
    }
    _logger.info(
      module: 'data.progress',
      event: 'game.session.submitted',
      message: '对局已同步到账号',
      traceContext: traceContext,
      extra: <String, Object?>{
        'level_id': levelId,
        'reason': reason,
        'stars': stars,
      },
    );
    return SessionSubmitResultModel.fromJson(
      body['data'] as Map<String, dynamic>? ?? <String, dynamic>{},
    );
  }
}
