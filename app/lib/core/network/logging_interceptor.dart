import 'package:dio/dio.dart';
import 'package:meme_game/core/config/app_config.dart';
import 'package:meme_game/core/observability/app_logger.dart';
import 'package:meme_game/core/observability/trace_context.dart';

/// HTTP 请求/响应日志拦截器。
class LoggingInterceptor extends Interceptor {
  LoggingInterceptor({
    required this.logger,
    required this.config,
  });

  final AppLogger logger;
  final AppConfig config;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (config.enableNetworkLog) {
      final TraceContext? traceContext = _readTraceContext(options);
      logger.info(
        module: 'network',
        event: 'http.request.sent',
        message: '${options.method} ${options.uri}',
        traceContext: traceContext,
        extra: <String, Object?>{
          'path': options.path,
          'query': options.queryParameters,
        },
      );
    }
    handler.next(options);
  }

  @override
  void onResponse(Response<dynamic> response, ResponseInterceptorHandler handler) {
    if (config.enableNetworkLog) {
      final TraceContext? traceContext = _readTraceContext(response.requestOptions);
      logger.info(
        module: 'network',
        event: 'http.response.received',
        message: '${response.requestOptions.method} ${response.requestOptions.path} -> ${response.statusCode}',
        traceContext: traceContext,
        extra: <String, Object?>{
          'status_code': response.statusCode,
          'request_id': response.headers.value('x-request-id'),
        },
      );
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final TraceContext? traceContext = _readTraceContext(err.requestOptions);
    logger.error(
      module: 'network',
      event: 'http.request.failed',
      message: '${err.requestOptions.method} ${err.requestOptions.path} 失败',
      traceContext: traceContext,
      extra: <String, Object?>{
        'error_type': err.type.toString(),
        'status_code': err.response?.statusCode,
        'error_message': err.message,
      },
    );
    handler.next(err);
  }

  TraceContext? _readTraceContext(RequestOptions options) {
    final Object? extraContext = options.extra['trace_context'];
    if (extraContext is TraceContext) {
      return extraContext;
    }
    return null;
  }
}
