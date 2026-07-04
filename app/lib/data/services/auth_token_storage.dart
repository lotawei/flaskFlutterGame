import 'package:shared_preferences/shared_preferences.dart';

/// 本地 Token 存储。
class AuthTokenStorage {
  AuthTokenStorage({SharedPreferences? preferences})
      : _preferencesFuture = preferences != null
            ? Future<SharedPreferences>.value(preferences)
            : SharedPreferences.getInstance();

  static const String _tokenKey = 'auth_access_token';
  static const String _userIdKey = 'auth_user_id';
  static const String _usernameKey = 'auth_username';
  static const String _displayNameKey = 'auth_display_name';

  final Future<SharedPreferences> _preferencesFuture;

  Future<String?> readToken() async {
    final SharedPreferences preferences = await _preferencesFuture;
    return preferences.getString(_tokenKey);
  }

  Future<void> saveSession({
    required String accessToken,
    required String userId,
    required String username,
    required String displayName,
  }) async {
    final SharedPreferences preferences = await _preferencesFuture;
    await preferences.setString(_tokenKey, accessToken);
    await preferences.setString(_userIdKey, userId);
    await preferences.setString(_usernameKey, username);
    await preferences.setString(_displayNameKey, displayName);
  }

  Future<Map<String, String>?> readProfile() async {
    final SharedPreferences preferences = await _preferencesFuture;
    final String? userId = preferences.getString(_userIdKey);
    final String? username = preferences.getString(_usernameKey);
    if (userId == null || username == null) {
      return null;
    }
    return <String, String>{
      'user_id': userId,
      'username': username,
      'display_name': preferences.getString(_displayNameKey) ?? username,
    };
  }

  Future<void> clear() async {
    final SharedPreferences preferences = await _preferencesFuture;
    await preferences.remove(_tokenKey);
    await preferences.remove(_userIdKey);
    await preferences.remove(_usernameKey);
    await preferences.remove(_displayNameKey);
  }
}
