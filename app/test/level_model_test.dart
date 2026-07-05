import 'package:flutter_test/flutter_test.dart';
import 'package:meme_game/core/level/archetype_registry.dart';
import 'package:meme_game/core/level/level_archetype_id.dart';
import 'package:meme_game/core/level/level_factory.dart';
import 'package:meme_game/core/level/level_enemy_model.dart';
import 'package:meme_game/core/level/level_loader.dart';
import 'package:meme_game/core/level/level_model.dart';
import 'package:meme_game/core/level/level_rule_evaluator.dart';
import 'package:meme_game/core/level/level_rule_model.dart';
import 'package:meme_game/core/level/level_validator.dart';

void main() {
  group('LevelModel', () {
    test('v1 JSON 可解析并默认 win_rules', () {
      const String rawJson = '''
      {
        "level_id": "test",
        "name": "test",
        "tile_size": 32,
        "width_tiles": 10,
        "height_tiles": 10,
        "player_spawn": {"x": 1, "y": 1},
        "platforms": [{"x": 0, "y": 9, "w": 10, "h": 1}],
        "coins": [],
        "enemies": [{"x": 5, "y": 3, "patrol_left": 1, "patrol_right": 2}],
        "goal": {"x": 8, "y": 1},
        "tip_text": "tip"
      }
      ''';
      final LevelModel level = LevelLoader().loadFromJsonString(rawJson);
      expect(level.enemies.length, 1);
      expect(level.archetype, LevelArchetypeId.rushStandard);
      expect(level.winRules.length, 1);
      expect(level.winRules.first.type, WinRuleType.reachGoal);
    });

    test('v2 JSON 可解析 archetype 与 mechanics', () {
      const String rawJson = '''
      {
        "schema_version": 2,
        "level_id": "timed_test",
        "name": "限时",
        "archetype": "timed_rush",
        "meme_theme": "panic",
        "tile_size": 32,
        "width_tiles": 20,
        "height_tiles": 15,
        "player_spawn": {"x": 1, "y": 11},
        "platforms": [{"x": 0, "y": 13, "w": 20, "h": 2}],
        "coins": [],
        "enemies": [],
        "goal": {"x": 18, "y": 11},
        "mechanics": [
          {"type": "time_limit", "params": {"seconds": 60, "warn_at": 10}}
        ],
        "win_rules": [{"type": "reach_goal", "params": {}}],
        "tip_text": "快"
      }
      ''';
      final LevelModel level = LevelLoader().loadFromJsonString(rawJson);
      expect(level.schemaVersion, 2);
      expect(level.archetype, LevelArchetypeId.timedRush);
      expect(level.mechanics.first.type, MechanicType.timeLimit);
    });

    test('v2 JSON 可解析 gravity_zones 与 gravity_flip 原型', () {
      const String rawJson = '''
      {
        "schema_version": 2,
        "level_id": "gravity_test",
        "name": "重力",
        "archetype": "gravity_flip",
        "meme_theme": "ibb",
        "tile_size": 32,
        "width_tiles": 40,
        "height_tiles": 15,
        "player_spawn": {"x": 1, "y": 11},
        "gravity_zones": [
          {"x": 0, "y": 0, "w": 40, "h": 7, "gravity": "up"},
          {"x": 0, "y": 7, "w": 40, "h": 8, "gravity": "down"}
        ],
        "platforms": [{"x": 0, "y": 13, "w": 40, "h": 2}],
        "coins": [],
        "enemies": [],
        "goal": {"x": 38, "y": 1},
        "mechanics": [
          {"type": "gravity_flip", "params": {"default_gravity": "down"}}
        ],
        "win_rules": [{"type": "reach_goal", "params": {}}],
        "tip_text": "倒挂"
      }
      ''';
      final LevelModel level = LevelLoader().loadFromJsonString(rawJson);
      expect(level.archetype, LevelArchetypeId.gravityFlip);
      expect(level.gravityZones.length, 2);
      expect(level.gravityZones.first.gravityDirection, -1);
      expect(level.mechanics.first.type, MechanicType.gravityFlip);
    });
  });

  group('LevelFactory', () {
    test('从原型组装关卡并继承默认规则', () {
      final LevelFactory factory = LevelFactory();
      final LevelModel level = factory.buildFromArchetype(
        archetypeId: LevelArchetypeId.reversalTrap,
        levelId: 'factory_test',
        name: '工厂测试',
        widthTiles: 30,
        heightTiles: 15,
        playerSpawn: LevelPointModel(x: 2, y: 11),
        platforms: <LevelRectModel>[
          LevelRectModel(x: 0, y: 13, w: 30, h: 2),
        ],
        goal: LevelPointModel(x: 28, y: 11),
        fakeGoals: <LevelPointModel>[LevelPointModel(x: 10, y: 11)],
        tipText: '找真旗',
      );
      expect(level.archetype, LevelArchetypeId.reversalTrap);
      expect(level.fakeGoals.length, 1);
      expect(level.winRules.first.params['must_be_real_goal'], true);
      expect(
        level.monetizationHooks.any(
          (MonetizationHookModel hook) =>
              hook.slot == MonetizationSlot.hintReveal,
        ),
        isTrue,
      );
    });
  });

  group('LevelValidator', () {
    test('反转关缺 fake_goals 时报错', () {
      final LevelValidator validator = LevelValidator();
      final LevelModel level = LevelModel(
        levelId: 'bad_reversal',
        name: '坏关',
        archetype: LevelArchetypeId.reversalTrap,
        memeTheme: 'test',
        tileSize: 32,
        widthTiles: 20,
        heightTiles: 15,
        playerSpawn: LevelPointModel(x: 1, y: 11),
        platforms: <LevelRectModel>[
          LevelRectModel(x: 0, y: 13, w: 20, h: 2),
        ],
        coins: <LevelPointModel>[],
        enemies: <LevelEnemyModel>[],
        goal: LevelPointModel(x: 18, y: 11),
        tipText: '',
      );
      final List<LevelValidationIssue> issues = validator.validate(level);
      expect(
        issues.any((LevelValidationIssue item) => item.code == 'REVERSAL_NO_FAKE_GOAL'),
        isTrue,
      );
    });

    test('重力反转关缺 gravity_zones 时报错', () {
      final LevelValidator validator = LevelValidator();
      final LevelModel level = LevelModel(
        levelId: 'bad_gravity',
        name: '坏关',
        archetype: LevelArchetypeId.gravityFlip,
        memeTheme: 'test',
        tileSize: 32,
        widthTiles: 20,
        heightTiles: 15,
        playerSpawn: LevelPointModel(x: 1, y: 11),
        platforms: <LevelRectModel>[
          LevelRectModel(x: 0, y: 13, w: 20, h: 2),
        ],
        coins: <LevelPointModel>[],
        enemies: <LevelEnemyModel>[],
        goal: LevelPointModel(x: 18, y: 11),
        tipText: '',
      );
      final List<LevelValidationIssue> issues = validator.validate(level);
      expect(
        issues.any((LevelValidationIssue item) => item.code == 'GRAVITY_NO_ZONES'),
        isTrue,
      );
    });
  });

  group('LevelRuleEvaluator', () {
    test('限时三星按用时评定', () {
      final LevelRuleEvaluator evaluator = LevelRuleEvaluator();
      final ArchetypeDefinition definition =
          ArchetypeRegistry.getDefinition(LevelArchetypeId.timedRush);
      final StarRatingResult result = evaluator.evaluateStars(
        starRules: definition.defaultStarRules,
        context: LevelRunContext(
          elapsedSeconds: 40,
          collectedCoins: 0,
          totalCoins: 0,
          defeatedEnemies: 0,
          totalEnemies: 0,
          damageTaken: 0,
          hasReachedGoal: true,
          isRealGoal: true,
        ),
      );
      expect(result.stars, 3);
    });

    test('读取 time_limit 秒数', () {
      final LevelRuleEvaluator evaluator = LevelRuleEvaluator();
      final int? seconds = evaluator.readTimeLimitSeconds(
        <MechanicConfigModel>[
          MechanicConfigModel(
            type: MechanicType.timeLimit,
            params: <String, Object?>{'seconds': 90},
          ),
        ],
      );
      expect(seconds, 90);
    });
  });
}
