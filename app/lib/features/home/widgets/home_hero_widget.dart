import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:meme_game/core/theme/app_colors.dart';
import 'package:meme_game/core/widgets/meme_primary_button.dart';
import 'package:meme_game/core/widgets/stat_chip.dart';
import 'package:meme_game/features/auth/auth_controller.dart';
import 'package:meme_game/features/home/controller.dart';

/// 首页顶部 Hero + 账号区。
class HomeHeroWidget extends StatelessWidget {
  const HomeHeroWidget({super.key, required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _buildLogoRow(),
        const SizedBox(height: 16),
        _buildAccountSection(),
        const SizedBox(height: 20),
        MemePrimaryButton(
          label: '马上开搞！',
          icon: Icons.sports_esports,
          isAccent: true,
          onPressed: controller.startDemoLevel,
        ),
        const SizedBox(height: 8),
        const Text(
          '跑、跳、收币、踩敌人——先到旗子的人赢',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildLogoRow() {
    return Row(
      children: <Widget>[
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.asset(
            'assets/icon/app_icon.png',
            width: 64,
            height: 64,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(width: 14),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                '搞事事',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                  height: 1.1,
                ),
              ),
              Text(
                '离谱梗游 · 五玩法试炼',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAccountSection() {
    final AuthController auth = controller.authController;
    return Obx(() {
      if (!auth.isLoggedIn.value) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.outline, width: 2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const Text(
                '登录存档，三星进度云同步 ☁️',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: controller.openLogin,
                icon: const Icon(Icons.login, size: 20),
                label: const Text('登录 / 注册'),
              ),
            ],
          ),
        );
      }
      final summary = auth.userSummary.value;
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: <Color>[
              AppColors.primary.withValues(alpha: 0.15),
              Colors.white.withValues(alpha: 0.9),
            ],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.outline, width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                const CircleAvatar(
                  backgroundColor: AppColors.primary,
                  child: Icon(Icons.face, color: Colors.white),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        auth.user.value?.displayName ?? '玩家',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '@${auth.user.value?.username ?? ''}',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(onPressed: controller.logout, child: const Text('退出')),
              ],
            ),
            if (summary != null) ...<Widget>[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  StatChip(
                    emoji: '⭐',
                    label: '总星 ${summary.totalStars}',
                    highlight: true,
                  ),
                  StatChip(emoji: '🏁', label: '通关 ${summary.clearedLevels}'),
                  StatChip(emoji: '🎮', label: '游玩 ${summary.playedLevels}'),
                ],
              ),
            ],
          ],
        ),
      );
    });
  }
}
