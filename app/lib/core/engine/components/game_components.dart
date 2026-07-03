import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:meme_game/core/engine/game_constants.dart';
import 'package:meme_game/core/engine/input/game_input_state.dart';

/// 平台碰撞体。
class PlatformComponent extends PositionComponent with CollisionCallbacks {
  PlatformComponent({
    required super.position,
    required super.size,
    required this.color,
  });

  final Color color;

  @override
  Future<void> onLoad() async {
    add(RectangleHitbox());
  }

  @override
  void render(Canvas canvas) {
    final Paint paint = Paint()..color = color;
    canvas.drawRect(size.toRect(), paint);
    final Paint border = Paint()
      ..color = const Color(0xFF1A1A1A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRect(size.toRect(), border);
  }
}

/// 可收集金币。
class CoinComponent extends PositionComponent with CollisionCallbacks {
  CoinComponent({
    required super.position,
    required this.onCollected,
  }) : super(size: Vector2.all(20));

  final void Function() onCollected;
  bool _isCollected = false;

  @override
  Future<void> onLoad() async {
    add(CircleHitbox());
  }

  @override
  void render(Canvas canvas) {
    if (_isCollected) {
      return;
    }
    final Paint paint = Paint()..color = const Color(0xFFFFD54F);
    canvas.drawCircle(Offset(size.x / 2, size.y / 2), 10, paint);
    final Paint shine = Paint()..color = const Color(0xFFFFF59D);
    canvas.drawCircle(const Offset(8, 8), 3, shine);
  }

  void collect() {
    if (_isCollected) {
      return;
    }
    _isCollected = true;
    removeFromParent();
    onCollected();
  }
}

/// 终点旗子。
class GoalComponent extends PositionComponent with CollisionCallbacks {
  GoalComponent({
    required super.position,
    required this.onReached,
  }) : super(size: Vector2(24, 48));

  final void Function() onReached;
  bool _isReached = false;

  @override
  Future<void> onLoad() async {
    add(RectangleHitbox());
  }

  @override
  void render(Canvas canvas) {
    final Paint pole = Paint()..color = const Color(0xFF424242);
    canvas.drawRect(Rect.fromLTWH(10, 0, 4, size.y), pole);
    final Paint flag = Paint()..color = const Color(0xFFE91E63);
    final Path path = Path()
      ..moveTo(14, 6)
      ..lineTo(24, 12)
      ..lineTo(14, 18)
      ..close();
    canvas.drawPath(path, flag);
  }

  void reach() {
    if (_isReached) {
      return;
    }
    _isReached = true;
    onReached();
  }
}

/// 玩家角色。
class PlayerComponent extends PositionComponent with CollisionCallbacks {
  PlayerComponent({
    required this.inputState,
    required this.onFellOff,
    required this.worldHeight,
  }) : super(size: Vector2(28, 28));

  final GameInputState inputState;
  final void Function() onFellOff;
  final double worldHeight;

  Vector2 velocity = Vector2.zero();
  bool isOnGround = false;
  bool _hasJumpedThisPress = false;

  @override
  Future<void> onLoad() async {
    add(RectangleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);
    isOnGround = false;
    _applyHorizontalInput();
    _applyJumpInput();
    velocity.y += GameConstants.gravity * dt;
    if (velocity.y > GameConstants.maxFallSpeed) {
      velocity.y = GameConstants.maxFallSpeed;
    }
    position += velocity * dt;
    if (position.y > worldHeight + 80) {
      onFellOff();
    }
    if (!inputState.jumpHeld) {
      _hasJumpedThisPress = false;
    }
  }

  void _applyHorizontalInput() {
    double direction = 0;
    if (inputState.moveLeft) {
      direction -= 1;
    }
    if (inputState.moveRight) {
      direction += 1;
    }
    velocity.x = direction * GameConstants.playerMoveSpeed;
  }

  void _applyJumpInput() {
    if (!inputState.jumpHeld) {
      return;
    }
    if (isOnGround && !_hasJumpedThisPress) {
      velocity.y = -GameConstants.playerJumpSpeed;
      isOnGround = false;
      _hasJumpedThisPress = true;
    }
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);
    if (other is PlatformComponent) {
      _resolvePlatformCollision(other, intersectionPoints);
    } else if (other is CoinComponent) {
      other.collect();
    } else if (other is GoalComponent) {
      other.reach();
    }
  }

  void _resolvePlatformCollision(
    PlatformComponent platform,
    Set<Vector2> intersectionPoints,
  ) {
    if (intersectionPoints.isEmpty) {
      return;
    }
    final double playerBottom = position.y + size.y;
    final double platformTop = platform.position.y;
    final bool isFalling = velocity.y >= 0;
    final bool landingOnTop =
        isFalling && playerBottom - platformTop < 18 && position.y < platform.position.y;
    if (landingOnTop) {
      position.y = platformTop - size.y;
      velocity.y = 0;
      isOnGround = true;
      return;
    }
    final double playerTop = position.y;
    final double platformBottom = platform.position.y + platform.size.y;
    if (velocity.y < 0 && playerTop < platformBottom) {
      position.y = platformBottom;
      velocity.y = 0;
    }
  }

  @override
  void render(Canvas canvas) {
    final Paint body = Paint()..color = const Color(0xFF7C4DFF);
    canvas.drawRect(size.toRect(), body);
    final Paint face = Paint()..color = const Color(0xFF1A1A1A);
    canvas.drawCircle(const Offset(9, 11), 2.5, face);
    canvas.drawCircle(const Offset(19, 11), 2.5, face);
    final Paint mouth = Paint()
      ..color = const Color(0xFF1A1A1A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawLine(const Offset(8, 20), const Offset(20, 20), mouth);
  }
}
