import 'package:get/get.dart';
import 'package:meme_game/core/observability/app_logger.dart';
import 'package:meme_game/core/observability/trace_context.dart';
import 'package:meme_game/data/models/auth_model.dart';
import 'package:meme_game/data/repositories/auth_repository.dart';
import 'package:meme_game/data/repositories/progress_repository.dart';

/// 全局登录态控制器。
class AuthController extends GetxController {
  AuthController({
    required AuthRepository authRepository,
    required ProgressRepository progressRepository,
    required AppLogger logger,
  })  : _authRepository = authRepository,
        _progressRepository = progressRepository,
        _logger = logger;

  final AuthRepository _authRepository;
  final ProgressRepository _progressRepository;
  final AppLogger _logger;

  final RxBool isLoggedIn = false.obs;
  final RxBool isRestoring = true.obs;
  final Rxn<UserProfileModel> user = Rxn<UserProfileModel>();
  final Rxn<UserSummaryModel> userSummary = Rxn<UserSummaryModel>();
  final RxMap<String, LevelProgressModel> levelProgress =
      <String, LevelProgressModel>{}.obs;

  @override
  void onInit() {
    super.onInit();
    restoreSession();
  }

  Future<void> restoreSession() async {
    isRestoring.value = true;
    final TraceContext traceContext = TraceContext.create();
    try {
      final UserProfileModel? profile = await _authRepository.restoreSession(
        traceContext: traceContext,
      );
      if (profile != null) {
        user.value = profile;
        isLoggedIn.value = true;
        await refreshProgress(traceContext: traceContext);
      }
    } finally {
      isRestoring.value = false;
    }
  }

  Future<void> applyManifestUser(UserSummaryModel? summary) async {
    userSummary.value = summary;
    if (summary != null && user.value == null) {
      user.value = UserProfileModel(
        userId: summary.userId,
        username: summary.username,
        displayName: summary.displayName,
        createdAt: '',
      );
      isLoggedIn.value = true;
    }
  }

  Future<void> refreshProgress({TraceContext? traceContext}) async {
    if (!isLoggedIn.value) {
      return;
    }
    final TraceContext context = traceContext ?? TraceContext.create();
    try {
      final UserProgressModel progress = await _progressRepository.fetchProgress(
        traceContext: context,
      );
      levelProgress.assignAll(progress.levels);
      userSummary.value = UserSummaryModel(
        userId: progress.userId,
        username: user.value?.username ?? '',
        displayName: user.value?.displayName ?? '',
        totalStars: progress.totalStars,
        clearedLevels: progress.clearedLevels,
        playedLevels: progress.playedLevels,
      );
    } catch (err) {
      _logger.warn(
        module: 'features.auth',
        event: 'auth.progress.refresh.failed',
        message: '进度刷新失败',
        extra: <String, Object?>{'error_message': err.toString()},
      );
    }
  }

  Future<void> logout() async {
    await _authRepository.logout();
    isLoggedIn.value = false;
    user.value = null;
    userSummary.value = null;
    levelProgress.clear();
  }

  int readLevelStars(String levelId) {
    return levelProgress[levelId]?.bestStars ?? 0;
  }
}
