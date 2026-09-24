import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:meme_game/features/gameplay/controller.dart';
import 'package:meme_game/features/gameplay/widgets/game_hud_widget.dart';
import 'package:meme_game/features/gameplay/widgets/touch_controls_widget.dart';

/// 闯关页面。
class GameplayView extends GetView<GameplayController> {
  const GameplayView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.hasError.value) {
          return _buildError();
        }
        return _buildGame();
      }),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(controller.errorMessage.value, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => Get.back<void>(),
              child: const Text('返回首页'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGame() {
    final game = controller.game;
    if (game == null) {
      return const Center(child: Text('游戏初始化失败'));
    }
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        GameWidget(game: game),
        GameHudWidget(controller: controller),
        TouchControlsWidget(controller: controller),
      ],
    );
  }
}
