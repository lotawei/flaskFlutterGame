/// 梗文结算语录。
class MemeQuotes {
  MemeQuotes._();

  static const List<String> victoryQuotes = <String>[
    '搞事成功，泰裤辣！',
    '这波属于是专业搞事选手',
    '旗子到了，梗也到了',
    '来财来财，金币全收',
  ];

  static const List<String> failFellQuotes = <String>[
    '地心引力：不客气',
    '下次一定好好跳',
    '掉下去了，但梗还在',
    '耗子尾汁，大意了',
  ];

  static const List<String> failEnemyQuotes = <String>[
    '侧面硬刚，属实勇',
    '敌人：你礼貌吗？',
    '应该从头顶踩啊兄弟',
    '这波是送人头',
  ];

  static String pickVictoryQuote(int seed) {
    return victoryQuotes[seed % victoryQuotes.length];
  }

  static const List<String> failTimeQuotes = <String>[
    '时间到，下次早点冲',
    '读秒读没了，属于是',
    '卡点失败，再练一把',
    '时间管理大师（反向）',
  ];

  static const List<String> failFakeGoalQuotes = <String>[
    '假旗子也敢冲？',
    '这波是被套路了',
    '真终点在别处啊兄弟',
    '反转了，但没完全反转',
  ];

  static String pickFailQuote({required String reason, required int seed}) {
    if (reason == 'hitByEnemy') {
      return failEnemyQuotes[seed % failEnemyQuotes.length];
    }
    if (reason == 'timeUp') {
      return failTimeQuotes[seed % failTimeQuotes.length];
    }
    if (reason == 'fakeGoal') {
      return failFakeGoalQuotes[seed % failFakeGoalQuotes.length];
    }
    return failFellQuotes[seed % failFellQuotes.length];
  }
}
