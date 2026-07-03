import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:meme_game/app/app_module.dart';
import 'package:meme_game/core/network/api_client.dart';
import 'package:meme_game/core/observability/app_logger.dart';
import 'package:meme_game/core/observability/trace_context.dart';
import 'package:meme_game/data/repositories/content_repository.dart';
import 'package:meme_game/features/home/controller.dart';
import 'package:meme_game/features/home/view.dart';

void main() {
  setUp(() {
    Get.reset();
    AppModule.init();
    final AppLogger logger = Get.find<AppLogger>();
    final ApiClient apiClient = Get.find<ApiClient>();
    Get.lazyPut<HomeController>(
      () => HomeController(
        contentRepository: ContentRepository(
          apiClient: apiClient,
          logger: logger,
        ),
        logger: logger,
        shouldAutoLoad: false,
      ),
    );
  });

  tearDown(() {
    Get.reset();
  });

  test('TraceContext 可生成并转为 Header', () {
    final TraceContext context = TraceContext.create();
    expect(context.traceId.startsWith('trace-'), isTrue);
    expect(context.toHeaders()['X-Trace-Id'], context.traceId);
  });

  test('AppLogger 可按级别输出结构化事件', () {
    final AppLogger logger = Get.find<AppLogger>();
    expect(
      () => logger.info(
        module: 'test',
        event: 'test.event',
        message: '测试日志',
        traceContext: TraceContext.create(),
      ),
      returnsNormally,
    );
  });

  testWidgets('首页可渲染', (WidgetTester tester) async {
    await tester.pumpWidget(
      const GetMaterialApp(home: HomeView()),
    );
    expect(find.textContaining('梗次元闯关'), findsOneWidget);
  });
}
