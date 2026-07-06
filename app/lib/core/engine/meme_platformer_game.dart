import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/events.dart';
import 'package:flame/experimental.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:meme_game/core/engine/components/effect_components.dart';
import 'package:meme_game/core/engine/components/game_components.dart';
import 'package:meme_game/core/engine/game_constants.dart';
import 'package:meme_game/core/engine/input/game_input_state.dart';
import 'package:meme_game/core/engine/sprites/sprite_registry.dart';
import 'package:meme_game/core/level/level_archetype_id.dart';
import 'package:meme_game/core/level/level_enemy_model.dart';
import 'package:meme_game/core/level/level_gravity_zone_model.dart';
import 'package:meme_game/core/level/level_model.dart';
import 'package:meme_game/core/level/level_rule_evaluator.dart';
import 'package:meme_game/core/level/level_rule_model.dart';
import 'package:meme_game/core/observability/app_logger.dart';

/// 游戏结束原因。
enum GameEndReason {
  victory,
  fellOff,
  hitByEnemy,
  timeUp,
  fakeGoal,
}

/// 搞事事横版闯关 Flame 游戏。
class MemePlatformerGame extends FlameGame
    with HasKeyboardHandlerComponents, HasCollisionDetection {
  MemePlatformerGame({
    required this.level,
    required this.inputState,
    required this.logger,
    required this.spriteRegistry,
    required this.onCoinCollected,
    required this.onGameEnded,
    this.onTimerTick,
  });

  final LevelModel level;
  final GameInputState inputState;
  final AppLogger logger;
  final SpriteRegistry spriteRegistry;
  final void Function(int totalCoins) onCoinCollected;
  final void Function(GameEndReason reason, int coins, double seconds) onGameEnded;
  final void Function(double remainingSeconds)? onTimerTick;

  late PlayerComponent _player;
  final LevelRuleEvaluator _ruleEvaluator = LevelRuleEvaluator();
  int _collectedCoins = 0;
  int _totalCoins = 0;
  int _defeatedEnemies = 0;
  double _elapsedSeconds = 0;
  int? _timeLimitSeconds;
  int? _timeWarnAtSeconds;
  bool _isEnded = false;
  bool _isPaused = false;

  @override
  Color backgroundColor() => const Color(0xFFB3E5FC);

  bool get isPaused => _isPaused;

  int get collectedCoins => _collectedCoins;

  int get totalCoins => _totalCoins;

  int get defeatedEnemies => _defeatedEnemies;

  double get elapsedSeconds => _elapsedSeconds;

  int? get timeLimitSeconds => _timeLimitSeconds;

  double? get remainingSeconds {
    if (_timeLimitSeconds == null) {
      return null;
    }
    return (_timeLimitSeconds! - _elapsedSeconds).clamp(0, _timeLimitSeconds!.toDouble());
  }

  bool get isTimeWarning {
    if (_timeWarnAtSeconds == null || _timeLimitSeconds == null) {
      return false;
    }
    final double? remaining = remainingSeconds;
    return remaining != null && remaining <= _timeWarnAtSeconds!;
  }

  void setPaused(bool value) {
    _isPaused = value;
    if (value) {
      pauseEngine();
    } else {
      resumeEngine();
    }
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    await spriteRegistry.preloadAllAssets();
    _loadMechanics();
    camera.viewfinder.anchor = Anchor.center;
    camera.backdrop.add(
      ViewportSkyBackdrop(spriteRegistry: spriteRegistry),
    );
    _buildLevel();
    _player = PlayerComponent(
      inputState: inputState,
      onFellOff: () => _finishGame(GameEndReason.fellOff),
      onHitByEnemy: () => _finishGame(GameEndReason.hitByEnemy),
      worldWidth: level.worldWidth,
      worldHeight: level.worldHeight,
      spriteRegistry: spriteRegistry,
      gravityZones: level.gravityZones,
      tileSize: level.tileSize.toDouble(),
      defaultGravityDirection: _readDefaultGravityDirection(),
      onLand: _spawnLandDust,
      onGravityDirectionChanged: _handleGravityDirectionChanged,
    );
    _player.position = _resolvePlayerSpawnPosition();
    _player.initializeGravityFromPosition();
    world.add(_player);
    _player.alignToPlatforms(
      world.children.whereType<PlatformComponent>(),
    );
    add(KeyboardListenerComponent());
    camera.follow(
      _player,
      horizontalOnly: true,
      maxSpeed: GameConstants.playerMoveSpeed * 3,
      snap: true,
    );
    camera.setBounds(
      Rectangle.fromLTWH(0, 0, level.worldWidth, level.worldHeight),
      considerViewport: true,
    );
    logger.info(
      module: 'core.engine',
      event: 'game.level.load.completed',
      message: '关卡加载完成',
      extra: <String, Object?>{
        'level_id': level.levelId,
        'archetype': level.archetype.value,
        'coin_count': _totalCoins,
        'enemy_count': level.enemies.length,
        'sprites_loaded': spriteRegistry.isLoaded,
      },
    );
  }

  void _loadMechanics() {
    _timeLimitSeconds = _ruleEvaluator.readTimeLimitSeconds(level.mechanics);
    for (final MechanicConfigModel mechanic in level.mechanics) {
      if (mechanic.type == MechanicType.timeLimit) {
        _timeWarnAtSeconds = mechanic.params['warn_at'] as int? ?? 15;
      }
    }
  }

  void _buildLevel() {
    for (final LevelRectModel rect in level.platforms) {
      final bool isGround = rect.y >= level.heightTiles - 2;
      world.add(
        PlatformComponent(
          position: Vector2(
            rect.x * level.tileSize.toDouble(),
            rect.y * level.tileSize.toDouble(),
          ),
          size: Vector2(
            rect.w * level.tileSize.toDouble(),
            rect.h * level.tileSize.toDouble(),
          ),
          isGround: isGround,
          spriteRegistry: spriteRegistry,
        ),
      );
    }
    for (final LevelGravityZoneModel zone in level.gravityZones) {
      world.add(
        GravityZoneOverlayComponent(
          zone: zone,
          tileSize: level.tileSize.toDouble(),
        ),
      );
    }
    if (level.gravityZones.length >= 2) {
      final double boundaryY = level.gravityZones.first.h * level.tileSize.toDouble();
      world.add(
        GravityBoundaryLineComponent(
          boundaryY: boundaryY,
          worldWidth: level.worldWidth,
        ),
      );
    }
    for (final LevelPointModel coin in level.coins) {
      _totalCoins += 1;
      world.add(
        CoinComponent(
          position: Vector2(
            coin.x * level.tileSize.toDouble() + 6,
            coin.y * level.tileSize.toDouble() + 6,
          ),
          spriteRegistry: spriteRegistry,
          onCollected: _handleCoinCollected,
          onBurst: _spawnCoinBurst,
        ),
      );
    }
    for (final LevelEnemyModel enemy in level.enemies) {
      final double tile = level.tileSize.toDouble();
      world.add(
        EnemyComponent(
          position: Vector2(enemy.x * tile, enemy.y * tile),
          patrolMinX: (enemy.x - enemy.patrolLeft) * tile,
          patrolMaxX: (enemy.x + enemy.patrolRight + 1) * tile,
          spriteRegistry: spriteRegistry,
          onDefeated: () {
            _defeatedEnemies += 1;
          },
        ),
      );
    }
    for (final LevelPointModel fakeGoal in level.fakeGoals) {
      world.add(
        FakeGoalComponent(
          position: Vector2(
            fakeGoal.x * level.tileSize.toDouble(),
            fakeGoal.y * level.tileSize.toDouble(),
          ),
          spriteRegistry: spriteRegistry,
          onReached: () => _finishGame(GameEndReason.fakeGoal),
        ),
      );
    }
    world.add(
      GoalComponent(
        position: Vector2(
          level.goal.x * level.tileSize.toDouble(),
          level.goal.y * level.tileSize.toDouble(),
        ),
        spriteRegistry: spriteRegistry,
        onReached: () => _finishGame(GameEndReason.victory),
      ),
    );
  }

  void _spawnCoinBurst(Vector2 worldPosition) {
    world.add(CoinBurstEffect(position: worldPosition - Vector2.all(12)));
  }

  void _spawnLandDust(Vector2 worldPosition) {
    world.add(LandDustEffect(position: worldPosition - Vector2(16, 10)));
  }

  int _readDefaultGravityDirection() {
    for (final MechanicConfigModel mechanic in level.mechanics) {
      if (mechanic.type == MechanicType.gravityFlip) {
        final String raw =
            mechanic.params['default_gravity'] as String? ?? 'down';
        return raw == 'up' ? -1 : 1;
      }
    }
    return 1;
  }

  void _handleGravityDirectionChanged(int gravityDirection) {
    world.add(
      LandDustEffect(
        position: _player.position + Vector2(_player.size.x / 2, _player.size.y / 2),
      ),
    );
    logger.info(
      module: 'core.engine',
      event: 'game.gravity.flipped',
      message: '重力方向切换',
      extra: <String, Object?>{
        'gravity_direction': gravityDirection,
        'velocity_y': _player.velocity.y,
      },
    );
  }

  void _handleCoinCollected() {
    _collectedCoins += 1;
    onCoinCollected(_collectedCoins);
  }

  Vector2 _resolvePlayerSpawnPosition() {
    const double playerWidth = 28;
    const double playerHeight = 28;
    final double tile = level.tileSize.toDouble();
    final double spawnX = level.playerSpawn.x * tile + 2;
    final double spawnTop = level.playerSpawn.y * tile;
    final double spawnCenterX = spawnX + playerWidth / 2;
    double? nearestPlatformTop;
    for (final LevelRectModel rect in level.platforms) {
      final double left = rect.x * tile;
      final double right = (rect.x + rect.w) * tile;
      final double top = rect.y * tile;
      if (spawnCenterX < left || spawnCenterX > right) {
        continue;
      }
      if (top < spawnTop + playerHeight - 16) {
        continue;
      }
      if (nearestPlatformTop == null || top < nearestPlatformTop) {
        nearestPlatformTop = top;
      }
    }
    final double spawnY = nearestPlatformTop != null
        ? nearestPlatformTop - playerHeight - 1
        : spawnTop;
    return Vector2(spawnX, spawnY);
  }

  void _finishGame(GameEndReason reason) {
    if (_isEnded) {
      return;
    }
    _isEnded = true;
    pauseEngine();
    logger.info(
      module: 'core.engine',
      event: 'game.session.ended',
      message: '单局结束',
      extra: <String, Object?>{
        'reason': reason.name,
        'coins': _collectedCoins,
        'defeated_enemies': _defeatedEnemies,
        'seconds': _elapsedSeconds,
      },
    );
    onGameEnded(reason, _collectedCoins, _elapsedSeconds);
  }

  @override
  void update(double dt) {
    if (_isPaused || _isEnded) {
      return;
    }
    super.update(dt);
    _elapsedSeconds += dt;
    _updateTimeLimit();
  }

  void _updateTimeLimit() {
    if (_timeLimitSeconds == null) {
      return;
    }
    final double remaining = remainingSeconds ?? 0;
    onTimerTick?.call(remaining);
    if (remaining <= 0) {
      _finishGame(GameEndReason.timeUp);
    }
  }
}

/// 键盘输入监听。
class KeyboardListenerComponent extends Component
    with HasGameReference<MemePlatformerGame>, KeyboardHandler {
  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    final GameInputState input = game.inputState;
    input.moveLeft = keysPressed.contains(LogicalKeyboardKey.arrowLeft) ||
        keysPressed.contains(LogicalKeyboardKey.keyA);
    input.moveRight = keysPressed.contains(LogicalKeyboardKey.arrowRight) ||
        keysPressed.contains(LogicalKeyboardKey.keyD);
    input.jumpHeld = keysPressed.contains(LogicalKeyboardKey.arrowUp) ||
        keysPressed.contains(LogicalKeyboardKey.keyW) ||
        keysPressed.contains(LogicalKeyboardKey.space);
    if (event is KeyDownEvent &&
        (event.logicalKey == LogicalKeyboardKey.arrowUp ||
            event.logicalKey == LogicalKeyboardKey.keyW ||
            event.logicalKey == LogicalKeyboardKey.space)) {
      input.jumpPressed = true;
    }
    return true;
  }
}
