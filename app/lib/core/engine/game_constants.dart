/// 游戏物理与渲染常量。
class GameConstants {
  GameConstants._();

  static const double gravity = 980;
  static const double playerMoveSpeed = 168;
  static const double playerAirMoveSpeed = 140;
  static const double playerMoveAcceleration = 1200;
  static const double playerMoveFriction = 3200;
  static const double playerJumpSpeed = 450;
  static const double maxFallSpeed = 640;
  static const double groundSnapTolerance = 12;
  static const double groundFeetTolerance = 6;
  static const double sideCollisionBias = 2;
  static const double minPlatformSupportOverlap = 28;
  static const double movementSubStep = 8;
  static const double cameraLerp = 8;
  static const double enemyPatrolSpeed = 60;
  /// 穿越重力分界线时竖直动量保持系数（ibb & obb 风格）。
  static const double gravityMomentumRetention = 0.95;
  /// 分界线附近过渡带高度（世界像素）。
  static const double gravityTransitionBand = 24;
}
