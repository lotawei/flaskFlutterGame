import 'dart:ui';

import 'package:flame/components.dart';

/// 金币收集爆散特效。
class CoinBurstEffect extends PositionComponent {
  CoinBurstEffect({required super.position}) : super(size: Vector2.all(24));

  double _elapsed = 0;

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;
    if (_elapsed >= 0.35) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final double progress = (_elapsed / 0.35).clamp(0, 1);
    final double radius = 6 + progress * 14;
    final Paint paint = Paint()
      ..color = Color.lerp(
        const Color(0xFFFFD54F),
        const Color(0x00FFD54F),
        progress,
      )!;
    canvas.drawCircle(Offset(size.x / 2, size.y / 2), radius, paint);
  }
}

/// 落地尘土特效。
class LandDustEffect extends PositionComponent {
  LandDustEffect({required super.position}) : super(size: Vector2(32, 12));

  double _elapsed = 0;

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;
    if (_elapsed >= 0.25) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final double progress = (_elapsed / 0.25).clamp(0, 1);
    final Paint paint = Paint()
      ..color = Color.lerp(
        const Color(0xFF8D6E63),
        const Color(0x008D6E63),
        progress,
      )!;
    canvas.drawOval(
      Rect.fromLTWH(2, 4, size.x - 4, size.y - 4),
      paint,
    );
  }
}
