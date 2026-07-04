import 'package:meme_game/core/level/level_enemy_model.dart';

/// 关卡数据模型。
class LevelModel {
  LevelModel({
    required this.levelId,
    required this.name,
    required this.memeArchetype,
    required this.tileSize,
    required this.widthTiles,
    required this.heightTiles,
    required this.playerSpawn,
    required this.platforms,
    required this.coins,
    required this.enemies,
    required this.goal,
    required this.tipText,
  });

  final String levelId;
  final String name;
  final String memeArchetype;
  final int tileSize;
  final int widthTiles;
  final int heightTiles;
  final LevelPointModel playerSpawn;
  final List<LevelRectModel> platforms;
  final List<LevelPointModel> coins;
  final List<LevelEnemyModel> enemies;
  final LevelPointModel goal;
  final String tipText;

  double get worldWidth => widthTiles * tileSize.toDouble();
  double get worldHeight => heightTiles * tileSize.toDouble();

  factory LevelModel.fromJson(Map<String, dynamic> json) {
    return LevelModel(
      levelId: json['level_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      memeArchetype: json['meme_archetype'] as String? ?? 'default',
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
      tipText: json['tip_text'] as String? ?? '',
    );
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
