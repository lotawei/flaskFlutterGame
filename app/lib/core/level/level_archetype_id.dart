/// 关卡玩法原型 ID。
enum LevelArchetypeId {
  rushStandard('rush_standard'),
  timedRush('timed_rush'),
  reversalTrap('reversal_trap'),
  greedTax('greed_tax'),
  lieFlat('lie_flat'),
  gravityFlip('gravity_flip');

  const LevelArchetypeId(this.value);

  final String value;

  static LevelArchetypeId fromValue(String raw) {
    return LevelArchetypeId.values.firstWhere(
      (LevelArchetypeId item) => item.value == raw,
      orElse: () => LevelArchetypeId.rushStandard,
    );
  }
}

/// 机制积木类型。
enum MechanicType {
  timeLimit('time_limit'),
  coinGreedScale('coin_greed_scale'),
  lieFlatMeter('lie_flat_meter'),
  reversalFakeGoal('reversal_fake_goal'),
  rhythmStep('rhythm_step'),
  gravityFlip('gravity_flip');

  const MechanicType(this.value);

  final String value;

  static MechanicType? fromValue(String raw) {
    for (final MechanicType type in MechanicType.values) {
      if (type.value == raw) {
        return type;
      }
    }
    return null;
  }
}

/// 胜利条件类型。
enum WinRuleType {
  reachGoal('reach_goal'),
  collectCoinsMin('collect_coins_min'),
  surviveTime('survive_time');

  const WinRuleType(this.value);

  final String value;

  static WinRuleType? fromValue(String raw) {
    for (final WinRuleType type in WinRuleType.values) {
      if (type.value == raw) {
        return type;
      }
    }
    return null;
  }
}

/// 三星条件类型。
enum StarConditionType {
  clear('clear'),
  coinsRatio('coins_ratio'),
  timeUnder('time_under'),
  noDamage('no_damage'),
  defeatAllEnemies('defeat_all_enemies');

  const StarConditionType(this.value);

  final String value;

  static StarConditionType? fromValue(String raw) {
    for (final StarConditionType type in StarConditionType.values) {
      if (type.value == raw) {
        return type;
      }
    }
    return null;
  }
}

/// 变现钩子槽位。
enum MonetizationSlot {
  reviveOnFail('revive_on_fail'),
  doubleCoins('double_coins'),
  skipHardSection('skip_hard_section'),
  hintReveal('hint_reveal'),
  seasonBonus('season_bonus');

  const MonetizationSlot(this.value);

  final String value;

  static MonetizationSlot? fromValue(String raw) {
    for (final MonetizationSlot slot in MonetizationSlot.values) {
      if (slot.value == raw) {
        return slot;
      }
    }
    return null;
  }
}
