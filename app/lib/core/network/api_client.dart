import 'package:dio/dio.dart';
import 'package:meme_game/core/config/app_config.dart';
import 'package:meme_game/core/network/auth_interceptor.dart';
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
    _dio.interceptors.add(AuthInterceptor(tokenReader: () => _accessToken));
  }

  final Dio _dio;
  String? _accessToken;

  void setAccessToken(String? token) {
    _accessToken = token;
  }

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

  Future<Response<Map<String, dynamic>>> postJson({
    required String path,
    required TraceContext traceContext,
    Map<String, dynamic>? body,
  }) async {
    return _dio.post<Map<String, dynamic>>(
      path,
      data: body,
      options: Options(
        headers: <String, String>{
          ...traceContext.toHeaders(),
          'Content-Type': 'application/json',
        },
        extra: <String, Object?>{'trace_context': traceContext},
      ),
    );
  }
}
