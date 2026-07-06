import 'package:meme_game/core/network/api_client.dart';
import 'package:meme_game/core/observability/app_logger.dart';
import 'package:meme_game/core/observability/trace_context.dart';
import 'package:meme_game/data/models/auth_model.dart';
import 'package:meme_game/data/services/auth_token_storage.dart';

/// 认证仓库：注册、登录、恢复会话。
class AuthRepository {
  AuthRepository({
    required ApiClient apiClient,
    required AuthTokenStorage tokenStorage,
    required AppLogger logger,
  })  : _apiClient = apiClient,
        _tokenStorage = tokenStorage,
        _logger = logger;

  final ApiClient _apiClient;
  final AuthTokenStorage _tokenStorage;
  final AppLogger _logger;

  Future<AuthTokenModel> register({
    required String username,
    required String password,
    required String displayName,
    required TraceContext traceContext,
  }) async {
    return _authenticate(
      path: '/api/v1/auth/register',
      body: <String, Object?>{
        'username': username,
        'password': password,
        'display_name': displayName,
      },
      traceContext: traceContext,
    );
  }

  Future<AuthTokenModel> login({
    required String username,
    required String password,
    required TraceContext traceContext,
  }) async {
    return _authenticate(
      path: '/api/v1/auth/login',
      body: <String, Object?>{
        'username': username,
        'password': password,
      },
      traceContext: traceContext,
    );
  }

  Future<UserProfileModel?> restoreSession({
    required TraceContext traceContext,
  }) async {
    final String? token = await _tokenStorage.readToken();
    if (token == null || token.isEmpty) {
      return null;
    }
    _apiClient.setAccessToken(token);
    try {
      final response = await _apiClient.getJson(
        path: '/api/v1/auth/me',
        traceContext: traceContext,
      );
      final Map<String, dynamic>? body = response.data;
      if (body == null || body['code'] != 0) {
        await logout();
        return null;
      }
      return UserProfileModel.fromJson(
        body['data'] as Map<String, dynamic>? ?? <String, dynamic>{},
      );
    } catch (_) {
      await logout();
      return null;
    }
  }

  Future<void> persistSession(AuthTokenModel authToken) async {
    await _tokenStorage.saveSession(
      accessToken: authToken.accessToken,
      userId: authToken.user.userId,
      username: authToken.user.username,
      displayName: authToken.user.displayName,
    );
    _apiClient.setAccessToken(authToken.accessToken);
    _logger.info(
      module: 'data.auth',
      event: 'auth.session.saved',
      message: '登录态已保存',
      extra: <String, Object?>{'user_id': authToken.user.userId},
    );
  }

  Future<void> logout() async {
    await _tokenStorage.clear();
    _apiClient.setAccessToken(null);
    _logger.info(
      module: 'data.auth',
      event: 'auth.session.cleared',
      message: '登录态已清除',
    );
  }

  Future<AuthTokenModel> _authenticate({
    required String path,
    required Map<String, Object?> body,
    required TraceContext traceContext,
  }) async {
    final response = await _apiClient.postJson(
      path: path,
      traceContext: traceContext,
      body: body,
    );
    final Map<String, dynamic>? responseBody = response.data;
    if (responseBody == null || responseBody['code'] != 0) {
      final int code = responseBody?['code'] as int? ?? -1;
      final String message = responseBody?['message'] as String? ?? '认证失败';
      throw AuthException(code: code, message: message);
    }
    final AuthTokenModel authToken = AuthTokenModel.fromJson(
      responseBody['data'] as Map<String, dynamic>? ?? <String, dynamic>{},
    );
    await persistSession(authToken);
    return authToken;
  }
}

/// 认证业务异常。
class AuthException implements Exception {
  AuthException({required this.code, required this.message});

  final int code;
  final String message;

  @override
  String toString() => message;
}
