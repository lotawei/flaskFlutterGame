import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:meme_game/core/engine/components/effect_components.dart';
import 'package:meme_game/core/engine/game_constants.dart';
import 'package:meme_game/core/engine/input/game_input_state.dart';
import 'package:meme_game/core/engine/sprites/sprite_registry.dart';
import 'package:meme_game/core/level/level_gravity_zone_model.dart';

/// 玩家动画状态。
enum PlayerState {
  idle,
  run,
  jump,
}

/// 平台碰撞解析轴（分轴移动避免穿墙）。
enum _CollisionAxis {
  horizontal,
  vertical,
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

/// 平台水平支撑区间。
class _PlatformSupport {
  const _PlatformSupport({required this.left, required this.right});

  final double left;
  final double right;
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
  static const int _platformResolvePasses = 4;

  int get currentGravityDirection => gravityDirection;

  /// 出生或穿模后，强制与平台对齐。
  void alignToPlatforms(Iterable<PlatformComponent> platforms) {
    for (final PlatformComponent platform in platforms) {
      _resolvePlatformCollision(platform, _CollisionAxis.horizontal);
      _resolvePlatformCollision(platform, _CollisionAxis.vertical);
    }
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
    _moveAlongAxis(
      axis: _CollisionAxis.horizontal,
      delta: velocity.x * dt,
    );
    _clampHorizontalBounds();
    _moveAlongAxis(
      axis: _CollisionAxis.vertical,
      delta: velocity.y * dt,
    );
    _enforcePlatformEdgeSupport();
    _resolvePlatformPenetration();
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

  void _moveAlongAxis({
    required _CollisionAxis axis,
    required double delta,
  }) {
    if (delta.abs() < 0.001) {
      return;
    }
    final double stepSign = delta.sign;
    double remaining = delta.abs();
    while (remaining > 0) {
      final double step = remaining < GameConstants.movementSubStep
          ? remaining
          : GameConstants.movementSubStep;
      final double beforePosition = axis == _CollisionAxis.horizontal
          ? position.x
          : position.y;
      if (axis == _CollisionAxis.horizontal) {
        position.x += step * stepSign;
      } else {
        position.y += step * stepSign;
      }
      _resolvePlatformContacts(axis);
      final double afterPosition = axis == _CollisionAxis.horizontal
          ? position.x
          : position.y;
      if ((afterPosition - beforePosition).abs() < 0.01 && step > 0.01) {
        if (axis == _CollisionAxis.horizontal) {
          velocity.x = 0;
        } else {
          velocity.y = 0;
        }
        break;
      }
      remaining -= step;
    }
  }

  void _resolvePlatformPenetration() {
    for (int pass = 0; pass < _platformResolvePasses; pass++) {
      var hasResolved = false;
      for (final PlatformComponent platform in _platforms) {
        if (_resolvePlatformCollision(platform, _CollisionAxis.horizontal)) {
          hasResolved = true;
        }
        if (_resolvePlatformCollision(platform, _CollisionAxis.vertical)) {
          hasResolved = true;
        }
      }
      if (!hasResolved) {
        break;
      }
    }
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

  void _resolvePlatformContacts(_CollisionAxis axis) {
    final Iterable<PlatformComponent> platforms =
        parent?.children.whereType<PlatformComponent>() ??
        const <PlatformComponent>[];
    for (int pass = 0; pass < _platformResolvePasses; pass++) {
      var hasResolved = false;
      for (final PlatformComponent platform in platforms) {
        if (_resolvePlatformCollision(platform, axis)) {
          hasResolved = true;
        }
      }
      if (!hasResolved) {
        break;
      }
    }
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

  void _clampHorizontalBounds() {
    final double worldMinX = 0;
    final double worldMaxX = worldWidth - size.x;
    if (position.x < worldMinX) {
      position.x = worldMinX;
      if (velocity.x < 0) {
        velocity.x = 0;
      }
    } else if (position.x > worldMaxX) {
      position.x = worldMaxX;
      if (velocity.x > 0) {
        velocity.x = 0;
      }
    }
  }

  void _enforcePlatformEdgeSupport() {
    if (!_isGrounded) {
      return;
    }
    if (gravityDirection > 0) {
      final _PlatformSupport? support = _findFeetSupport();
      if (support == null) {
        _isGrounded = false;
        isOnGround = false;
        return;
      }
      final double maxOverhang = 0;
      final double minX = support.left;
      final double maxX = support.right - size.x;
      if (position.x < minX) {
        position.x = minX;
        if (velocity.x < 0) {
          velocity.x = 0;
        }
      } else if (position.x > maxX) {
        position.x = maxX;
        if (velocity.x > 0) {
          velocity.x = 0;
        }
      }
      return;
    }
    final _PlatformSupport? ceilingSupport = _findHeadSupport();
    if (ceilingSupport == null) {
      _isGrounded = false;
      isOnGround = false;
      return;
    }
    final double maxOverhang = 0;
    final double minX = ceilingSupport.left;
    final double maxX = ceilingSupport.right - size.x;
    if (position.x < minX) {
      position.x = minX;
      if (velocity.x < 0) {
        velocity.x = 0;
      }
    } else if (position.x > maxX) {
      position.x = maxX;
      if (velocity.x > 0) {
        velocity.x = 0;
      }
    }
  }

  _PlatformSupport? _findFeetSupport() {
    final double feetY = position.y + size.y;
    final double playerLeft = position.x;
    final double playerRight = position.x + size.x;
    _PlatformSupport? bestSupport;
    double bestOverlap = 0;
    for (final PlatformComponent platform in _platforms) {
      final double platTop = platform.position.y;
      if ((feetY - platTop).abs() > GameConstants.groundSnapTolerance + 2) {
        continue;
      }
      final double platLeft = platform.position.x;
      final double platRight = platform.position.x + platform.size.x;
      final double overlapWidth = _computeHorizontalOverlap(
        playerLeft,
        playerRight,
        platLeft,
        platRight,
      );
      if (overlapWidth < GameConstants.minPlatformSupportOverlap) {
        continue;
      }
      if (overlapWidth > bestOverlap) {
        bestOverlap = overlapWidth;
        bestSupport = _PlatformSupport(left: platLeft, right: platRight);
      }
    }
    return bestSupport;
  }

  _PlatformSupport? _findHeadSupport() {
    final double headY = position.y;
    final double playerLeft = position.x;
    final double playerRight = position.x + size.x;
    _PlatformSupport? bestSupport;
    double bestOverlap = 0;
    for (final PlatformComponent platform in _platforms) {
      final double platBottom = platform.position.y + platform.size.y;
      if ((platBottom - headY).abs() > GameConstants.groundSnapTolerance + 2) {
        continue;
      }
      final double platLeft = platform.position.x;
      final double platRight = platform.position.x + platform.size.x;
      final double overlapWidth = _computeHorizontalOverlap(
        playerLeft,
        playerRight,
        platLeft,
        platRight,
      );
      if (overlapWidth < GameConstants.minPlatformSupportOverlap) {
        continue;
      }
      if (overlapWidth > bestOverlap) {
        bestOverlap = overlapWidth;
        bestSupport = _PlatformSupport(left: platLeft, right: platRight);
      }
    }
    return bestSupport;
  }

  double _clampXToPlatform(double platLeft, double platRight) {
    final double minX = platLeft;
    final double maxX = platRight - size.x;
    if (position.x < minX) {
      return minX;
    }
    if (position.x > maxX) {
      return maxX;
    }
    return position.x;
  }

  double _computeHorizontalOverlap(
    double aLeft,
    double aRight,
    double bLeft,
    double bRight,
  ) {
    final double left = aLeft > bLeft ? aLeft : bLeft;
    final double right = aRight < bRight ? aRight : bRight;
    if (right <= left) {
      return 0;
    }
    return right - left;
  }

  Iterable<PlatformComponent> get _platforms =>
      parent?.children.whereType<PlatformComponent>() ??
      const <PlatformComponent>[];

  void _markGrounded() {
    _isGrounded = true;
    isOnGround = true;
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

  bool _resolvePlatformCollision(
    PlatformComponent platform,
    _CollisionAxis axis,
  ) {
    final double playerLeft = position.x;
    final double playerRight = position.x + size.x;
    final double playerTop = position.y;
    final double playerBottom = position.y + size.y;
    final double platLeft = platform.position.x;
    final double platRight = platform.position.x + platform.size.x;
    final double platTop = platform.position.y;
    final double platBottom = platform.position.y + platform.size.y;
    if (playerRight <= platLeft ||
        playerLeft >= platRight ||
        playerBottom <= platTop ||
        playerTop >= platBottom) {
      return false;
    }
    final double overlapLeft = playerRight - platLeft;
    final double overlapRight = platRight - playerLeft;
    final double overlapTop = playerBottom - platTop;
    final double overlapBottom = platBottom - playerTop;
    final double minHorizontal = overlapLeft < overlapRight ? overlapLeft : overlapRight;
    final double minVertical = overlapTop < overlapBottom ? overlapTop : overlapBottom;
    if (axis == _CollisionAxis.horizontal) {
      return _resolveHorizontalPlatformCollision(
        platLeft: platLeft,
        platRight: platRight,
        platTop: platTop,
        overlapLeft: overlapLeft,
        overlapRight: overlapRight,
        overlapTop: overlapTop,
        minHorizontal: minHorizontal,
        minVertical: minVertical,
      );
    }
    return _resolveVerticalPlatformCollision(
      platLeft: platLeft,
      platRight: platRight,
      platTop: platTop,
      platBottom: platBottom,
      overlapTop: overlapTop,
      overlapBottom: overlapBottom,
      minHorizontal: minHorizontal,
      minVertical: minVertical,
    );
  }

  bool _resolveHorizontalPlatformCollision({
    required double platLeft,
    required double platRight,
    required double platTop,
    required double overlapLeft,
    required double overlapRight,
    required double overlapTop,
    required double minHorizontal,
    required double minVertical,
  }) {
    final double playerBottom = position.y + size.y;
    if (gravityDirection > 0 &&
        velocity.y < 0 &&
        overlapTop <= GameConstants.groundSnapTolerance &&
        playerBottom <= platTop + GameConstants.groundSnapTolerance) {
      return false;
    }
    final bool isSideContact = playerBottom > platTop + 2 ||
        minHorizontal <= minVertical + GameConstants.sideCollisionBias;
    if (!isSideContact) {
      return false;
    }
    if (overlapLeft < overlapRight) {
      position.x = platLeft - size.x;
    } else {
      position.x = platRight;
    }
    velocity.x = 0;
    return true;
  }

  bool _resolveVerticalPlatformCollision({
    required double platLeft,
    required double platRight,
    required double platTop,
    required double platBottom,
    required double overlapTop,
    required double overlapBottom,
    required double minHorizontal,
    required double minVertical,
  }) {
    if (gravityDirection > 0) {
      if (overlapTop > GameConstants.groundSnapTolerance + 8) {
        return false;
      }
      if (velocity.y < 0 && overlapTop <= GameConstants.groundSnapTolerance) {
        return false;
      }
      final bool shouldLandOnTop = overlapTop > 0 &&
          overlapTop <= GameConstants.groundSnapTolerance + 6;
      final double overlapWidth = _computeHorizontalOverlap(
        position.x,
        position.x + size.x,
        platLeft,
        platRight,
      );
      if (shouldLandOnTop &&
          overlapWidth >= GameConstants.minPlatformSupportOverlap) {
        final bool justLanded = !_wasOnGround;
        position.y = platTop - size.y;
        position.x = _clampXToPlatform(platLeft, platRight);
        velocity.y = 0;
        if (justLanded) {
          onLand?.call(Vector2(position.x + size.x / 2, position.y + size.y));
        }
        _markGrounded();
        return true;
      }
      if (shouldLandOnTop) {
        return false;
      }
      if (minHorizontal + GameConstants.sideCollisionBias <= minVertical) {
        return false;
      }
      if (velocity.y < 0) {
        position.y = platBottom;
        velocity.y = 0;
        return true;
      }
      position.y = platTop - size.y;
      velocity.y = 0;
      _markGrounded();
      return true;
    }
    if (overlapBottom > GameConstants.groundSnapTolerance + 8) {
      return false;
    }
    if (velocity.y > 0 &&
        overlapBottom <= GameConstants.groundSnapTolerance) {
      return false;
    }
    final bool shouldLandOnBottom = overlapBottom > 0 &&
        overlapBottom <= GameConstants.groundSnapTolerance + 6;
    final double overlapWidth = _computeHorizontalOverlap(
      position.x,
      position.x + size.x,
      platLeft,
      platRight,
    );
    if (shouldLandOnBottom &&
        overlapWidth >= GameConstants.minPlatformSupportOverlap) {
      final bool justLanded = !_wasOnGround;
      position.y = platBottom;
      position.x = _clampXToPlatform(platLeft, platRight);
      velocity.y = 0;
      if (justLanded) {
        onLand?.call(Vector2(position.x + size.x / 2, position.y));
      }
      _markGrounded();
      return true;
    }
    if (shouldLandOnBottom) {
      return false;
    }
    if (minHorizontal + GameConstants.sideCollisionBias <= minVertical) {
      return false;
    }
    if (velocity.y > 0) {
      position.y = platTop - size.y;
      velocity.y = 0;
      return true;
    }
    position.y = platBottom;
    velocity.y = 0;
    _markGrounded();
    return true;
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
