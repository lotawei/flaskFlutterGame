import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:meme_game/core/theme/app_colors.dart';
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
                _HudIconButton(
                  icon: Icons.arrow_back_rounded,
                  onPressed: () => Get.back<void>(),
                ),
                const SizedBox(width: 8),
                Obx(
                  () => _HudChip(
                    label: '🪙 ${controller.collectedCoins.value}/${controller.totalCoins.value}',
                    highlight: true,
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
                    return _HudChip(
                      label: '⏱ ${remaining.ceil()}s',
                      isDanger: isWarning,
                    );
                  },
                ),
                const Spacer(),
                Obx(
                  () => _HudIconButton(
                    icon: controller.isPaused.value
                        ? Icons.play_arrow_rounded
                        : Icons.pause_rounded,
                    onPressed: controller.togglePause,
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
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.hudBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white24, width: 1.5),
                      ),
                      child: Text(
                        controller.tipText.value,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.outline.withValues(alpha: 0.5)),
              ),
              child: const Text(
                '键盘: A/D 或 ←/→ 移动 · W/↑/空格 跳跃',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HudIconButton extends StatelessWidget {
  const _HudIconButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.hudBg,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white24, width: 1.5),
          ),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}

class _HudChip extends StatelessWidget {
  const _HudChip({
    required this.label,
    this.highlight = false,
    this.isDanger = false,
  });

  final String label;
  final bool highlight;
  final bool isDanger;

  @override
  Widget build(BuildContext context) {
    final Color bg = isDanger
        ? AppColors.danger.withValues(alpha: 0.9)
        : highlight
            ? AppColors.coin.withValues(alpha: 0.95)
            : AppColors.hudBg;
    final Color textColor = highlight && !isDanger
        ? AppColors.textPrimary
        : Colors.white;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDanger ? AppColors.danger : AppColors.outline.withValues(alpha: 0.6),
          width: 1.5,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w800,
          fontSize: 13,
        ),
      ),
    );
  }
}
