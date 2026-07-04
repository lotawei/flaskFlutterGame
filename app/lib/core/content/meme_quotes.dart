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

  static String pickFailQuote({required String reason, required int seed}) {
    if (reason == 'hitByEnemy') {
      return failEnemyQuotes[seed % failEnemyQuotes.length];
    }
    return failFellQuotes[seed % failFellQuotes.length];
  }
}
