import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:meme_game/core/theme/app_colors.dart';
import 'package:meme_game/core/widgets/level_tile_widget.dart';
import 'package:meme_game/features/home/controller.dart';

/// 关卡列表区。
class HomeLevelListWidget extends StatelessWidget {
  const HomeLevelListWidget({super.key, required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Row(
          children: <Widget>[
            Text('🗺️', style: TextStyle(fontSize: 22)),
            SizedBox(width: 8),
            Text(
              '选关开搞',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          '五种玩法各来一局，找到你的本命梗',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        const SizedBox(height: 14),
        ...HomeController.demoLevels.map(_buildLevelTile),
      ],
    );
  }

  Widget _buildLevelTile(DemoLevelEntry entry) {
    return Obx(() {
      final int stars = controller.authController.readLevelStars(entry.levelId);
      final LevelTileStyle style = LevelTileStyle.fromLevelId(entry.levelId);
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: LevelTileWidget(
          title: entry.title,
          subtitle: entry.subtitle,
          tag: style.tag,
          tagColor: style.color,
          stars: stars,
          onTap: () => controller.startLevel(entry.levelId),
        ),
      );
    });
  }
}
