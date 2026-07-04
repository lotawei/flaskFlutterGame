import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:meme_game/core/theme/app_colors.dart';
import 'package:meme_game/core/widgets/sky_scaffold.dart';
import 'package:meme_game/data/models/manifest_model.dart';
import 'package:meme_game/features/home/controller.dart';
import 'package:meme_game/features/home/widgets/home_hero_widget.dart';
import 'package:meme_game/features/home/widgets/home_level_list_widget.dart';

/// 首页：选关试玩 + 账号进度。
class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return SkyScaffold(
      appBar: AppBar(
        title: const Text('搞事事'),
        actions: <Widget>[
          IconButton(
            onPressed: controller.loadManifest,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: '刷新梗包',
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value || controller.authController.isRestoring.value) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }
        return _buildContent();
      }),
    );
  }

  Widget _buildContent() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: <Widget>[
        HomeHeroWidget(controller: controller),
        const SizedBox(height: 28),
        HomeLevelListWidget(controller: controller),
        if (controller.hasError.value) ...<Widget>[
          const SizedBox(height: 16),
          _buildManifestError(),
        ],
        if (controller.packs.isNotEmpty) ...<Widget>[
          const SizedBox(height: 24),
          _buildRemotePacksSection(),
        ],
        const SizedBox(height: 16),
        _buildDevInfoSection(),
      ],
    );
  }

  Widget _buildManifestError() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outline, width: 2),
      ),
      child: Row(
        children: <Widget>[
          const Icon(Icons.cloud_off_rounded, color: AppColors.accent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '梗包服务未连接，本地试玩不受影响',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary.withValues(alpha: 0.85),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRemotePacksSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Row(
          children: <Widget>[
            Text('📦', style: TextStyle(fontSize: 20)),
            SizedBox(width: 8),
            Text(
              '远程梗包',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...controller.packs.map(_buildPackTile),
      ],
    );
  }

  Widget _buildPackTile(MemePackModel pack) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(14),
        child: ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: AppColors.outline, width: 1.5),
          ),
          leading: const Icon(Icons.videogame_asset_rounded, color: AppColors.primary),
          title: Text(
            pack.name,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          subtitle: Text('${pack.version} · ${pack.sizeBytes} bytes'),
          trailing: pack.isDeprecated
              ? const Chip(label: Text('已下线'))
              : IconButton(
                  icon: const Icon(Icons.play_circle_fill_rounded, color: AppColors.primary),
                  onPressed: controller.startDemoLevel,
                ),
        ),
      ),
    );
  }

  Widget _buildDevInfoSection() {
    return Theme(
      data: Theme.of(Get.context!).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(top: 4, bottom: 8),
        title: Text(
          '开发者信息',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary.withValues(alpha: 0.9),
          ),
        ),
        children: <Widget>[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.outline.withValues(alpha: 0.4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  '服务端: ${controller.serverVersion.value.isEmpty ? '离线' : controller.serverVersion.value}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 4),
                SelectableText(
                  'trace: ${controller.lastTraceId.value}',
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
