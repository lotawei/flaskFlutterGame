import 'package:get/get.dart';
import 'package:meme_game/core/engine/input/game_input_state.dart';
import 'package:meme_game/core/engine/meme_platformer_game.dart';
import 'package:meme_game/core/engine/sprites/sprite_registry.dart';
import 'package:meme_game/core/level/level_model.dart';
import 'package:meme_game/core/observability/app_logger.dart';
import 'package:meme_game/core/observability/trace_context.dart';
import 'package:meme_game/core/level/level_rule_evaluator.dart';
import 'package:meme_game/core/level/level_rule_model.dart';
import 'package:meme_game/data/repositories/level_repository.dart';
import 'package:meme_game/data/repositories/progress_repository.dart';
import 'package:meme_game/features/auth/auth_controller.dart';

/// 闯关页控制器。
class GameplayController extends GetxController {
  GameplayController({
    required LevelRepository levelRepository,
    required ProgressRepository progressRepository,
    required AuthController authController,
    required AppLogger logger,
  })  : _levelRepository = levelRepository,
        _progressRepository = progressRepository,
        _authController = authController,
        _logger = logger;

  final LevelRepository _levelRepository;
  final ProgressRepository _progressRepository;
  final AuthController _authController;
  final AppLogger _logger;
  final LevelRuleEvaluator _ruleEvaluator = LevelRuleEvaluator();

  final GameInputState inputState = GameInputState();
  final RxBool isLoading = true.obs;
  final RxBool hasError = false.obs;
  final RxString errorMessage = ''.obs;
  final RxInt collectedCoins = 0.obs;
  final RxInt totalCoins = 0.obs;
  final RxDouble elapsedSeconds = 0.0.obs;
  final RxnDouble remainingSeconds = RxnDouble();
  final RxBool isTimeWarning = false.obs;
  final RxBool isPaused = false.obs;
  final RxString tipText = ''.obs;

  LevelModel? level;
  MemePlatformerGame? game;
  late TraceContext traceContext;
  String levelId = 'demo_haqi';
  final SpriteRegistry spriteRegistry = SpriteRegistry();

  @override
  void onInit() {
    super.onInit();
    levelId = Get.parameters['levelId'] ?? 'demo_haqi';
    traceContext = TraceContext.create();
    loadLevel();
  }

  Future<void> loadLevel() async {
    isLoading.value = true;
    hasError.value = false;
    errorMessage.value = '';
    _logger.info(
      module: 'features.gameplay',
      event: 'game.session.started',
      message: '开始加载闯关',
      traceContext: traceContext,
      extra: <String, Object?>{'level_id': levelId},
    );
    try {
      final LevelModel loadedLevel = await _levelRepository.loadLevel(
        levelId: levelId,
        traceContext: traceContext,
      );
      level = loadedLevel;
      tipText.value = loadedLevel.tipText;
      totalCoins.value = loadedLevel.coins.length;
      game = MemePlatformerGame(
        level: loadedLevel,
        inputState: inputState,
        logger: _logger,
        spriteRegistry: spriteRegistry,
        onCoinCollected: (int coins) {
          collectedCoins.value = coins;
        },
        onTimerTick: (double remaining) {
          remainingSeconds.value = remaining;
          isTimeWarning.value = game?.isTimeWarning ?? false;
        },
        onGameEnded: _handleGameEnded,
      );
      remainingSeconds.value = game!.remainingSeconds;
    } catch (err) {
      hasError.value = true;
      errorMessage.value = err.toString();
      _logger.error(
        module: 'features.gameplay',
        event: 'game.level.load.failed',
        message: '关卡加载失败',
        traceContext: traceContext,
        extra: <String, Object?>{'error_message': err.toString()},
      );
    } finally {
      isLoading.value = false;
    }
  }

  void togglePause() {
    if (game == null) {
      return;
    }
    isPaused.value = !isPaused.value;
    game!.setPaused(isPaused.value);
  }

  void setMoveLeft(bool value) {
    inputState.moveLeft = value;
  }

  void setMoveRight(bool value) {
    inputState.moveRight = value;
  }

  void setJumpHeld(bool value) {
    inputState.jumpHeld = value;
  }

  void _handleGameEnded(
    GameEndReason reason,
    int coins,
    double seconds,
  ) async {
    final LevelModel? currentLevel = level;
    final bool isVictory = reason == GameEndReason.victory;
    int stars = 0;
    int defeatedEnemies = game?.defeatedEnemies ?? 0;
    if (currentLevel != null && isVictory) {
      final StarRatingResult rating = _ruleEvaluator.evaluateStars(
        starRules: currentLevel.starRules,
        context: LevelRunContext(
          elapsedSeconds: seconds,
          collectedCoins: coins,
          totalCoins: currentLevel.coins.length,
          defeatedEnemies: defeatedEnemies,
          totalEnemies: currentLevel.enemies.length,
          damageTaken: reason == GameEndReason.hitByEnemy ? 1 : 0,
          hasReachedGoal: true,
          isRealGoal: true,
        ),
      );
      stars = rating.stars;
    }
    String? syncMessage;
    int? syncedTotalStars;
    if (_authController.isLoggedIn.value) {
      try {
        final result = await _progressRepository.submitSession(
          traceContext: traceContext,
          levelId: levelId,
          reason: reason.name,
          coins: coins,
          totalCoins: totalCoins.value,
          seconds: seconds,
          stars: stars,
          defeatedEnemies: defeatedEnemies,
        );
        syncedTotalStars = result.totalStars;
        syncMessage = '进度已同步 · 本关 ${result.levelProgress.bestStars} 星';
        await _authController.refreshProgress(traceContext: traceContext);
      } catch (err) {
        syncMessage = '进度同步失败（可稍后重试）';
        _logger.warn(
          module: 'features.gameplay',
          event: 'game.session.sync.failed',
          message: '对局上报失败',
          traceContext: traceContext,
          extra: <String, Object?>{'error_message': err.toString()},
        );
      }
    }
    Get.offNamed(
      '/result',
      arguments: <String, Object?>{
        'reason': reason.name,
        'levelId': levelId,
        'levelName': level?.name ?? levelId,
        'coins': coins,
        'totalCoins': totalCoins.value,
        'seconds': seconds,
        'stars': stars,
        'traceId': traceContext.traceId,
        'syncMessage': syncMessage,
        'syncedTotalStars': syncedTotalStars,
        'isLoggedIn': _authController.isLoggedIn.value,
      },
    );
  }

  @override
  void onClose() {
    inputState.reset();
    super.onClose();
  }
}
