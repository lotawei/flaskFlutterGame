import 'package:meme_game/core/level/archetype_registry.dart';
import 'package:meme_game/core/level/level_archetype_id.dart';
import 'package:meme_game/core/level/level_enemy_model.dart';
import 'package:meme_game/core/level/level_model.dart';
import 'package:meme_game/core/level/level_rule_model.dart';

/// 关卡工厂：从玩法原型 + 地图积木快速组装关卡。
class LevelFactory {
  /// 用原型默认值补齐机制/规则，再覆盖关卡自定义字段。
  LevelModel buildFromArchetype({
    required LevelArchetypeId archetypeId,
    required String levelId,
    required String name,
    required int widthTiles,
    required int heightTiles,
    required LevelPointModel playerSpawn,
    required List<LevelRectModel> platforms,
    required LevelPointModel goal,
    List<LevelPointModel> coins = const <LevelPointModel>[],
    List<LevelEnemyModel> enemies = const <LevelEnemyModel>[],
    List<LevelPointModel> fakeGoals = const <LevelPointModel>[],
    List<MechanicConfigModel>? mechanics,
    List<WinRuleModel>? winRules,
    List<StarRuleModel>? starRules,
    List<MonetizationHookModel>? monetizationHooks,
    String memeTheme = 'default',
    String difficulty = 'normal',
    String tipText = '',
    String designerNotes = '',
  }) {
    final ArchetypeDefinition definition =
        ArchetypeRegistry.getDefinition(archetypeId);
    return LevelModel(
      schemaVersion: 2,
      levelId: levelId,
      name: name,
      archetype: archetypeId,
      memeTheme: memeTheme,
      difficulty: difficulty,
      tileSize: 32,
      widthTiles: widthTiles,
      heightTiles: heightTiles,
      playerSpawn: playerSpawn,
      platforms: platforms,
      coins: coins,
      enemies: enemies,
      fakeGoals: fakeGoals,
      goal: goal,
      mechanics: mechanics ?? definition.defaultMechanics,
      winRules: winRules ?? definition.defaultWinRules,
      starRules: starRules ?? definition.defaultStarRules,
      monetizationHooks:
          monetizationHooks ?? definition.defaultMonetizationHooks,
      tipText: tipText,
      designerNotes: designerNotes,
    );
  }
}
