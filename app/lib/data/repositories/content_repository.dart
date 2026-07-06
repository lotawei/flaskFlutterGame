import 'package:meme_game/core/network/api_client.dart';
import 'package:meme_game/core/observability/app_logger.dart';
import 'package:meme_game/core/observability/flow_tracer.dart';
import 'package:meme_game/core/observability/trace_context.dart';
import 'package:meme_game/data/models/manifest_model.dart';

/// 内容域数据仓库：负责 manifest 远程拉取。
class ContentRepository {
  ContentRepository({
    required ApiClient apiClient,
    required AppLogger logger,
  })  : _apiClient = apiClient,
        _logger = logger;

  final ApiClient _apiClient;
  final AppLogger _logger;

  Future<ManifestModel> fetchManifest({
    required TraceContext traceContext,
    String? clientVersion,
  }) async {
    final FlowTracer tracer = FlowTracer(
      logger: _logger,
      module: 'data.content',
      flowName: 'content.manifest.fetch',
      traceContext: traceContext,
    );
    return tracer.runStep<ManifestModel>(
      stepName: 'request_api',
      extra: <String, Object?>{'client_version': clientVersion},
      action: (TraceContext spanContext) async {
        final response = await _apiClient.getJson(
          path: '/api/v1/content/manifest',
          traceContext: spanContext,
          queryParameters: clientVersion == null
              ? null
              : <String, dynamic>{'client_version': clientVersion},
        );
        final Map<String, dynamic>? body = response.data;
        if (body == null) {
          throw StateError('manifest 响应为空');
        }
        final int code = body['code'] as int? ?? -1;
        if (code != 0) {
          throw StateError('manifest 业务错误: ${body['message']}');
        }
        final Map<String, dynamic>? data = body['data'] as Map<String, dynamic>?;
        if (data == null) {
          throw StateError('manifest data 为空');
        }
        return ManifestModel.fromJson(data);
      },
    );
  }
}
