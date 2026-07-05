import 'dart:math' as math;

import 'package:meme_game/core/engine/game_constants.dart';

/// 平台 AABB（世界坐标）。
class PlatformSurface {
  const PlatformSurface({
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
  });

  final double left;
  final double top;
  final double right;
  final double bottom;

  double get width => right - left;
  double get height => bottom - top;
}

/// 单帧物理解算结果。
class PlatformPhysicsResult {
  const PlatformPhysicsResult({
    required this.x,
    required this.y,
    required this.velocityX,
    required this.velocityY,
    required this.isGrounded,
    required this.justLanded,
  });

  final double x;
  final double y;
  final double velocityX;
  final double velocityY;
  final bool isGrounded;
  final bool justLanded;
}

/// 横版平台物理：分轴移动 → MTV 出穿透 → 脚底探针定着地。
class PlatformPhysicsSolver {
  PlatformPhysicsSolver({
    required this.platforms,
    required this.worldWidth,
    required this.worldHeight,
    required this.gravityDirection,
    this.playerWidth = 28,
    this.playerHeight = 28,
  });

  final List<PlatformSurface> platforms;
  final double worldWidth;
  final double worldHeight;
  final int gravityDirection;
  final double playerWidth;
  final double playerHeight;

  static const int _maxDepenetrationPasses = 8;
  static const double _sideWallMargin = 6;

  PlatformPhysicsResult simulate({
    required double x,
    required double y,
    required double velocityX,
    required double velocityY,
    required double dt,
    required bool wasGrounded,
  }) {
    double px = x;
    double py = y;
    double vx = velocityX;
    double vy = velocityY;
    _sweepAxis(
      isHorizontal: true,
      px: () => px,
      py: () => py,
      setPx: (double v) => px = v,
      setPy: (double v) => py = v,
      velocity: vx,
      dt: dt,
      setVelocity: (double v) => vx = v,
      wasRising: false,
    );
    px = _clampWorldX(px);
    final bool wasRising = gravityDirection > 0 ? vy < 0 : vy > 0;
    _sweepAxis(
      isHorizontal: false,
      px: () => px,
      py: () => py,
      setPx: (double v) => px = v,
      setPy: (double v) => py = v,
      velocity: vy,
      dt: dt,
      setVelocity: (double v) => vy = v,
      wasRising: wasRising,
    );
    for (int pass = 0; pass < _maxDepenetrationPasses; pass++) {
      if (!_depenetrate(
        px: () => px,
        py: () => py,
        setPx: (double v) => px = v,
        setPy: (double v) => py = v,
        wasRising: wasRising,
      )) {
        break;
      }
    }
    px = _clampWorldX(px);
    final bool isGrounded = _probeGrounded(px, py);
    final bool justLanded = isGrounded && !wasGrounded;
    return PlatformPhysicsResult(
      x: px,
      y: py,
      velocityX: vx,
      velocityY: isGrounded && _isMovingIntoGround(vy) ? 0 : vy,
      isGrounded: isGrounded,
      justLanded: justLanded,
    );
  }

  /// 出生/穿模后吸附到合法位置。
  PlatformPhysicsResult snapToValid({
    required double x,
    required double y,
  }) {
    double px = _clampWorldX(x);
    double py = y;
    for (int pass = 0; pass < _maxDepenetrationPasses * 2; pass++) {
      if (!_depenetrate(
        px: () => px,
        py: () => py,
        setPx: (double v) => px = v,
        setPy: (double v) => py = v,
        wasRising: false,
      )) {
        break;
      }
    }
    px = _clampWorldX(px);
    final bool isGrounded = _probeGrounded(px, py);
    if (isGrounded) {
      final PlatformSurface? support = gravityDirection > 0
          ? _findSupportPlatform(px, py)
          : _findCeilingSupportPlatform(px, py);
      if (support != null) {
        px = _clampXOnPlatform(px, support);
        if (gravityDirection > 0) {
          py = support.top - playerHeight;
        } else {
          py = support.bottom;
        }
      }
    }
    return PlatformPhysicsResult(
      x: px,
      y: py,
      velocityX: 0,
      velocityY: 0,
      isGrounded: isGrounded,
      justLanded: false,
    );
  }

  void _sweepAxis({
    required bool isHorizontal,
    required double Function() px,
    required double Function() py,
    required void Function(double) setPx,
    required void Function(double) setPy,
    required double velocity,
    required double dt,
    required void Function(double) setVelocity,
    required bool wasRising,
  }) {
    if (velocity.abs() < 0.001 || dt <= 0) {
      return;
    }
    final double delta = velocity * dt;
    final double stepSign = delta.sign;
    double remaining = delta.abs();
    while (remaining > 0) {
      final double step = math.min(remaining, GameConstants.movementSubStep);
      if (isHorizontal) {
        setPx(px() + step * stepSign);
      } else {
        setPy(py() + step * stepSign);
      }
      final double before = isHorizontal ? px() : py();
      _resolveContactsAlongAxis(
        isHorizontal: isHorizontal,
        px: px,
        py: py,
        setPx: setPx,
        setPy: setPy,
        wasRising: wasRising,
      );
      final double after = isHorizontal ? px() : py();
      if ((after - before).abs() < 0.01 && step > 0.01) {
        setVelocity(0);
        break;
      }
      remaining -= step;
    }
  }

  void _resolveContactsAlongAxis({
    required bool isHorizontal,
    required double Function() px,
    required double Function() py,
    required void Function(double) setPx,
    required void Function(double) setPy,
    required bool wasRising,
  }) {
    for (int pass = 0; pass < 4; pass++) {
      var moved = false;
      for (final PlatformSurface platform in platforms) {
        if (_resolveOnePlatformAlongAxis(
          platform: platform,
          isHorizontal: isHorizontal,
          px: px,
          py: py,
          setPx: setPx,
          setPy: setPy,
          wasRising: wasRising,
        )) {
          moved = true;
        }
      }
      if (!moved) {
        break;
      }
    }
  }

  bool _resolveOnePlatformAlongAxis({
    required PlatformSurface platform,
    required bool isHorizontal,
    required double Function() px,
    required double Function() py,
    required void Function(double) setPx,
    required void Function(double) setPy,
    required bool wasRising,
  }) {
    final _OverlapInfo? overlap = _computeOverlap(px(), py(), platform);
    if (overlap == null) {
      return false;
    }
    if (isHorizontal) {
      return _resolveHorizontal(platform, overlap, px, py, setPx);
    }
    return _resolveVertical(
      platform,
      overlap,
      px,
      py,
      setPx,
      setPy,
      wasRising,
    );
  }

  bool _resolveHorizontal(
    PlatformSurface platform,
    _OverlapInfo overlap,
    double Function() px,
    double Function() py,
    void Function(double) setPx,
  ) {
    if (gravityDirection > 0 &&
        overlap.overlapTop <= GameConstants.groundSnapTolerance &&
        py() + playerHeight <= platform.top + GameConstants.groundSnapTolerance) {
      return false;
    }
    if (!_shouldBlockHorizontal(platform, overlap, px(), py())) {
      return false;
    }
    if (overlap.penetrationXLeft < overlap.penetrationXRight) {
      setPx(platform.left - playerWidth);
    } else {
      setPx(platform.right);
    }
    return true;
  }

  bool _shouldBlockHorizontal(
    PlatformSurface platform,
    _OverlapInfo overlap,
    double playerX,
    double playerY,
  ) {
    final double playerTop = playerY;
    final double playerBottom = playerY + playerHeight;
    final double bodyLeft = playerX;
    final double bodyRight = playerX + playerWidth;
    if (playerBottom <= platform.top + GameConstants.groundSnapTolerance) {
      return false;
    }
    if (playerBottom >= platform.bottom - _sideWallMargin &&
        playerTop < platform.bottom) {
      if (bodyLeft < platform.left + _sideWallMargin) {
        return true;
      }
      if (bodyRight > platform.right - _sideWallMargin) {
        return true;
      }
      return false;
    }
    if (gravityDirection > 0 &&
        overlap.overlapTop <= GameConstants.groundSnapTolerance &&
        playerBottom <= platform.top + GameConstants.groundSnapTolerance + 4) {
      return false;
    }
    if (gravityDirection < 0 &&
        overlap.overlapBottom <= GameConstants.groundSnapTolerance &&
        playerTop >= platform.bottom - GameConstants.groundSnapTolerance - 4) {
      return false;
    }
    if (gravityDirection > 0 && playerBottom > platform.top + _sideWallMargin) {
      if (playerTop >= platform.bottom - _sideWallMargin) {
        return false;
      }
      return true;
    }
    if (gravityDirection < 0 && playerTop < platform.bottom - _sideWallMargin) {
      if (playerBottom <= platform.top + _sideWallMargin) {
        return false;
      }
      return true;
    }
    return overlap.penetrationX <
        overlap.penetrationY + GameConstants.sideCollisionBias;
  }

  bool _resolveVertical(
    PlatformSurface platform,
    _OverlapInfo overlap,
    double Function() px,
    double Function() py,
    void Function(double) setPx,
    void Function(double) setPy,
    bool wasRising,
  ) {
    if (gravityDirection > 0) {
      if (wasRising && _shouldPassThroughFromBelow(py(), platform)) {
        return false;
      }
      if (wasRising &&
          overlap.overlapTop <= GameConstants.groundSnapTolerance &&
          py() + playerHeight <= platform.top + GameConstants.groundSnapTolerance) {
        return false;
      }
      if (_canLandOnTop(px(), py(), platform, overlap)) {
        setPy(platform.top - playerHeight);
        return true;
      }
      if (wasRising && overlap.penetrationYBottom < overlap.penetrationYTop) {
        return false;
      }
      return false;
    }
    if (!wasRising && _shouldPassThroughFromAbove(py(), platform)) {
      return false;
    }
    if (!wasRising &&
        overlap.overlapBottom <= GameConstants.groundSnapTolerance &&
        py() >= platform.bottom - GameConstants.groundSnapTolerance) {
      return false;
    }
    if (_canLandOnBottom(px(), py(), platform, overlap)) {
      setPy(platform.bottom);
      return true;
    }
    if (!wasRising && overlap.penetrationYTop < overlap.penetrationYBottom) {
      return false;
    }
    return false;
  }

  bool _shouldPassThroughFromBelow(double playerY, PlatformSurface platform) {
    return playerY + playerHeight > platform.top + 1 &&
        playerY < platform.bottom - 1;
  }

  bool _shouldPassThroughFromAbove(double playerY, PlatformSurface platform) {
    return playerY < platform.bottom - 1 &&
        playerY + playerHeight > platform.top + 1;
  }

  bool _canLandOnTop(
    double px,
    double py,
    PlatformSurface platform,
    _OverlapInfo overlap,
  ) {
    if (overlap.overlapTop <= 0 ||
        overlap.overlapTop > GameConstants.groundSnapTolerance + 4) {
      return false;
    }
    return _feetSupportedOnPlatform(px, py, platform);
  }

  bool _canLandOnBottom(
    double px,
    double py,
    PlatformSurface platform,
    _OverlapInfo overlap,
  ) {
    if (overlap.overlapBottom <= 0 ||
        overlap.overlapBottom > GameConstants.groundSnapTolerance + 4) {
      return false;
    }
    return _headSupportedOnPlatform(px, py, platform);
  }

  bool _depenetrate({
    required double Function() px,
    required double Function() py,
    required void Function(double) setPx,
    required void Function(double) setPy,
    required bool wasRising,
  }) {
    _OverlapInfo? smallest;
    PlatformSurface? hitPlatform;
    for (final PlatformSurface platform in platforms) {
      final _OverlapInfo? overlap = _computeOverlap(px(), py(), platform);
      if (overlap == null) {
        continue;
      }
      if (gravityDirection > 0 &&
          wasRising &&
          _shouldPassThroughFromBelow(py(), platform)) {
        continue;
      }
      if (gravityDirection < 0 &&
          !wasRising &&
          _shouldPassThroughFromAbove(py(), platform)) {
        continue;
      }
      if (smallest == null || overlap.penetration < smallest.penetration) {
        smallest = overlap;
        hitPlatform = platform;
      }
    }
    if (smallest == null || hitPlatform == null) {
      return false;
    }
    final PlatformSurface platform = hitPlatform;
    final _OverlapInfo overlap = smallest;
    if (overlap.penetrationX < overlap.penetrationY) {
      if (overlap.penetrationXLeft < overlap.penetrationXRight) {
        setPx(platform.left - playerWidth);
      } else {
        setPx(platform.right);
      }
      return true;
    }
    if (gravityDirection > 0) {
      if (_canLandOnTop(px(), py(), platform, overlap)) {
        setPy(platform.top - playerHeight);
        setPx(_clampXOnPlatform(px(), platform));
        return true;
      }
      if (wasRising) {
        return false;
      }
      if (overlap.penetrationYBottom < overlap.penetrationYTop) {
        setPy(platform.bottom);
        return true;
      }
      setPy(platform.top - playerHeight);
      return true;
    }
    if (_canLandOnBottom(px(), py(), platform, overlap)) {
      setPy(platform.bottom);
      setPx(_clampXOnPlatform(px(), platform));
      return true;
    }
    if (overlap.penetrationYTop < overlap.penetrationYBottom) {
      setPy(platform.top - playerHeight);
      return true;
    }
    setPy(platform.bottom);
    return true;
  }

  bool _probeGrounded(double px, double py) {
    if (gravityDirection > 0) {
      return _findSupportPlatform(px, py) != null;
    }
    return _findCeilingSupportPlatform(px, py) != null;
  }

  PlatformSurface? _findSupportPlatform(double px, double py) {
    final double feetY = py + playerHeight;
    PlatformSurface? best;
    double bestWidth = 0;
    for (final PlatformSurface platform in platforms) {
      if ((feetY - platform.top).abs() > GameConstants.groundSnapTolerance + 2) {
        continue;
      }
      if (!_feetSupportedOnPlatform(px, py, platform)) {
        continue;
      }
      final double width = platform.width;
      if (width > bestWidth) {
        bestWidth = width;
        best = platform;
      }
    }
    return best;
  }

  PlatformSurface? _findCeilingSupportPlatform(double px, double py) {
    PlatformSurface? best;
    double bestWidth = 0;
    for (final PlatformSurface platform in platforms) {
      if ((platform.bottom - py).abs() > GameConstants.groundSnapTolerance + 2) {
        continue;
      }
      if (!_headSupportedOnPlatform(px, py, platform)) {
        continue;
      }
      final double width = platform.width;
      if (width > bestWidth) {
        bestWidth = width;
        best = platform;
      }
    }
    return best;
  }

  bool _feetSupportedOnPlatform(double px, double py, PlatformSurface platform) {
    final double bodyLeft = px;
    final double bodyRight = px + playerWidth;
    final double supportLeft = math.max(bodyLeft, platform.left);
    final double supportRight = math.min(bodyRight, platform.right);
    final double supportWidth = supportRight - supportLeft;
    if (supportWidth < GameConstants.minPlatformSupportOverlap) {
      return false;
    }
    final double feetY = py + playerHeight;
    return (feetY - platform.top).abs() <= GameConstants.groundSnapTolerance + 2;
  }

  bool _headSupportedOnPlatform(double px, double py, PlatformSurface platform) {
    final double bodyLeft = px;
    final double bodyRight = px + playerWidth;
    final double supportLeft = math.max(bodyLeft, platform.left);
    final double supportRight = math.min(bodyRight, platform.right);
    final double supportWidth = supportRight - supportLeft;
    if (supportWidth < GameConstants.minPlatformSupportOverlap) {
      return false;
    }
    return (platform.bottom - py).abs() <= GameConstants.groundSnapTolerance + 2;
  }

  double _clampXOnPlatform(double px, PlatformSurface platform) {
    final double minX = platform.left;
    final double maxX = platform.right - playerWidth;
    if (px < minX) {
      return minX;
    }
    if (px > maxX) {
      return maxX;
    }
    return px;
  }

  double _clampWorldX(double px) {
    final double minX = 0;
    final double maxX = worldWidth - playerWidth;
    if (px < minX) {
      return minX;
    }
    if (px > maxX) {
      return maxX;
    }
    return px;
  }

  bool _isMovingIntoGround(double vy) {
    if (gravityDirection > 0) {
      return vy > 0;
    }
    return vy < 0;
  }

  _OverlapInfo? _computeOverlap(
    double px,
    double py,
    PlatformSurface platform,
  ) {
    final double playerRight = px + playerWidth;
    final double playerBottom = py + playerHeight;
    if (playerRight <= platform.left ||
        px >= platform.right ||
        playerBottom <= platform.top ||
        py >= platform.bottom) {
      return null;
    }
    final double penetrationXLeft = playerRight - platform.left;
    final double penetrationXRight = platform.right - px;
    final double penetrationYTop = playerBottom - platform.top;
    final double penetrationYBottom = platform.bottom - py;
    final double penetrationX = math.min(penetrationXLeft, penetrationXRight);
    final double penetrationY = math.min(penetrationYTop, penetrationYBottom);
    return _OverlapInfo(
      penetrationXLeft: penetrationXLeft,
      penetrationXRight: penetrationXRight,
      penetrationYTop: penetrationYTop,
      penetrationYBottom: penetrationYBottom,
      penetrationX: penetrationX,
      penetrationY: penetrationY,
      penetration: math.min(penetrationX, penetrationY),
      overlapTop: penetrationYTop,
      overlapBottom: penetrationYBottom,
    );
  }
}

class _OverlapInfo {
  const _OverlapInfo({
    required this.penetrationXLeft,
    required this.penetrationXRight,
    required this.penetrationYTop,
    required this.penetrationYBottom,
    required this.penetrationX,
    required this.penetrationY,
    required this.penetration,
    required this.overlapTop,
    required this.overlapBottom,
  });

  final double penetrationXLeft;
  final double penetrationXRight;
  final double penetrationYTop;
  final double penetrationYBottom;
  final double penetrationX;
  final double penetrationY;
  final double penetration;
  final double overlapTop;
  final double overlapBottom;
}
