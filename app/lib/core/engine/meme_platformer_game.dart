import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:meme_game/core/engine/components/game_components.dart';
import 'package:meme_game/core/engine/game_constants.dart';
import 'package:meme_game/core/engine/input/game_input_state.dart';
import 'package:meme_game/core/level/level_model.dart';
import 'package:meme_game/core/observability/app_logger.dart';

/// 游戏结束原因。
enum GameEndReason {
  victory,
  fellOff,
}

/// 搞事事横版闯关 Flame 游戏。
class MemePlatformerGame extends FlameGame
    with HasKeyboardHandlerComponents, HasCollisionDetection {
  MemePlatformerGame({
    required this.level,
    required this.inputState,
    required this.logger,
    required this.onCoinCollected,
    required this.onGameEnded,
  });

  final LevelModel level;
  final GameInputState inputState;
  final AppLogger logger;
  final void Function(int totalCoins) onCoinCollected;
  final void Function(GameEndReason reason, int coins, double seconds) onGameEnded;

  late PlayerComponent _player;
  int _collectedCoins = 0;
  int _totalCoins = 0;
  double _elapsedSeconds = 0;
  bool _isEnded = false;
  bool _isPaused = false;

  @override
  Color backgroundColor() => const Color(0xFFB3E5FC);

  bool get isPaused => _isPaused;

  int get collectedCoins => _collectedCoins;

  int get totalCoins => _totalCoins;

  double get elapsedSeconds => _elapsedSeconds;

  void setPaused(bool value) {
    _isPaused = value;
    pauseEngine();
    if (!value) {
      resumeEngine();
    }
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    camera.viewfinder.anchor = Anchor.topLeft;
    _buildLevel();
    _player = PlayerComponent(
      inputState: inputState,
      onFellOff: () => _finishGame(GameEndReason.fellOff),
      worldHeight: level.worldHeight,
    );
    _player.position = Vector2(
      level.playerSpawn.x * level.tileSize.toDouble() + 2,
      level.playerSpawn.y * level.tileSize.toDouble(),
    );
    add(_player);
    add(KeyboardListenerComponent());
    logger.info(
      module: 'core.engine',
      event: 'game.level.load.completed',
      message: '关卡加载完成',
      extra: <String, Object?>{
        'level_id': level.levelId,
        'coin_count': _totalCoins,
      },
    );
  }

  void _buildLevel() {
    for (final LevelRectModel rect in level.platforms) {
      final PlatformComponent platform = PlatformComponent(
        position: Vector2(
          rect.x * level.tileSize.toDouble(),
          rect.y * level.tileSize.toDouble(),
        ),
        size: Vector2(
          rect.w * level.tileSize.toDouble(),
          rect.h * level.tileSize.toDouble(),
        ),
        color: rect.y >= level.heightTiles - 2
            ? const Color(0xFF66BB6A)
            : const Color(0xFF8D6E63),
      );
      add(platform);
    }
    for (final LevelPointModel coin in level.coins) {
      _totalCoins += 1;
      add(
        CoinComponent(
          position: Vector2(
            coin.x * level.tileSize.toDouble() + 6,
            coin.y * level.tileSize.toDouble() + 6,
          ),
          onCollected: _handleCoinCollected,
        ),
      );
    }
    add(
      GoalComponent(
        position: Vector2(
          level.goal.x * level.tileSize.toDouble(),
          level.goal.y * level.tileSize.toDouble(),
        ),
        onReached: () => _finishGame(GameEndReason.victory),
      ),
    );
  }

  void _handleCoinCollected() {
    _collectedCoins += 1;
    onCoinCollected(_collectedCoins);
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
    _updateCamera();
  }

  void _updateCamera() {
    final double targetX = (_player.position.x + _player.size.x / 2) - size.x / 2;
    final double maxX = level.worldWidth - size.x;
    final double clampedX = targetX.clamp(0, maxX > 0 ? maxX : 0);
    final double currentX = camera.viewfinder.position.x;
    final double nextX =
        currentX + (clampedX - currentX) * GameConstants.cameraLerp * (1 / 60);
    camera.viewfinder.position = Vector2(nextX, 0);
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
