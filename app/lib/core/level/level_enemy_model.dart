/// 关卡敌人配置（tile 坐标）。
class LevelEnemyModel {
  LevelEnemyModel({
    required this.x,
    required this.y,
    required this.patrolLeft,
    required this.patrolRight,
  });

  final int x;
  final int y;
  final int patrolLeft;
  final int patrolRight;

  factory LevelEnemyModel.fromJson(Map<String, dynamic> json) {
    return LevelEnemyModel(
      x: json['x'] as int? ?? 0,
      y: json['y'] as int? ?? 0,
      patrolLeft: json['patrol_left'] as int? ?? 1,
      patrolRight: json['patrol_right'] as int? ?? 1,
    );
  }
}
