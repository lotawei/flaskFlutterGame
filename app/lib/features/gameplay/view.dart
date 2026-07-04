import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:meme_game/core/theme/app_colors.dart';
import 'package:meme_game/core/widgets/meme_primary_button.dart';
import 'package:meme_game/core/widgets/sky_scaffold.dart';
import 'package:meme_game/features/gameplay/controller.dart';
import 'package:meme_game/features/gameplay/widgets/game_hud_widget.dart';
import 'package:meme_game/features/gameplay/widgets/touch_controls_widget.dart';

/// 闯关页面。
class GameplayView extends GetView<GameplayController> {
  const GameplayView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) {
        return _buildLoading();
      }
      if (controller.hasError.value) {
        return _buildError();
      }
      return _buildGame();
    });
  }

  Widget _buildLoading() {
    return const SkyScaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            CircularProgressIndicator(color: AppColors.primary),
            SizedBox(height: 16),
            Text(
              '关卡加载中…',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return SkyScaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Get.back<void>(),
        ),
        title: const Text('加载失败'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.outline, width: 2),
              ),
              child: Column(
                children: <Widget>[
                  const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.danger),
                  const SizedBox(height: 12),
                  Text(
                    controller.errorMessage.value,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            MemePrimaryButton(
              label: '返回首页',
              icon: Icons.home_rounded,
              onPressed: () => Get.back<void>(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGame() {
    final game = controller.game;
    if (game == null) {
      return SkyScaffold(
        body: Center(
          child: MemePrimaryButton(
            label: '返回首页',
            icon: Icons.home_rounded,
            onPressed: () => Get.back<void>(),
          ),
        ),
      );
    }
    return Scaffold(
      backgroundColor: AppColors.sky,
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          GameWidget(game: game),
          GameHudWidget(controller: controller),
          TouchControlsWidget(controller: controller),
        ],
      ),
    );
  }
}
