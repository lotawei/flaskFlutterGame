import 'package:meme_game/core/level/level_archetype_id.dart';
import 'package:meme_game/core/level/level_enemy_model.dart';
import 'package:meme_game/core/level/level_rule_model.dart';

/// 关卡数据模型（v1/v2 兼容）。
class LevelModel {
  LevelModel({
    this.schemaVersion = 1,
    required this.levelId,
    required this.name,
    required this.archetype,
    required this.memeTheme,
    this.difficulty = 'normal',
    required this.tileSize,
    required this.widthTiles,
    required this.heightTiles,
    required this.playerSpawn,
    required this.platforms,
    required this.coins,
    required this.enemies,
    required this.goal,
    this.fakeGoals = const <LevelPointModel>[],
    this.mechanics = const <MechanicConfigModel>[],
    this.winRules = const <WinRuleModel>[],
    this.starRules = const <StarRuleModel>[],
    this.monetizationHooks = const <MonetizationHookModel>[],
    required this.tipText,
    this.designerNotes = '',
  });

  final int schemaVersion;
  final String levelId;
  final String name;
  final LevelArchetypeId archetype;
  final String memeTheme;
  final String difficulty;
  final int tileSize;
  final int widthTiles;
  final int heightTiles;
  final LevelPointModel playerSpawn;
  final List<LevelRectModel> platforms;
  final List<LevelPointModel> coins;
  final List<LevelEnemyModel> enemies;
  final LevelPointModel goal;
  final List<LevelPointModel> fakeGoals;
  final List<MechanicConfigModel> mechanics;
  final List<WinRuleModel> winRules;
  final List<StarRuleModel> starRules;
  final List<MonetizationHookModel> monetizationHooks;
  final String tipText;
  final String designerNotes;

  /// v1 字段别名，保持旧代码可读。
  String get memeArchetype => memeTheme;

  double get worldWidth => widthTiles * tileSize.toDouble();
  double get worldHeight => heightTiles * tileSize.toDouble();

  factory LevelModel.fromJson(Map<String, dynamic> json) {
    final int schemaVersion = json['schema_version'] as int? ?? 1;
    final LevelArchetypeId archetype = LevelArchetypeId.fromValue(
      json['archetype'] as String? ?? 'rush_standard',
    );
    final String memeTheme = json['meme_theme'] as String? ??
        json['meme_archetype'] as String? ??
        'default';
    return LevelModel(
      schemaVersion: schemaVersion,
      levelId: json['level_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      archetype: archetype,
      memeTheme: memeTheme,
      difficulty: json['difficulty'] as String? ?? 'normal',
      tileSize: json['tile_size'] as int? ?? 32,
      widthTiles: json['width_tiles'] as int? ?? 40,
      heightTiles: json['height_tiles'] as int? ?? 15,
      playerSpawn: LevelPointModel.fromJson(
        json['player_spawn'] as Map<String, dynamic>? ?? <String, dynamic>{},
      ),
      platforms: _parseRects(json['platforms']),
      coins: _parsePoints(json['coins']),
      enemies: _parseEnemies(json['enemies']),
      goal: LevelPointModel.fromJson(
        json['goal'] as Map<String, dynamic>? ?? <String, dynamic>{},
      ),
      fakeGoals: _parsePoints(json['fake_goals']),
      mechanics: _parseMechanics(json['mechanics']),
      winRules: _parseWinRules(json['win_rules']),
      starRules: _parseStarRules(json['star_rules']),
      monetizationHooks: _parseMonetizationHooks(json['monetization_hooks']),
      tipText: json['tip_text'] as String? ?? '',
      designerNotes: json['designer_notes'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'schema_version': schemaVersion,
      'level_id': levelId,
      'name': name,
      'archetype': archetype.value,
      'meme_theme': memeTheme,
      'difficulty': difficulty,
      'tile_size': tileSize,
      'width_tiles': widthTiles,
      'height_tiles': heightTiles,
      'player_spawn': <String, int>{'x': playerSpawn.x, 'y': playerSpawn.y},
      'platforms': platforms
          .map(
            (LevelRectModel rect) => <String, int>{
              'x': rect.x,
              'y': rect.y,
              'w': rect.w,
              'h': rect.h,
            },
          )
          .toList(),
      'coins': coins
          .map(
            (LevelPointModel point) => <String, int>{
              'x': point.x,
              'y': point.y,
            },
          )
          .toList(),
      'enemies': enemies
          .map(
            (LevelEnemyModel enemy) => <String, int>{
              'x': enemy.x,
              'y': enemy.y,
              'patrol_left': enemy.patrolLeft,
              'patrol_right': enemy.patrolRight,
            },
          )
          .toList(),
      'goal': <String, int>{'x': goal.x, 'y': goal.y},
      if (fakeGoals.isNotEmpty)
        'fake_goals': fakeGoals
            .map(
              (LevelPointModel point) => <String, int>{
                'x': point.x,
                'y': point.y,
              },
            )
            .toList(),
      if (mechanics.isNotEmpty)
        'mechanics': mechanics
            .map(
              (MechanicConfigModel item) => <String, Object?>{
                'type': item.type.value,
                'params': item.params,
              },
            )
            .toList(),
      'win_rules': winRules
          .map(
            (WinRuleModel rule) => <String, Object?>{
              'type': rule.type.value,
              'params': rule.params,
            },
          )
          .toList(),
      if (starRules.isNotEmpty)
        'star_rules': starRules
            .map(
              (StarRuleModel rule) => <String, Object?>{
                'star': rule.star,
                'condition': rule.condition.value,
                'params': rule.params,
              },
            )
            .toList(),
      if (monetizationHooks.isNotEmpty)
        'monetization_hooks': monetizationHooks
            .map(
              (MonetizationHookModel hook) => <String, Object?>{
                'slot': hook.slot.value,
                'enabled': hook.isEnabled,
              },
            )
            .toList(),
      'tip_text': tipText,
      if (designerNotes.isNotEmpty) 'designer_notes': designerNotes,
    };
  }

  static List<LevelRectModel> _parseRects(Object? raw) {
    if (raw is! List<dynamic>) {
      return <LevelRectModel>[];
    }
    return raw
        .whereType<Map<String, dynamic>>()
        .map(LevelRectModel.fromJson)
        .toList();
  }

  static List<LevelPointModel> _parsePoints(Object? raw) {
    if (raw is! List<dynamic>) {
      return <LevelPointModel>[];
    }
    return raw
        .whereType<Map<String, dynamic>>()
        .map(LevelPointModel.fromJson)
        .toList();
  }

  static List<LevelEnemyModel> _parseEnemies(Object? raw) {
    if (raw is! List<dynamic>) {
      return <LevelEnemyModel>[];
    }
    return raw
        .whereType<Map<String, dynamic>>()
        .map(LevelEnemyModel.fromJson)
        .toList();
  }

  static List<MechanicConfigModel> _parseMechanics(Object? raw) {
    if (raw is! List<dynamic>) {
      return <MechanicConfigModel>[];
    }
    return raw
        .whereType<Map<String, dynamic>>()
        .map(MechanicConfigModel.fromJson)
        .toList();
  }

  static List<WinRuleModel> _parseWinRules(Object? raw) {
    if (raw is! List<dynamic> || raw.isEmpty) {
      return <WinRuleModel>[
        WinRuleModel(type: WinRuleType.reachGoal, params: <String, Object?>{}),
      ];
    }
    return raw
        .whereType<Map<String, dynamic>>()
        .map(WinRuleModel.fromJson)
        .toList();
  }

  static List<StarRuleModel> _parseStarRules(Object? raw) {
    if (raw is! List<dynamic>) {
      return <StarRuleModel>[];
    }
    return raw
        .whereType<Map<String, dynamic>>()
        .map(StarRuleModel.fromJson)
        .toList();
  }

  static List<MonetizationHookModel> _parseMonetizationHooks(Object? raw) {
    if (raw is! List<dynamic>) {
      return <MonetizationHookModel>[];
    }
    return raw
        .whereType<Map<String, dynamic>>()
        .map(MonetizationHookModel.fromJson)
        .toList();
  }
}

/// 关卡点坐标（tile 单位）。
class LevelPointModel {
  LevelPointModel({required this.x, required this.y});

  final int x;
  final int y;

  factory LevelPointModel.fromJson(Map<String, dynamic> json) {
    return LevelPointModel(
      x: json['x'] as int? ?? 0,
      y: json['y'] as int? ?? 0,
    );
  }
}

/// 关卡矩形（tile 单位）。
class LevelRectModel {
  LevelRectModel({
    required this.x,
    required this.y,
    required this.w,
    required this.h,
  });

  final int x;
  final int y;
  final int w;
  final int h;

  factory LevelRectModel.fromJson(Map<String, dynamic> json) {
    return LevelRectModel(
      x: json['x'] as int? ?? 0,
      y: json['y'] as int? ?? 0,
      w: json['w'] as int? ?? 1,
      h: json['h'] as int? ?? 1,
    );
  }
}
