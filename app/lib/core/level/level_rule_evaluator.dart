import 'package:meme_game/core/level/level_archetype_id.dart';
import 'package:meme_game/core/level/level_rule_model.dart';

/// 胜利条件与三星评定。
class LevelRuleEvaluator {
  bool isWinSatisfied({
    required List<WinRuleModel> winRules,
    required LevelRunContext context,
  }) {
    for (final WinRuleModel rule in winRules) {
      if (!_checkWinRule(rule, context)) {
        return false;
      }
    }
    return true;
  }

  StarRatingResult evaluateStars({
    required List<StarRuleModel> starRules,
    required LevelRunContext context,
  }) {
    int stars = 0;
    final List<String> details = <String>[];
    final List<StarRuleModel> sortedRules = List<StarRuleModel>.from(starRules)
      ..sort(
        (StarRuleModel a, StarRuleModel b) => a.star.compareTo(b.star),
      );
    for (final StarRuleModel rule in sortedRules) {
      final bool passed = _checkStarRule(rule, context);
      if (passed) {
        stars = rule.star;
        details.add('★$stars ${rule.condition.value} 达成');
      }
    }
    return StarRatingResult(stars: stars, details: details);
  }

  bool _checkWinRule(WinRuleModel rule, LevelRunContext context) {
    switch (rule.type) {
      case WinRuleType.reachGoal:
        final bool mustBeReal =
            rule.params['must_be_real_goal'] as bool? ?? false;
        if (mustBeReal) {
          return context.hasReachedGoal && context.isRealGoal;
        }
        return context.hasReachedGoal;
      case WinRuleType.collectCoinsMin:
        final int minCoins = rule.params['min'] as int? ?? 1;
        return context.collectedCoins >= minCoins;
      case WinRuleType.surviveTime:
        final double seconds = (rule.params['seconds'] as num?)?.toDouble() ?? 0;
        return context.elapsedSeconds >= seconds;
    }
  }

  bool _checkStarRule(StarRuleModel rule, LevelRunContext context) {
    switch (rule.condition) {
      case StarConditionType.clear:
        return context.hasReachedGoal;
      case StarConditionType.coinsRatio:
        if (context.totalCoins == 0) {
          return true;
        }
        final double ratio = (rule.params['ratio'] as num?)?.toDouble() ?? 1;
        return context.collectedCoins / context.totalCoins >= ratio;
      case StarConditionType.timeUnder:
        final double limit = (rule.params['seconds'] as num?)?.toDouble() ?? 999;
        return context.hasReachedGoal && context.elapsedSeconds <= limit;
      case StarConditionType.noDamage:
        return context.hasReachedGoal && context.damageTaken == 0;
      case StarConditionType.defeatAllEnemies:
        return context.hasReachedGoal &&
            context.defeatedEnemies >= context.totalEnemies;
    }
  }

  int? readTimeLimitSeconds(List<MechanicConfigModel> mechanics) {
    for (final MechanicConfigModel mechanic in mechanics) {
      if (mechanic.type == MechanicType.timeLimit) {
        return mechanic.params['seconds'] as int?;
      }
    }
    return null;
  }
}
