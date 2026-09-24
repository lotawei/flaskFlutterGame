import 'package:meme_game/core/level/level_archetype_id.dart';
import 'package:meme_game/core/level/level_rule_model.dart';

/// 玩法原型默认配置（与 shared/level/archetypes/*.json 对齐）。
class ArchetypeDefinition {
  ArchetypeDefinition({
    required this.archetypeId,
    required this.name,
    required this.tagline,
    required this.coreLoop,
    required this.defaultMechanics,
    required this.defaultWinRules,
    required this.defaultStarRules,
    required this.defaultMonetizationHooks,
  });

  final LevelArchetypeId archetypeId;
  final String name;
  final String tagline;
  final String coreLoop;
  final List<MechanicConfigModel> defaultMechanics;
  final List<WinRuleModel> defaultWinRules;
  final List<StarRuleModel> defaultStarRules;
  final List<MonetizationHookModel> defaultMonetizationHooks;
}

/// 玩法原型注册表：策划选 archetype，系统自动补齐默认规则。
class ArchetypeRegistry {
  ArchetypeRegistry._();

  static final Map<LevelArchetypeId, ArchetypeDefinition> _definitions =
      <LevelArchetypeId, ArchetypeDefinition>{
    LevelArchetypeId.rushStandard: ArchetypeDefinition(
      archetypeId: LevelArchetypeId.rushStandard,
      name: '标准冲关',
      tagline: '跑到终点就赢',
      coreLoop: '移动→跳跃→收币→踩敌人→到旗',
      defaultMechanics: <MechanicConfigModel>[],
      defaultWinRules: <WinRuleModel>[
        WinRuleModel(type: WinRuleType.reachGoal, params: <String, Object?>{}),
      ],
      defaultStarRules: <StarRuleModel>[
        StarRuleModel(
          star: 1,
          condition: StarConditionType.clear,
          params: <String, Object?>{},
        ),
        StarRuleModel(
          star: 2,
          condition: StarConditionType.coinsRatio,
          params: <String, Object?>{'ratio': 0.6},
        ),
        StarRuleModel(
          star: 3,
          condition: StarConditionType.defeatAllEnemies,
          params: <String, Object?>{},
        ),
      ],
      defaultMonetizationHooks: <MonetizationHookModel>[
        MonetizationHookModel(
          slot: MonetizationSlot.reviveOnFail,
          isEnabled: true,
        ),
        MonetizationHookModel(
          slot: MonetizationSlot.doubleCoins,
          isEnabled: true,
        ),
      ],
    ),
    LevelArchetypeId.timedRush: ArchetypeDefinition(
      archetypeId: LevelArchetypeId.timedRush,
      name: '限时冲关',
      tagline: '倒计时压迫感',
      coreLoop: '读秒→风险路线→冲线抢时间',
      defaultMechanics: <MechanicConfigModel>[
        MechanicConfigModel(
          type: MechanicType.timeLimit,
          params: <String, Object?>{'seconds': 90, 'warn_at': 15},
        ),
      ],
      defaultWinRules: <WinRuleModel>[
        WinRuleModel(type: WinRuleType.reachGoal, params: <String, Object?>{}),
      ],
      defaultStarRules: <StarRuleModel>[
        StarRuleModel(
          star: 1,
          condition: StarConditionType.clear,
          params: <String, Object?>{},
        ),
        StarRuleModel(
          star: 2,
          condition: StarConditionType.timeUnder,
          params: <String, Object?>{'seconds': 60},
        ),
        StarRuleModel(
          star: 3,
          condition: StarConditionType.timeUnder,
          params: <String, Object?>{'seconds': 45},
        ),
      ],
      defaultMonetizationHooks: <MonetizationHookModel>[
        MonetizationHookModel(
          slot: MonetizationSlot.reviveOnFail,
          isEnabled: true,
        ),
        MonetizationHookModel(
          slot: MonetizationSlot.hintReveal,
          isEnabled: true,
        ),
      ],
    ),
    LevelArchetypeId.reversalTrap: ArchetypeDefinition(
      archetypeId: LevelArchetypeId.reversalTrap,
      name: '反转陷阱',
      tagline: '假平台假终点',
      coreLoop: '试探→被骗→找真路',
      defaultMechanics: <MechanicConfigModel>[
        MechanicConfigModel(
          type: MechanicType.reversalFakeGoal,
          params: <String, Object?>{'fake_goal_fail': true},
        ),
      ],
      defaultWinRules: <WinRuleModel>[
        WinRuleModel(
          type: WinRuleType.reachGoal,
          params: <String, Object?>{'must_be_real_goal': true},
        ),
      ],
      defaultStarRules: <StarRuleModel>[
        StarRuleModel(
          star: 1,
          condition: StarConditionType.clear,
          params: <String, Object?>{},
        ),
        StarRuleModel(
          star: 2,
          condition: StarConditionType.noDamage,
          params: <String, Object?>{},
        ),
        StarRuleModel(
          star: 3,
          condition: StarConditionType.coinsRatio,
          params: <String, Object?>{'ratio': 1.0},
        ),
      ],
      defaultMonetizationHooks: <MonetizationHookModel>[
        MonetizationHookModel(
          slot: MonetizationSlot.hintReveal,
          isEnabled: true,
        ),
      ],
    ),
    LevelArchetypeId.greedTax: ArchetypeDefinition(
      archetypeId: LevelArchetypeId.greedTax,
      name: '来财税局',
      tagline: '越贪越难',
      coreLoop: '收币→难度上升→路线取舍',
      defaultMechanics: <MechanicConfigModel>[
        MechanicConfigModel(
          type: MechanicType.coinGreedScale,
          params: <String, Object?>{
            'enemy_speed_per_coin': 2,
            'tax_zone_after_coins': 4,
          },
        ),
      ],
      defaultWinRules: <WinRuleModel>[
        WinRuleModel(type: WinRuleType.reachGoal, params: <String, Object?>{}),
      ],
      defaultStarRules: <StarRuleModel>[
        StarRuleModel(
          star: 1,
          condition: StarConditionType.clear,
          params: <String, Object?>{},
        ),
        StarRuleModel(
          star: 2,
          condition: StarConditionType.coinsRatio,
          params: <String, Object?>{'ratio': 0.5},
        ),
        StarRuleModel(
          star: 3,
          condition: StarConditionType.coinsRatio,
          params: <String, Object?>{'ratio': 1.0},
        ),
      ],
      defaultMonetizationHooks: <MonetizationHookModel>[
        MonetizationHookModel(
          slot: MonetizationSlot.doubleCoins,
          isEnabled: true,
        ),
        MonetizationHookModel(
          slot: MonetizationSlot.skipHardSection,
          isEnabled: true,
        ),
      ],
    ),
    LevelArchetypeId.lieFlat: ArchetypeDefinition(
      archetypeId: LevelArchetypeId.lieFlat,
      name: '躺平计量',
      tagline: '站着掉面子',
      coreLoop: '移动掉面子→找区躺平回血',
      defaultMechanics: <MechanicConfigModel>[
        MechanicConfigModel(
          type: MechanicType.lieFlatMeter,
          params: <String, Object?>{
            'drain_per_sec_moving': 8,
            'recover_per_sec_idle': 12,
            'fail_at_zero': true,
          },
        ),
      ],
      defaultWinRules: <WinRuleModel>[
        WinRuleModel(type: WinRuleType.reachGoal, params: <String, Object?>{}),
      ],
      defaultStarRules: <StarRuleModel>[
        StarRuleModel(
          star: 1,
          condition: StarConditionType.clear,
          params: <String, Object?>{},
        ),
        StarRuleModel(
          star: 2,
          condition: StarConditionType.timeUnder,
          params: <String, Object?>{'seconds': 120},
        ),
        StarRuleModel(
          star: 3,
          condition: StarConditionType.noDamage,
          params: <String, Object?>{},
        ),
      ],
      defaultMonetizationHooks: <MonetizationHookModel>[
        MonetizationHookModel(
          slot: MonetizationSlot.reviveOnFail,
          isEnabled: true,
        ),
      ],
    ),
  };

  static ArchetypeDefinition getDefinition(LevelArchetypeId id) {
    return _definitions[id] ?? _definitions[LevelArchetypeId.rushStandard]!;
  }

  static List<ArchetypeDefinition> listAll() {
    return _definitions.values.toList();
  }
}
