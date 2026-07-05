/// 游戏物理与渲染常量。
class GameConstants {
  GameConstants._();

  static const double gravity = 980;
  static const double playerMoveSpeed = 180;
  static const double playerMoveAcceleration = 1600;
  static const double playerMoveFriction = 2200;
  static const double playerJumpSpeed = 450;
  static const double maxFallSpeed = 640;
  static const double groundSnapTolerance = 16;
  static const double groundFeetTolerance = 6;
  static const double cameraLerp = 8;
  static const double enemyPatrolSpeed = 60;
}
