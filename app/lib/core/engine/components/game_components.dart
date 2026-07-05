import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:meme_game/core/engine/components/effect_components.dart';
import 'package:meme_game/core/engine/game_constants.dart';
import 'package:meme_game/core/engine/input/game_input_state.dart';
import 'package:meme_game/core/engine/sprites/sprite_registry.dart';

/// 玩家动画状态。
enum PlayerState {
  idle,
  run,
  jump,
}

/// 天空背景层（视差平铺）。
class SkyBackgroundComponent extends PositionComponent with HasGameReference<FlameGame> {
  SkyBackgroundComponent({
    required this.worldWidth,
    required this.worldHeight,
    required this.spriteRegistry,
  }) : super(priority: -10);

  final double worldWidth;
  final double worldHeight;
  final SpriteRegistry spriteRegistry;
  Sprite? _skySprite;
  static const double _parallaxFactor = 0.28;

  @override
  Future<void> onLoad() async {
    _skySprite = spriteRegistry.buildSprite('bg_sky');
    size = Vector2(worldWidth, worldHeight);
  }

  @override
  void render(Canvas canvas) {
    if (_skySprite == null) {
      final Paint paint = Paint()..color = const Color(0xFFB3E5FC);
      canvas.drawRect(size.toRect(), paint);
      return;
    }
    const double tileWidth = 320;
    const double tileHeight = 180;
    final double parallaxOffset =
        game.camera.viewfinder.position.x * _parallaxFactor;
    final double startX = -parallaxOffset % tileWidth - tileWidth;
    for (double x = startX; x < size.x + tileWidth; x += tileWidth) {
      for (double y = 0; y < size.y; y += tileHeight) {
        _skySprite!.render(
          canvas,
          position: Vector2(x, y),
          size: Vector2(tileWidth, tileHeight),
        );
      }
    }
  }
}

/// 平台碰撞体（瓦片贴图）。
class PlatformComponent extends PositionComponent with CollisionCallbacks {
  PlatformComponent({
    required super.position,
    required super.size,
    required this.isGround,
    required this.spriteRegistry,
  });

  final bool isGround;
  final SpriteRegistry spriteRegistry;
  Sprite? _tileSprite;

  @override
  Future<void> onLoad() async {
    _tileSprite = spriteRegistry.buildSprite(
      isGround ? 'tile_ground' : 'tile_platform',
    );
    add(RectangleHitbox());
  }

  @override
  void render(Canvas canvas) {
    if (_tileSprite == null) {
      final Paint paint = Paint()
        ..color = isGround ? const Color(0xFF66BB6A) : const Color(0xFF8D6E63);
      canvas.drawRect(size.toRect(), paint);
      return;
    }
    const double tileSize = 32;
    for (double x = 0; x < size.x; x += tileSize) {
      for (double y = 0; y < size.y; y += tileSize) {
        _tileSprite!.render(
          canvas,
          position: Vector2(x, y),
          size: Vector2(tileSize, tileSize),
        );
      }
    }
  }
}

/// 可收集金币。
class CoinComponent extends SpriteAnimationComponent with CollisionCallbacks {
  CoinComponent({
    required super.position,
    required this.spriteRegistry,
    required this.onCollected,
    this.onBurst,
  }) : super(size: Vector2.all(20));

  final SpriteRegistry spriteRegistry;
  final void Function() onCollected;
  final void Function(Vector2 worldPosition)? onBurst;
  bool _isCollected = false;

  @override
  Future<void> onLoad() async {
    animation = spriteRegistry.buildAnimation('coin', 'spin');
    add(CircleHitbox());
  }

  void collect() {
    if (_isCollected) {
      return;
    }
    _isCollected = true;
    onBurst?.call(position + size / 2);
    removeFromParent();
    onCollected();
  }
}

/// 巡逻敌人。
class EnemyComponent extends SpriteAnimationComponent with CollisionCallbacks {
  EnemyComponent({
    required super.position,
    required this.patrolMinX,
    required this.patrolMaxX,
    required this.spriteRegistry,
    required this.onDefeated,
  }) : super(size: Vector2(28, 28));

  final double patrolMinX;
  final double patrolMaxX;
  final SpriteRegistry spriteRegistry;
  final void Function() onDefeated;
  double _direction = 1;
  bool _isAlive = true;

  @override
  Future<void> onLoad() async {
    animation = spriteRegistry.buildAnimation('enemy', 'walk');
    add(RectangleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!_isAlive) {
      return;
    }
    position.x += _direction * GameConstants.enemyPatrolSpeed * dt;
    if (position.x <= patrolMinX) {
      position.x = patrolMinX;
      _direction = 1;
      scale.x = 1;
    } else if (position.x + size.x >= patrolMaxX) {
      position.x = patrolMaxX - size.x;
      _direction = -1;
      scale.x = -1;
    }
  }

  void defeat() {
    if (!_isAlive) {
      return;
    }
    _isAlive = false;
    removeFromParent();
    onDefeated();
  }

  bool get isAlive => _isAlive;
}

/// 假终点旗子（反转陷阱关）。
class FakeGoalComponent extends SpriteComponent with CollisionCallbacks {
  FakeGoalComponent({
    required super.position,
    required this.spriteRegistry,
    required this.onReached,
  }) : super(size: Vector2(24, 48));

  final SpriteRegistry spriteRegistry;
  final void Function() onReached;
  bool _isReached = false;

  @override
  Future<void> onLoad() async {
    sprite = spriteRegistry.buildSprite('goal_flag');
    add(RectangleHitbox());
  }

  void reach() {
    if (_isReached) {
      return;
    }
    _isReached = true;
    onReached();
  }

  @override
  void render(Canvas canvas) {
    canvas.saveLayer(null, Paint());
    super.render(canvas);
    canvas.drawColor(const Color(0x66FF1744), BlendMode.srcATop);
    canvas.restore();
  }
}

/// 终点旗子。
class GoalComponent extends SpriteComponent with CollisionCallbacks {
  GoalComponent({
    required super.position,
    required this.spriteRegistry,
    required this.onReached,
  }) : super(size: Vector2(24, 48));

  final SpriteRegistry spriteRegistry;
  final void Function() onReached;
  bool _isReached = false;

  @override
  Future<void> onLoad() async {
    sprite = spriteRegistry.buildSprite('goal_flag');
    add(RectangleHitbox());
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
class PlayerComponent extends SpriteAnimationGroupComponent<PlayerState>
    with CollisionCallbacks {
  PlayerComponent({
    required this.inputState,
    required this.onFellOff,
    required this.onHitByEnemy,
    required this.worldHeight,
    required this.spriteRegistry,
    this.onLand,
  }) : super(size: Vector2(28, 28));

  final GameInputState inputState;
  final void Function() onFellOff;
  final void Function() onHitByEnemy;
  final double worldHeight;
  final SpriteRegistry spriteRegistry;
  final void Function(Vector2 worldPosition)? onLand;

  Vector2 velocity = Vector2.zero();
  bool isOnGround = false;
  bool _isGrounded = false;
  bool _hasJumpedThisPress = false;
  bool _wasOnGround = false;
  double _coyoteTimer = 0;
  static const double _coyoteDuration = 0.12;

  /// 出生或穿模后，强制与平台对齐。
  void alignToPlatforms(Iterable<PlatformComponent> platforms) {
    for (final PlatformComponent platform in platforms) {
      _resolvePlatformCollision(platform);
    }
  }

  @override
  Future<void> onLoad() async {
    final SpriteAnimation? idle =
        spriteRegistry.buildAnimation('player', 'idle');
    final SpriteAnimation? run = spriteRegistry.buildAnimation('player', 'run');
    final SpriteAnimation? jump =
        spriteRegistry.buildAnimation('player', 'jump');
    if (idle != null && run != null && jump != null) {
      animations = <PlayerState, SpriteAnimation>{
        PlayerState.idle: idle,
        PlayerState.run: run,
        PlayerState.jump: jump,
      };
      current = PlayerState.idle;
    }
    add(RectangleHitbox());
    await super.onLoad();
  }

  @override
  void update(double dt) {
    super.update(dt);
    final bool wasGrounded = _isGrounded;
    final bool canJump = wasGrounded || _coyoteTimer > 0;
    isOnGround = wasGrounded;
    _isGrounded = false;
    _applyHorizontalInput();
    _applyJumpInput(canJump);
    _updateAnimationState(wasGrounded);
    velocity.y += GameConstants.gravity * dt;
    if (velocity.y > GameConstants.maxFallSpeed) {
      velocity.y = GameConstants.maxFallSpeed;
    }
    position += velocity * dt;
    if (wasGrounded) {
      _coyoteTimer = _coyoteDuration;
    } else {
      _coyoteTimer -= dt;
    }
    if (position.y > worldHeight + 80) {
      onFellOff();
    }
    if (!inputState.jumpHeld) {
      _hasJumpedThisPress = false;
    }
    _wasOnGround = wasGrounded;
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

  void _applyJumpInput(bool canJump) {
    if (!inputState.jumpHeld) {
      return;
    }
    if (!canJump || _hasJumpedThisPress) {
      return;
    }
    velocity.y = -GameConstants.playerJumpSpeed;
    _isGrounded = false;
    isOnGround = false;
    _hasJumpedThisPress = true;
    _coyoteTimer = 0;
  }

  void _updateAnimationState(bool wasGrounded) {
    if (animations == null || animations!.isEmpty) {
      return;
    }
    if (!wasGrounded && velocity.y.abs() > 1) {
      current = PlayerState.jump;
      return;
    }
    if (inputState.moveLeft) {
      scale.x = -1;
      current = PlayerState.run;
      return;
    }
    if (inputState.moveRight) {
      scale.x = 1;
      current = PlayerState.run;
      return;
    }
    scale.x = 1;
    current = PlayerState.idle;
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);
    _handleCollision(other, intersectionPoints);
  }

  @override
  void onCollision(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollision(intersectionPoints, other);
    _handleCollision(other, intersectionPoints);
  }

  void _handleCollision(
    PositionComponent other,
    Set<Vector2> intersectionPoints,
  ) {
    if (other is PlatformComponent) {
      _resolvePlatformCollision(other);
    } else if (other is CoinComponent) {
      other.collect();
    } else if (other is EnemyComponent) {
      _resolveEnemyCollision(other);
    } else if (other is GoalComponent) {
      other.reach();
    } else if (other is FakeGoalComponent) {
      other.reach();
    }
  }

  void _resolvePlatformCollision(PlatformComponent platform) {
    final double playerLeft = position.x;
    final double playerRight = position.x + size.x;
    final double playerTop = position.y;
    final double playerBottom = position.y + size.y;
    final double platLeft = platform.position.x;
    final double platRight = platform.position.x + platform.size.x;
    final double platTop = platform.position.y;
    final double platBottom = platform.position.y + platform.size.y;
    if (playerRight <= platLeft || playerLeft >= platRight) {
      return;
    }
    if (playerBottom <= platTop || playerTop >= platBottom) {
      return;
    }
    final double overlapTop = playerBottom - platTop;
    final double overlapBottom = platBottom - playerTop;
    if (velocity.y >= 0 && overlapTop <= overlapBottom) {
      position.y = platTop - size.y;
      velocity.y = 0;
      if (!_wasOnGround) {
        onLand?.call(Vector2(position.x + size.x / 2, position.y + size.y));
      }
      _isGrounded = true;
      isOnGround = true;
      return;
    }
    if (velocity.y < 0 && overlapBottom < overlapTop) {
      position.y = platBottom;
      velocity.y = 0;
      return;
    }
    if (velocity.y >= 0) {
      position.y = platTop - size.y;
      velocity.y = 0;
      if (!_wasOnGround) {
        onLand?.call(Vector2(position.x + size.x / 2, position.y + size.y));
      }
      _isGrounded = true;
      isOnGround = true;
    }
  }

  void _resolveEnemyCollision(EnemyComponent enemy) {
    if (!enemy.isAlive) {
      return;
    }
    final bool isStomp =
        velocity.y > 0 && (position.y + size.y - enemy.position.y) < 14;
    if (isStomp) {
      enemy.defeat();
      velocity.y = -GameConstants.playerJumpSpeed * 0.65;
      _isGrounded = false;
      isOnGround = false;
      return;
    }
    onHitByEnemy();
  }
}
