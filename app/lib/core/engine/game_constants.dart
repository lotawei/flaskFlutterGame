/// 游戏物理与渲染常量。
class GameConstants {
  GameConstants._();

  static const double gravity = 980;
  static const double playerMoveSpeed = 180;
  static const double playerJumpSpeed = 420;
  static const double maxFallSpeed = 640;
  static const double cameraLerp = 8;
  static const int targetFps = 60;
}
