import 'package:meme_game/core/level/level_archetype_id.dart';

/// 机制积木配置。
class MechanicConfigModel {
  MechanicConfigModel({required this.type, required this.params});

  final MechanicType type;
  final Map<String, Object?> params;

  factory MechanicConfigModel.fromJson(Map<String, dynamic> json) {
    final String rawType = json['type'] as String? ?? '';
    final MechanicType? type = MechanicType.fromValue(rawType);
    if (type == null) {
      throw FormatException('未知机制类型: $rawType');
    }
    return MechanicConfigModel(
      type: type,
      params: Map<String, Object?>.from(
        json['params'] as Map<String, dynamic>? ?? <String, dynamic>{},
      ),
    );
  }
}

/// 胜利规则。
class WinRuleModel {
  WinRuleModel({required this.type, required this.params});

  final WinRuleType type;
  final Map<String, Object?> params;

  factory WinRuleModel.fromJson(Map<String, dynamic> json) {
    final String rawType = json['type'] as String? ?? '';
    final WinRuleType? type = WinRuleType.fromValue(rawType);
    if (type == null) {
      throw FormatException('未知胜利规则: $rawType');
    }
    return WinRuleModel(
      type: type,
      params: Map<String, Object?>.from(
        json['params'] as Map<String, dynamic>? ?? <String, dynamic>{},
      ),
    );
  }
}

/// 三星评价规则。
class StarRuleModel {
  StarRuleModel({
    required this.star,
    required this.condition,
    required this.params,
  });

  final int star;
  final StarConditionType condition;
  final Map<String, Object?> params;

  factory StarRuleModel.fromJson(Map<String, dynamic> json) {
    final String rawCondition = json['condition'] as String? ?? '';
    final StarConditionType? condition = StarConditionType.fromValue(rawCondition);
    if (condition == null) {
      throw FormatException('未知三星条件: $rawCondition');
    }
    return StarRuleModel(
      star: json['star'] as int? ?? 1,
      condition: condition,
      params: Map<String, Object?>.from(
        json['params'] as Map<String, dynamic>? ?? <String, dynamic>{},
      ),
    );
  }
}

/// 变现钩子配置（供策划填表，引擎读取后决定 UI 展示）。
class MonetizationHookModel {
  MonetizationHookModel({required this.slot, required this.isEnabled});

  final MonetizationSlot slot;
  final bool isEnabled;

  factory MonetizationHookModel.fromJson(Map<String, dynamic> json) {
    final String rawSlot = json['slot'] as String? ?? '';
    final MonetizationSlot? slot = MonetizationSlot.fromValue(rawSlot);
    if (slot == null) {
      throw FormatException('未知变现槽位: $rawSlot');
    }
    return MonetizationHookModel(
      slot: slot,
      isEnabled: json['enabled'] as bool? ?? true,
    );
  }
}

/// 单局结算上下文（用于胜利/三星/变现判定）。
class LevelRunContext {
  LevelRunContext({
    required this.elapsedSeconds,
    required this.collectedCoins,
    required this.totalCoins,
    required this.defeatedEnemies,
    required this.totalEnemies,
    required this.damageTaken,
    required this.hasReachedGoal,
    required this.isRealGoal,
  });

  final double elapsedSeconds;
  final int collectedCoins;
  final int totalCoins;
  final int defeatedEnemies;
  final int totalEnemies;
  final int damageTaken;
  final bool hasReachedGoal;
  final bool isRealGoal;
}

/// 三星评定结果。
class StarRatingResult {
  StarRatingResult({required this.stars, required this.details});

  final int stars;
  final List<String> details;
}
