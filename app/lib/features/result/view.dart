import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:meme_game/core/theme/app_colors.dart';
import 'package:meme_game/core/widgets/meme_primary_button.dart';
import 'package:meme_game/core/widgets/sky_scaffold.dart';
import 'package:meme_game/core/widgets/stat_chip.dart';
import 'package:meme_game/features/result/controller.dart';

/// 结算页面。
class ResultView extends GetView<ResultController> {
  const ResultView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final bool isVictory = controller.isVictory;
      return SkyScaffold(
        appBar: AppBar(title: const Text('本局结算')),
        body: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _buildHero(isVictory),
              const SizedBox(height: 20),
              _buildQuoteCard(),
              const SizedBox(height: 20),
              _buildStatsCard(isVictory),
              const Spacer(),
              MemePrimaryButton(
                label: '再来一局',
                icon: Icons.replay_rounded,
                isAccent: true,
                onPressed: controller.replay,
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: controller.goHome,
                child: const Text('回首页'),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildHero(bool isVictory) {
    return Column(
      children: <Widget>[
        Container(
          width: 96,
          height: 96,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isVictory
                ? AppColors.coin.withValues(alpha: 0.35)
                : AppColors.skyDeep.withValues(alpha: 0.4),
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.outline, width: 2.5),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: AppColors.outline,
                offset: Offset(0, 4),
                blurRadius: 0,
              ),
            ],
          ),
          child: Icon(
            isVictory ? Icons.emoji_events_rounded : Icons.sentiment_dissatisfied_rounded,
            size: 52,
            color: isVictory ? AppColors.accent : AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          controller.titleText,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            color: AppColors.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Text(
          controller.levelName.value,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildQuoteCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.outline, width: 2),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: AppColors.outline,
            offset: Offset(0, 3),
            blurRadius: 0,
          ),
        ],
      ),
      child: Text(
        controller.memeQuote.value,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          height: 1.4,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildStatsCard(bool isVictory) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.outline, width: 2),
      ),
      child: Column(
        children: <Widget>[
          _StatRow(
            emoji: '🪙',
            label: '收集金币',
            value: '${controller.coins.value}/${controller.totalCoins.value}',
          ),
          _StatRow(
            emoji: '⏱️',
            label: '用时',
            value: '${controller.seconds.value.toStringAsFixed(1)} 秒',
          ),
          if (isVictory)
            _StatRow(
              emoji: '⭐',
              label: '本局三星',
              value: '${'★' * controller.stars.value}${'☆' * (3 - controller.stars.value)}',
              highlight: controller.stars.value >= 3,
            ),
          Obx(
            () => controller.syncMessage.value.isEmpty
                ? const SizedBox.shrink()
                : _StatRow(
                    emoji: '☁️',
                    label: '账号同步',
                    value: controller.syncMessage.value,
                  ),
          ),
          Obx(
            () => controller.syncedTotalStars.value == null
                ? const SizedBox.shrink()
                : _StatRow(
                    emoji: '🏆',
                    label: '账号总星',
                    value: '${controller.syncedTotalStars.value}',
                    highlight: true,
                  ),
          ),
          Obx(
            () => controller.isLoggedIn.value
                ? const SizedBox.shrink()
                : const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      '登录后可同步进度到云端',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.emoji,
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final String emoji;
  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: <Widget>[
          StatChip(emoji: emoji, label: label, highlight: highlight),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 15,
                color: AppColors.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
