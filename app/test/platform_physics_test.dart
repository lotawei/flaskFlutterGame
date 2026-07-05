import 'package:flutter_test/flutter_test.dart';
import 'package:meme_game/core/engine/platform_physics.dart';

void main() {
  group('PlatformPhysicsSolver', () {
    PlatformPhysicsSolver buildSolver({
      List<PlatformSurface>? platforms,
      double worldWidth = 800,
    }) {
      return PlatformPhysicsSolver(
        platforms: platforms ??
            <PlatformSurface>[
              const PlatformSurface(left: 0, top: 400, right: 320, bottom: 432),
              const PlatformSurface(left: 256, top: 368, right: 384, bottom: 400),
            ],
        worldWidth: worldWidth,
        worldHeight: 480,
        gravityDirection: 1,
      );
    }

    test('侧向贴台阶不会穿进砖块', () {
      final PlatformPhysicsSolver solver = buildSolver();
      final PlatformPhysicsResult result = solver.simulate(
        x: 250,
        y: 372,
        velocityX: 200,
        velocityY: 0,
        dt: 0.05,
        wasGrounded: true,
      );
      expect(result.x + 28 <= 256.1, isTrue);
    });

    test('走出平台边缘会坠落', () {
      final PlatformPhysicsSolver solver = buildSolver();
      final PlatformPhysicsResult result = solver.simulate(
        x: 292,
        y: 372,
        velocityX: 120,
        velocityY: 0,
        dt: 0.03,
        wasGrounded: true,
      );
      expect(result.isGrounded, isFalse);
    });

    test('从下方跳穿台阶不会顶头卡住', () {
      final PlatformPhysicsSolver solver = buildSolver();
      final PlatformPhysicsResult result = solver.simulate(
        x: 280,
        y: 410,
        velocityX: 0,
        velocityY: -300,
        dt: 0.016,
        wasGrounded: false,
      );
      expect(result.y < 410, isTrue);
    });

    test('落在台阶上需脚底完全在平台内', () {
      final PlatformPhysicsSolver solver = buildSolver();
      final PlatformPhysicsResult result = solver.simulate(
        x: 260,
        y: 320,
        velocityX: 0,
        velocityY: 400,
        dt: 0.08,
        wasGrounded: false,
      );
      if (result.isGrounded) {
        expect(result.x + 4 >= 256, isTrue);
        expect(result.x + 28 - 4 <= 384, isTrue);
      }
    });

    test('世界左边界不会穿出 x<0', () {
      final PlatformPhysicsSolver solver = buildSolver();
      final PlatformPhysicsResult result = solver.simulate(
        x: 2,
        y: 372,
        velocityX: -300,
        velocityY: 0,
        dt: 0.05,
        wasGrounded: true,
      );
      expect(result.x >= 0, isTrue);
    });

    test('平台边缘悬空不算着地', () {
      final PlatformPhysicsSolver solver = buildSolver();
      final PlatformPhysicsResult result = solver.simulate(
        x: 294,
        y: 372,
        velocityX: 0,
        velocityY: 0,
        dt: 0.016,
        wasGrounded: true,
      );
      expect(result.isGrounded, isFalse);
    });

    test('悬挑下方可继续向右走', () {
      final PlatformPhysicsSolver solver = buildSolver();
      final PlatformPhysicsResult result = solver.simulate(
        x: 280,
        y: 372,
        velocityX: 160,
        velocityY: 0,
        dt: 0.04,
        wasGrounded: true,
      );
      expect(result.x, greaterThan(280));
      expect(result.x + 28 <= 256.1, isFalse);
    });
  });
}
