/// 用户资料模型。
class UserProfileModel {
  UserProfileModel({
    required this.userId,
    required this.username,
    required this.displayName,
    required this.createdAt,
  });

  final String userId;
  final String username;
  final String displayName;
  final String createdAt;

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      userId: json['user_id'] as String? ?? '',
      username: json['username'] as String? ?? '',
      displayName: json['display_name'] as String? ?? '',
      createdAt: json['created_at'] as String? ?? '',
    );
  }
}

/// 登录响应模型。
class AuthTokenModel {
  AuthTokenModel({
    required this.accessToken,
    required this.tokenType,
    required this.expiresIn,
    required this.user,
  });

  final String accessToken;
  final String tokenType;
  final int expiresIn;
  final UserProfileModel user;

  factory AuthTokenModel.fromJson(Map<String, dynamic> json) {
    return AuthTokenModel(
      accessToken: json['access_token'] as String? ?? '',
      tokenType: json['token_type'] as String? ?? 'Bearer',
      expiresIn: json['expires_in'] as int? ?? 0,
      user: UserProfileModel.fromJson(
        json['user'] as Map<String, dynamic>? ?? <String, dynamic>{},
      ),
    );
  }
}

/// Manifest 内嵌用户摘要。
class UserSummaryModel {
  UserSummaryModel({
    required this.userId,
    required this.username,
    required this.displayName,
    required this.totalStars,
    required this.clearedLevels,
    required this.playedLevels,
  });

  final String userId;
  final String username;
  final String displayName;
  final int totalStars;
  final int clearedLevels;
  final int playedLevels;

  factory UserSummaryModel.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> summary =
        json['summary'] as Map<String, dynamic>? ?? <String, dynamic>{};
    return UserSummaryModel(
      userId: json['user_id'] as String? ?? '',
      username: json['username'] as String? ?? '',
      displayName: json['display_name'] as String? ?? '',
      totalStars: summary['total_stars'] as int? ?? 0,
      clearedLevels: summary['cleared_levels'] as int? ?? 0,
      playedLevels: summary['played_levels'] as int? ?? 0,
    );
  }
}

/// 单关进度。
class LevelProgressModel {
  LevelProgressModel({
    required this.levelId,
    required this.bestStars,
    required this.bestTimeSeconds,
    required this.bestCoins,
    required this.clearCount,
    required this.failCount,
  });

  final String levelId;
  final int bestStars;
  final double? bestTimeSeconds;
  final int bestCoins;
  final int clearCount;
  final int failCount;

  factory LevelProgressModel.fromJson(Map<String, dynamic> json) {
    return LevelProgressModel(
      levelId: json['level_id'] as String? ?? '',
      bestStars: json['best_stars'] as int? ?? 0,
      bestTimeSeconds: (json['best_time_seconds'] as num?)?.toDouble(),
      bestCoins: json['best_coins'] as int? ?? 0,
      clearCount: json['clear_count'] as int? ?? 0,
      failCount: json['fail_count'] as int? ?? 0,
    );
  }
}

/// 用户进度汇总。
class UserProgressModel {
  UserProgressModel({
    required this.userId,
    required this.levels,
    required this.totalStars,
    required this.clearedLevels,
    required this.playedLevels,
  });

  final String userId;
  final Map<String, LevelProgressModel> levels;
  final int totalStars;
  final int clearedLevels;
  final int playedLevels;

  factory UserProgressModel.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> rawLevels =
        json['levels'] as Map<String, dynamic>? ?? <String, dynamic>{};
    final Map<String, LevelProgressModel> levels = <String, LevelProgressModel>{};
    rawLevels.forEach((String key, dynamic value) {
      if (value is Map<String, dynamic>) {
        levels[key] = LevelProgressModel.fromJson(value);
      }
    });
    final Map<String, dynamic> summary =
        json['summary'] as Map<String, dynamic>? ?? <String, dynamic>{};
    return UserProgressModel(
      userId: json['user_id'] as String? ?? '',
      levels: levels,
      totalStars: summary['total_stars'] as int? ?? 0,
      clearedLevels: summary['cleared_levels'] as int? ?? 0,
      playedLevels: summary['played_levels'] as int? ?? 0,
    );
  }
}

/// 对局上报结果。
class SessionSubmitResultModel {
  SessionSubmitResultModel({
    required this.levelProgress,
    required this.totalStars,
    required this.clearedLevels,
  });

  final LevelProgressModel levelProgress;
  final int totalStars;
  final int clearedLevels;

  factory SessionSubmitResultModel.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> summary =
        json['summary'] as Map<String, dynamic>? ?? <String, dynamic>{};
    return SessionSubmitResultModel(
      levelProgress: LevelProgressModel.fromJson(
        json['level_progress'] as Map<String, dynamic>? ?? <String, dynamic>{},
      ),
      totalStars: summary['total_stars'] as int? ?? 0,
      clearedLevels: summary['cleared_levels'] as int? ?? 0,
    );
  }
}
