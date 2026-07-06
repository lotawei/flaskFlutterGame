import 'package:flutter/material.dart';
import 'package:meme_game/core/theme/app_colors.dart';

/// 关卡选择卡片。
class LevelTileWidget extends StatelessWidget {
  LevelTileWidget({
    super.key,
    required this.title,
    required this.subtitle,
    required this.tag,
    required this.tagColor,
    required this.stars,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String tag;
  final Color tagColor;
  final int stars;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final String starText = stars > 0 ? '★' * stars + '☆' * (3 - stars) : '未通关';
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
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
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: <Widget>[
                Container(
                  width: 52,
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: tagColor.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.outline, width: 1.5),
                  ),
                  child: Text(
                    stars > 0 ? '$stars★' : 'GO',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: stars > 0 ? 14 : 16,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: tagColor,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppColors.outline,
                                width: 1,
                              ),
                            ),
                            child: Text(
                              tag,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            starText,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: stars > 0
                                  ? AppColors.accent
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.play_circle_filled, color: AppColors.primary, size: 36),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 玩法原型 → 展示标签与颜色。
class LevelTileStyle {
  LevelTileStyle({required this.tag, required this.color});

  final String tag;
  final Color color;

  static LevelTileStyle fromLevelId(String levelId) {
    if (levelId.contains('timed')) {
      return LevelTileStyle(tag: '限时', color: const Color(0xFFFF8A65));
    }
    if (levelId.contains('reversal')) {
      return LevelTileStyle(tag: '反转', color: const Color(0xFFCE93D8));
    }
    if (levelId.contains('greed')) {
      return LevelTileStyle(tag: '贪币', color: const Color(0xFF80CBC4));
    }
    if (levelId.contains('lie_flat')) {
      return LevelTileStyle(tag: '躺平', color: const Color(0xFF90CAF9));
    }
    if (levelId.contains('gravity')) {
      return LevelTileStyle(tag: '重力', color: const Color(0xFFBA68C8));
    }
    return LevelTileStyle(tag: '冲关', color: AppColors.coin);
  }
}
