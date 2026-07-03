import 'package:dio/dio.dart';
import 'package:meme_game/core/config/app_config.dart';
import 'package:meme_game/core/network/logging_interceptor.dart';
import 'package:meme_game/core/observability/app_logger.dart';
import 'package:meme_game/core/observability/trace_context.dart';

/// 统一 HTTP 客户端。
class ApiClient {
  ApiClient({
    required AppConfig config,
    required AppLogger logger,
  }) : _dio = Dio(
          BaseOptions(
            baseUrl: config.apiBaseUrl,
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 15),
            headers: const <String, String>{
              'Accept': 'application/json',
            },
          ),
        ) {
    _dio.interceptors.add(LoggingInterceptor(logger: logger, config: config));
  }

  final Dio _dio;

  Future<Response<Map<String, dynamic>>> getJson({
    required String path,
    required TraceContext traceContext,
    Map<String, dynamic>? queryParameters,
  }) async {
    return _dio.get<Map<String, dynamic>>(
      path,
      queryParameters: queryParameters,
      options: Options(
        headers: traceContext.toHeaders(),
        extra: <String, Object?>{'trace_context': traceContext},
      ),
    );
  }
}
