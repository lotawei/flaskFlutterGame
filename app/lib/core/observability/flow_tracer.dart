import 'package:meme_game/core/observability/app_logger.dart';
import 'package:meme_game/core/observability/trace_context.dart';

/// 客户端业务流程追踪。
class FlowTracer {
  FlowTracer({
    required this.logger,
    required this.module,
    required this.flowName,
    required this.traceContext,
  });

  final AppLogger logger;
  final String module;
  final String flowName;
  final TraceContext traceContext;

  Future<T> runStep<T>({
    required String stepName,
    required Future<T> Function(TraceContext spanContext) action,
    Map<String, Object?> extra = const <String, Object?>{},
  }) async {
    final TraceContext spanContext = traceContext.createChildSpan();
    final String eventPrefix = '$flowName.$stepName';
    final DateTime startedAt = DateTime.now();
    logger.info(
      module: module,
      event: '$eventPrefix.started',
      message: '[$flowName] 步骤开始: $stepName',
      traceContext: spanContext,
      extra: extra,
    );
    try {
      final T result = await action(spanContext);
      final int durationMs = DateTime.now().difference(startedAt).inMilliseconds;
      logger.info(
        module: module,
        event: '$eventPrefix.completed',
        message: '[$flowName] 步骤完成: $stepName',
        traceContext: spanContext,
        extra: <String, Object?>{
          ...extra,
          'duration_ms': durationMs,
        },
      );
      return result;
    } catch (err) {
      final int durationMs = DateTime.now().difference(startedAt).inMilliseconds;
      logger.error(
        module: module,
        event: '$eventPrefix.failed',
        message: '[$flowName] 步骤失败: $stepName - $err',
        traceContext: spanContext,
        extra: <String, Object?>{
          ...extra,
          'duration_ms': durationMs,
          'error_type': err.runtimeType.toString(),
          'error_message': err.toString(),
        },
      );
      rethrow;
    }
  }
}
