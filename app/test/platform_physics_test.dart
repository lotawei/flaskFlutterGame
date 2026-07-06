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
              const PlatformSurface(
                left: 0,
                top: 400,
                right: 320,
                bottom: 432,
                isOneWay: false,
              ),
              const PlatformSurface(
                left: 256,
                top: 368,
                right: 384,
                bottom: 400,
                isOneWay: true,
              ),
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
      final PlatformPhysicsSolver solver = PlatformPhysicsSolver(
        platforms: <PlatformSurface>[
          const PlatformSurface(
            left: 0,
            top: 400,
            right: 320,
            bottom: 432,
            isOneWay: true,
          ),
          const PlatformSurface(
            left: 256,
            top: 368,
            right: 384,
            bottom: 400,
            isOneWay: true,
          ),
        ],
        worldWidth: 800,
        worldHeight: 480,
        gravityDirection: 1,
      );
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

    test('单帧起跳后应保留上升速度', () {
      final PlatformPhysicsSolver solver = PlatformPhysicsSolver(
        platforms: <PlatformSurface>[
          const PlatformSurface(
            left: 0,
            top: 400,
            right: 800,
            bottom: 432,
            isOneWay: false,
          ),
        ],
        worldWidth: 800,
        worldHeight: 480,
        gravityDirection: 1,
      );
      final PlatformPhysicsResult result = solver.simulate(
        x: 100,
        y: 372,
        velocityX: 0,
        velocityY: -450,
        dt: 1 / 60,
        wasGrounded: false,
      );
      expect(result.velocityY, lessThan(-400));
      expect(result.y, lessThan(372));
    });

    test('地面起跳应达到正常高度', () {
      final PlatformPhysicsSolver solver = PlatformPhysicsSolver(
        platforms: <PlatformSurface>[
          const PlatformSurface(
            left: 0,
            top: 400,
            right: 800,
            bottom: 432,
            isOneWay: false,
          ),
          const PlatformSurface(
            left: 256,
            top: 368,
            right: 384,
            bottom: 400,
            isOneWay: true,
          ),
        ],
        worldWidth: 800,
        worldHeight: 480,
        gravityDirection: 1,
      );
      double x = 280;
      double y = 372;
      double vy = 0;
      bool grounded = true;
      double minY = y;
      const double dt = 1 / 60;
      for (int frame = 0; frame < 90; frame++) {
        if (grounded && frame == 0) {
          vy = -450;
          grounded = false;
        }
        vy += 980 * dt;
        if (vy > 640) {
          vy = 640;
        }
        final PlatformPhysicsResult result = solver.simulate(
          x: x,
          y: y,
          velocityX: 0,
          velocityY: vy,
          dt: dt,
          wasGrounded: grounded,
        );
        x = result.x;
        y = result.y;
        vy = result.velocityY;
        grounded = result.isGrounded;
        if (y < minY) {
          minY = y;
        }
      }
      final double apexHeight = 372 - minY;
      expect(apexHeight, greaterThan(80));
    });

    test('开阔地面起跳应达到正常高度', () {
      final PlatformPhysicsSolver solver = PlatformPhysicsSolver(
        platforms: <PlatformSurface>[
          const PlatformSurface(
            left: 0,
            top: 400,
            right: 800,
            bottom: 432,
            isOneWay: false,
          ),
        ],
        worldWidth: 800,
        worldHeight: 480,
        gravityDirection: 1,
      );
      double y = 372;
      double vy = 0;
      bool grounded = true;
      double minY = y;
      const double dt = 1 / 60;
      for (int frame = 0; frame < 90; frame++) {
        if (grounded && frame == 0) {
          vy = -450;
          grounded = false;
        }
        vy += 980 * dt;
        if (vy > 640) {
          vy = 640;
        }
        final PlatformPhysicsResult result = solver.simulate(
          x: 100,
          y: y,
          velocityX: 0,
          velocityY: vy,
          dt: dt,
          wasGrounded: grounded,
        );
        y = result.y;
        vy = result.velocityY;
        grounded = result.isGrounded;
        if (y < minY) {
          minY = y;
        }
      }
      final double apexHeight = 372 - minY;
      expect(apexHeight, greaterThan(80));
    });

    test('顶实心绿色砖块应弹回不能穿上去', () {
      final PlatformPhysicsSolver solver = PlatformPhysicsSolver(
        platforms: <PlatformSurface>[
          const PlatformSurface(
            left: 200,
            top: 368,
            right: 232,
            bottom: 400,
            isOneWay: false,
          ),
        ],
        worldWidth: 800,
        worldHeight: 480,
        gravityDirection: 1,
      );
      final PlatformPhysicsResult result = solver.simulate(
        x: 202,
        y: 410,
        velocityX: 0,
        velocityY: -350,
        dt: 0.016,
        wasGrounded: false,
      );
      expect(result.y, greaterThanOrEqualTo(400));
      expect(result.y, lessThan(410));
    });

    test('脚底悬空在砖面上方不算着地', () {
      final PlatformPhysicsSolver solver = PlatformPhysicsSolver(
        platforms: <PlatformSurface>[
          const PlatformSurface(
            left: 0,
            top: 400,
            right: 320,
            bottom: 432,
            isOneWay: false,
          ),
        ],
        worldWidth: 800,
        worldHeight: 480,
        gravityDirection: 1,
      );
      final PlatformPhysicsResult result = solver.simulate(
        x: 100,
        y: 360,
        velocityX: 0,
        velocityY: 0,
        dt: 0.016,
        wasGrounded: false,
      );
      expect(result.isGrounded, isFalse);
    });

    test('高速下落穿进实心墙必须被推到顶面', () {
      final PlatformPhysicsSolver solver = PlatformPhysicsSolver(
        platforms: <PlatformSurface>[
          const PlatformSurface(
            left: 0,
            top: 400,
            right: 320,
            bottom: 464,
            isOneWay: false,
          ),
        ],
        worldWidth: 800,
        worldHeight: 480,
        gravityDirection: 1,
      );
      final PlatformPhysicsResult result = solver.simulate(
        x: 100,
        y: 430,
        velocityX: 0,
        velocityY: 640,
        dt: 0.05,
        wasGrounded: false,
      );
      expect(result.y + 28, lessThanOrEqualTo(400.5));
      expect(result.y, greaterThanOrEqualTo(372));
    });

    test('静止卡在实心墙内必须被推出', () {
      final PlatformPhysicsSolver solver = PlatformPhysicsSolver(
        platforms: <PlatformSurface>[
          const PlatformSurface(
            left: 0,
            top: 400,
            right: 320,
            bottom: 464,
            isOneWay: false,
          ),
        ],
        worldWidth: 800,
        worldHeight: 480,
        gravityDirection: 1,
      );
      final PlatformPhysicsResult result = solver.simulate(
        x: 100,
        y: 440,
        velocityX: 0,
        velocityY: 0,
        dt: 0.016,
        wasGrounded: false,
      );
      expect(result.y + 28, lessThanOrEqualTo(400.5));
    });

    test('snapToValid 必须把卡在墙内的玩家推出', () {
      final PlatformPhysicsSolver solver = PlatformPhysicsSolver(
        platforms: <PlatformSurface>[
          const PlatformSurface(
            left: 0,
            top: 400,
            right: 320,
            bottom: 464,
            isOneWay: false,
          ),
        ],
        worldWidth: 800,
        worldHeight: 480,
        gravityDirection: 1,
      );
      final PlatformPhysicsResult result = solver.snapToValid(
        x: 100,
        y: 440,
      );
      expect(result.y + 28, lessThanOrEqualTo(400.5));
    });

    test('陷进宽地面按左键不能被推到屏幕外', () {
      final PlatformPhysicsSolver solver = PlatformPhysicsSolver(
        platforms: <PlatformSurface>[
          const PlatformSurface(
            left: 0,
            top: 400,
            right: 800,
            bottom: 464,
            isOneWay: false,
          ),
        ],
        worldWidth: 800,
        worldHeight: 480,
        gravityDirection: 1,
      );
      final PlatformPhysicsResult result = solver.simulate(
        x: 100,
        y: 410,
        velocityX: -200,
        velocityY: 0,
        dt: 0.05,
        wasGrounded: false,
      );
      expect(result.x, greaterThanOrEqualTo(0));
      expect(result.x, lessThan(200));
      expect(result.y + 28, lessThanOrEqualTo(400.5));
    });
  });
}
