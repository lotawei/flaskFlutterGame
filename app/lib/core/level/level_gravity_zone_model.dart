/// 重力分区（参考 ibb & obb：上下半区重力相反）。
class LevelGravityZoneModel {
  LevelGravityZoneModel({
    required this.x,
    required this.y,
    required this.w,
    required this.h,
    required this.gravityDirection,
  });

  final int x;
  final int y;
  final int w;
  final int h;

  /// 1 = 向下，-1 = 向上。
  final int gravityDirection;

  bool containsWorldPoint({
    required double worldX,
    required double worldY,
    required double tileSize,
  }) {
    final double left = x * tileSize;
    final double top = y * tileSize;
    final double right = (x + w) * tileSize;
    final double bottom = (y + h) * tileSize;
    return worldX >= left &&
        worldX < right &&
        worldY >= top &&
        worldY < bottom;
  }

  factory LevelGravityZoneModel.fromJson(Map<String, dynamic> json) {
    final String gravityRaw = json['gravity'] as String? ?? 'down';
    return LevelGravityZoneModel(
      x: json['x'] as int? ?? 0,
      y: json['y'] as int? ?? 0,
      w: json['w'] as int? ?? 1,
      h: json['h'] as int? ?? 1,
      gravityDirection: gravityRaw == 'up' ? -1 : 1,
    );
  }
}
