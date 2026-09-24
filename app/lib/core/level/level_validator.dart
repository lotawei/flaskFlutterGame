import 'package:meme_game/core/level/level_archetype_id.dart';
import 'package:meme_game/core/level/level_model.dart';
import 'package:meme_game/core/level/level_rule_model.dart';

/// 关卡校验结果。
class LevelValidationIssue {
  LevelValidationIssue({required this.code, required this.message});

  final String code;
  final String message;
}

/// 关卡数据校验器（策划提交前 / CI 批量检查）。
class LevelValidator {
  List<LevelValidationIssue> validate(LevelModel level) {
    final List<LevelValidationIssue> issues = <LevelValidationIssue>[];
    if (level.levelId.isEmpty) {
      issues.add(
        LevelValidationIssue(code: 'LEVEL_ID_EMPTY', message: 'level_id 不能为空'),
      );
    }
    if (level.platforms.isEmpty) {
      issues.add(
        LevelValidationIssue(code: 'NO_PLATFORMS', message: '至少需要一个平台'),
      );
    }
    if (level.goal.x < 0 || level.goal.y < 0) {
      issues.add(
        LevelValidationIssue(code: 'GOAL_INVALID', message: 'goal 坐标无效'),
      );
    }
    if (level.playerSpawn.x >= level.widthTiles ||
        level.playerSpawn.y >= level.heightTiles) {
      issues.add(
        LevelValidationIssue(
          code: 'SPAWN_OUT_OF_BOUNDS',
          message: 'player_spawn 超出地图范围',
        ),
      );
    }
    if (level.winRules.isEmpty) {
      issues.add(
        LevelValidationIssue(
          code: 'NO_WIN_RULE',
          message: '至少一条 win_rules',
        ),
      );
    }
    for (final LevelPointModel coin in level.coins) {
      if (coin.x >= level.widthTiles || coin.y >= level.heightTiles) {
        issues.add(
          LevelValidationIssue(
            code: 'COIN_OUT_OF_BOUNDS',
            message: '金币 ($coin.x,$coin.y) 超出地图',
          ),
        );
      }
    }
    if (level.archetype == LevelArchetypeId.reversalTrap &&
        level.fakeGoals.isEmpty) {
      issues.add(
        LevelValidationIssue(
          code: 'REVERSAL_NO_FAKE_GOAL',
          message: '反转陷阱关至少需要一个 fake_goals',
        ),
      );
    }
    if (level.archetype == LevelArchetypeId.timedRush) {
      final bool hasTimer = level.mechanics.any(
        (MechanicConfigModel item) => item.type == MechanicType.timeLimit,
      );
      if (!hasTimer) {
        issues.add(
          LevelValidationIssue(
            code: 'TIMED_NO_LIMIT',
            message: '限时关需配置 time_limit 机制',
          ),
        );
      }
    }
    return issues;
  }

  bool isValid(LevelModel level) => validate(level).isEmpty;
}
