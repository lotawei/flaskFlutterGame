import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:meme_game/core/engine/components/effect_components.dart';
import 'package:meme_game/core/engine/game_constants.dart';
import 'package:meme_game/core/engine/input/game_input_state.dart';
import 'package:meme_game/core/engine/sprites/sprite_registry.dart';
import 'package:meme_game/core/engine/platform_physics.dart';
import 'package:meme_game/core/level/level_gravity_zone_model.dart';

/// 玩家动画状态。
enum PlayerState {
  idle,
  run,
  jump,
}

/// 天空背景（挂载在 camera.backdrop，始终铺满屏幕，不受世界左边界影响）。
class ViewportSkyBackdrop extends Component with HasGameReference<FlameGame> {
  ViewportSkyBackdrop({required this.spriteRegistry});

  final SpriteRegistry spriteRegistry;
  Sprite? _skySprite;
  static const double _parallaxFactor = 0.28;

  @override
  Future<void> onLoad() async {
    _skySprite = spriteRegistry.buildSprite('bg_sky');
    await super.onLoad();
  }

  @override
  void render(Canvas canvas) {
    final Vector2 viewportSize = game.camera.viewport.virtualSize;
    final Paint skyPaint = Paint()..color = const Color(0xFFB3E5FC);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, viewportSize.x, viewportSize.y),
      skyPaint,
    );
    if (_skySprite == null) {
      return;
    }
    const double tileWidth = 320;
    const double tileHeight = 180;
    final double parallaxOffset =
        game.camera.viewfinder.position.x * _parallaxFactor;
    final double startX = -(parallaxOffset % tileWidth);
    for (double x = startX - tileWidth; x < viewportSize.x + tileWidth; x += tileWidth) {
      for (double y = 0; y < viewportSize.y; y += tileHeight) {
        _skySprite!.render(
          canvas,
          position: Vector2(x, y),
          size: Vector2(tileWidth, tileHeight),
        );
      }
    }
  }
}

/// 天空背景层（世界坐标，保留供非 camera 场景复用）。
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

/// 重力分区可视化（ibb & obb 风格半透明色带）。
class GravityZoneOverlayComponent extends PositionComponent {
  GravityZoneOverlayComponent({
    required this.zone,
    required this.tileSize,
  }) : super(
          position: Vector2(zone.x * tileSize, zone.y * tileSize),
          size: Vector2(zone.w * tileSize, zone.h * tileSize),
          priority: -5,
        );

  final LevelGravityZoneModel zone;
  final double tileSize;

  @override
  void render(Canvas canvas) {
    final bool isGravityUp = zone.gravityDirection < 0;
    final Color fill = isGravityUp
        ? const Color(0x33CE93D8)
        : const Color(0x3390CAF9);
    final Color border = isGravityUp
        ? const Color(0x889C27B0)
        : const Color(0x8842A5F5);
    canvas.drawRect(
      size.toRect(),
      Paint()..color = fill,
    );
    canvas.drawRect(
      size.toRect(),
      Paint()
        ..color = border
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }
}

/// 玩家角色。
class PlayerComponent extends SpriteAnimationGroupComponent<PlayerState>
    with CollisionCallbacks {
  PlayerComponent({
    required this.inputState,
    required this.onFellOff,
    required this.onHitByEnemy,
    required this.worldWidth,
    required this.worldHeight,
    required this.spriteRegistry,
    this.gravityZones = const <LevelGravityZoneModel>[],
    this.tileSize = 32,
    this.defaultGravityDirection = 1,
    this.onLand,
    this.onGravityDirectionChanged,
  }) : super(size: Vector2(28, 28));

  final GameInputState inputState;
  final void Function() onFellOff;
  final void Function() onHitByEnemy;
  final double worldWidth;
  final double worldHeight;
  final SpriteRegistry spriteRegistry;
  final List<LevelGravityZoneModel> gravityZones;
  final double tileSize;
  final int defaultGravityDirection;
  final void Function(Vector2 worldPosition)? onLand;
  final void Function(int gravityDirection)? onGravityDirectionChanged;

  Vector2 velocity = Vector2.zero();
  bool isOnGround = false;
  bool _isGrounded = false;
  bool _hasJumpedThisPress = false;
  bool _wasOnGround = false;
  double _coyoteTimer = 0;
  int _facingDirection = 1;
  int gravityDirection = 1;
  static const double _coyoteDuration = 0.12;

  int get currentGravityDirection => gravityDirection;

  List<PlatformSurface> _buildPlatformSurfaces() {
    return _platforms
        .map(
          (PlatformComponent platform) => PlatformSurface(
            left: platform.position.x,
            top: platform.position.y,
            right: platform.position.x + platform.size.x,
            bottom: platform.position.y + platform.size.y,
          ),
        )
        .toList();
  }

  PlatformPhysicsSolver _createPhysicsSolver() {
    return PlatformPhysicsSolver(
      platforms: _buildPlatformSurfaces(),
      worldWidth: worldWidth,
      worldHeight: worldHeight,
      gravityDirection: gravityDirection,
      playerWidth: size.x,
      playerHeight: size.y,
    );
  }

  /// 出生或穿模后，强制与平台对齐。
  void alignToPlatforms(Iterable<PlatformComponent> platforms) {
    final PlatformPhysicsResult result = _createPhysicsSolver().snapToValid(
      x: position.x,
      y: position.y,
    );
    position.x = result.x;
    position.y = result.y;
    velocity = Vector2.zero();
    _isGrounded = result.isGrounded;
    isOnGround = result.isGrounded;
  }

  @override
  Future<void> onLoad() async {
    gravityDirection = defaultGravityDirection;
    scale.y = gravityDirection.toDouble();
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
    _applyHorizontalInput(dt);
    _applyJumpInput(canJump);
    _updateGravityDirection();
    velocity.y += gravityDirection * GameConstants.gravity * dt;
    if (gravityDirection > 0) {
      if (velocity.y > GameConstants.maxFallSpeed) {
        velocity.y = GameConstants.maxFallSpeed;
      }
    } else if (velocity.y < -GameConstants.maxFallSpeed) {
      velocity.y = -GameConstants.maxFallSpeed;
    }
    final PlatformPhysicsResult physics = _createPhysicsSolver().simulate(
      x: position.x,
      y: position.y,
      velocityX: velocity.x,
      velocityY: velocity.y,
      dt: dt,
      wasGrounded: wasGrounded,
    );
    position.x = physics.x;
    position.y = physics.y;
    velocity.x = physics.velocityX;
    velocity.y = physics.velocityY;
    _isGrounded = physics.isGrounded;
    isOnGround = physics.isGrounded;
    if (physics.justLanded) {
      final Vector2 landPoint = gravityDirection > 0
          ? Vector2(position.x + size.x / 2, position.y + size.y)
          : Vector2(position.x + size.x / 2, position.y);
      onLand?.call(landPoint);
    }
    _updateAnimationState(wasGrounded);
    if (wasGrounded || _isGrounded) {
      _coyoteTimer = _coyoteDuration;
    } else {
      _coyoteTimer -= dt;
    }
    if (gravityDirection > 0 && position.y > worldHeight + 80) {
      onFellOff();
    } else if (gravityDirection < 0 && position.y < -80) {
      onFellOff();
    }
    if (!inputState.jumpHeld) {
      _hasJumpedThisPress = false;
    }
    _wasOnGround = wasGrounded || _isGrounded;
  }

  void _applyHorizontalInput(double dt) {
    final bool isGroundedMove = _isGrounded || _wasOnGround;
    if (!inputState.moveLeft && !inputState.moveRight) {
      velocity.x = 0;
      return;
    }
    double targetVelocityX = 0;
    if (inputState.moveLeft) {
      targetVelocityX -= isGroundedMove
          ? GameConstants.playerMoveSpeed
          : GameConstants.playerAirMoveSpeed;
    }
    if (inputState.moveRight) {
      targetVelocityX += isGroundedMove
          ? GameConstants.playerMoveSpeed
          : GameConstants.playerAirMoveSpeed;
    }
    if (isGroundedMove) {
      velocity.x = targetVelocityX;
      return;
    }
    velocity.x = _moveTowards(
      velocity.x,
      targetVelocityX,
      GameConstants.playerMoveAcceleration * dt,
    );
  }

  double _moveTowards(double current, double target, double maxDelta) {
    if ((target - current).abs() <= maxDelta) {
      return target;
    }
    return current + (target - current).sign * maxDelta;
  }

  void _applyJumpInput(bool canJump) {
    if (!inputState.jumpHeld) {
      return;
    }
    if (!canJump || _hasJumpedThisPress) {
      return;
    }
    velocity.y = -gravityDirection * GameConstants.playerJumpSpeed;
    _isGrounded = false;
    isOnGround = false;
    _hasJumpedThisPress = true;
    _coyoteTimer = 0;
  }

  void _updateAnimationState(bool wasGrounded) {
    if (animations == null || animations!.isEmpty) {
      return;
    }
    if (inputState.moveLeft && !inputState.moveRight) {
      _facingDirection = -1;
    } else if (inputState.moveRight && !inputState.moveLeft) {
      _facingDirection = 1;
    }
    scale.x = _facingDirection.toDouble();
    scale.y = gravityDirection.toDouble();
    final bool isAirborne = !wasGrounded && !_isGrounded && velocity.y.abs() > 12;
    if (isAirborne) {
      current = PlayerState.jump;
      return;
    }
    if (inputState.moveLeft || inputState.moveRight) {
      current = PlayerState.run;
      return;
    }
    current = PlayerState.idle;
  }

  void _updateGravityDirection() {
    if (gravityZones.isEmpty) {
      return;
    }
    final double centerX = position.x + size.x / 2;
    final double centerY = position.y + size.y / 2;
    int nextDirection = defaultGravityDirection;
    for (final LevelGravityZoneModel zone in gravityZones) {
      if (zone.containsWorldPoint(
        worldX: centerX,
        worldY: centerY,
        tileSize: tileSize,
      )) {
        nextDirection = zone.gravityDirection;
      }
    }
    if (nextDirection == gravityDirection) {
      return;
    }
    gravityDirection = nextDirection;
    scale.y = gravityDirection.toDouble();
    onGravityDirectionChanged?.call(gravityDirection);
  }

  Iterable<PlatformComponent> get _platforms =>
      parent?.children.whereType<PlatformComponent>() ??
      const <PlatformComponent>[];

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
      return;
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

  void _resolveEnemyCollision(EnemyComponent enemy) {
    if (!enemy.isAlive) {
      return;
    }
    final bool isStomp = gravityDirection > 0
        ? velocity.y > 0 && (position.y + size.y - enemy.position.y) < 14
        : velocity.y < 0 &&
            (enemy.position.y + enemy.size.y - position.y) < 14;
    if (isStomp) {
      enemy.defeat();
      velocity.y = -gravityDirection * GameConstants.playerJumpSpeed * 0.65;
      _isGrounded = false;
      isOnGround = false;
      return;
    }
    onHitByEnemy();
  }
}
