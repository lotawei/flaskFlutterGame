import 'package:flutter_test/flutter_test.dart';
import 'package:meme_game/core/engine/game_constants.dart';
import 'package:meme_game/core/engine/platform_physics.dart';
import 'package:meme_game/core/level/level_gravity_zone_model.dart';

void main() {
  group('重力反转 ibb & obb 风格', () {
    test('穿越分界线动量翻转 vy2 = -vy1 * k', () {
      const double vyBefore = -420;
      final double vyAfter =
          -vyBefore * GameConstants.gravityMomentumRetention;
      expect(vyAfter, closeTo(399, 1));
    });

    test('上区向下重力 下区向上重力分区解析', () {
      final LevelGravityZoneModel upperZone = LevelGravityZoneModel(
        x: 0,
        y: 0,
        w: 62,
        h: 7,
        gravityDirection: 1,
      );
      final LevelGravityZoneModel lowerZone = LevelGravityZoneModel(
        x: 0,
        y: 7,
        w: 62,
        h: 8,
        gravityDirection: -1,
      );
      expect(
        upperZone.containsWorldPoint(worldX: 100, worldY: 100, tileSize: 32),
        isTrue,
      );
      expect(
        lowerZone.containsWorldPoint(worldX: 100, worldY: 300, tileSize: 32),
        isTrue,
      );
      expect(upperZone.gravityDirection, 1);
      expect(lowerZone.gravityDirection, -1);
    });

    test('重力向上时站在天花板底面', () {
      final PlatformPhysicsSolver solver = PlatformPhysicsSolver(
        platforms: <PlatformSurface>[
          const PlatformSurface(
            left: 64,
            top: 384,
            right: 576,
            bottom: 416,
            isOneWay: false,
          ),
        ],
        worldWidth: 1984,
        worldHeight: 480,
        gravityDirection: -1,
      );
      final PlatformPhysicsResult result = solver.snapToValid(
        x: 100,
        y: 400,
      );
      expect(result.y, closeTo(416, 1));
      expect(result.isGrounded, isTrue);
    });

    test('重力向上跳跃应获得与重力相反的初速度', () {
      const int gravityDirection = -1;
      const double jumpSpeed = GameConstants.playerJumpSpeed;
      final double velocityY = -gravityDirection * jumpSpeed;
      expect(velocityY, greaterThan(0));
    });

    test('重力向下跳跃初速度为负', () {
      const int gravityDirection = 1;
      const double jumpSpeed = GameConstants.playerJumpSpeed;
      final double velocityY = -gravityDirection * jumpSpeed;
      expect(velocityY, lessThan(0));
    });
  });
}
