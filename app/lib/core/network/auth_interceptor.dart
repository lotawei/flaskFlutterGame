import 'package:dio/dio.dart';

/// 自动附加 Bearer Token。
class AuthInterceptor extends Interceptor {
  AuthInterceptor({required this.tokenReader});

  final String? Function() tokenReader;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final String? token = tokenReader();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}
