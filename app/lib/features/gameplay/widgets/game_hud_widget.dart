import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:meme_game/features/gameplay/controller.dart';

/// 游戏 HUD：金币、提示、暂停。
class GameHudWidget extends StatelessWidget {
  const GameHudWidget({super.key, required this.controller});

  final GameplayController controller;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                IconButton(
                  onPressed: () => Get.back<void>(),
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black54,
                  ),
                ),
                const SizedBox(width: 8),
                Obx(
                  () => Chip(
                    label: Text(
                      '金币 ${controller.collectedCoins.value}/${controller.totalCoins.value}',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Obx(
                  () {
                    final double? remaining = controller.remainingSeconds.value;
                    if (remaining == null) {
                      return const SizedBox.shrink();
                    }
                    final bool isWarning = controller.isTimeWarning.value;
                    return Chip(
                      backgroundColor:
                          isWarning ? Colors.red.shade100 : null,
                      label: Text(
                        '⏱ ${remaining.ceil()}s',
                        style: TextStyle(
                          color: isWarning ? Colors.red.shade900 : null,
                          fontWeight:
                              isWarning ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    );
                  },
                ),
                const Spacer(),
                IconButton(
                  onPressed: controller.togglePause,
                  icon: Obx(
                    () => Icon(
                      controller.isPaused.value ? Icons.play_arrow : Icons.pause,
                      color: Colors.white,
                    ),
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black54,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Obx(
              () => controller.tipText.value.isEmpty
                  ? const SizedBox.shrink()
                  : Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        controller.tipText.value,
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
            ),
            const Spacer(),
            const Text(
              '键盘: A/D 或 ←/→ 移动，W/↑/空格 跳跃',
              style: TextStyle(color: Colors.black87, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
