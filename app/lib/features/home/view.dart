import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:meme_game/data/models/manifest_model.dart';
import 'package:meme_game/features/auth/auth_controller.dart';
import 'package:meme_game/features/home/controller.dart';

/// 首页：账号 + 试玩入口 + manifest 状态。
class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('搞事事'),
        actions: <Widget>[
          IconButton(
            onPressed: controller.loadManifest,
            icon: const Icon(Icons.refresh),
            tooltip: '刷新梗包',
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value || controller.authController.isRestoring.value) {
          return const Center(child: CircularProgressIndicator());
        }
        return _buildContent();
      }),
    );
  }

  Widget _buildContent() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        _buildAccountCard(),
        const SizedBox(height: 12),
        _buildLevelSection(),
        if (controller.hasError.value) ...<Widget>[
          const SizedBox(height: 12),
          _buildManifestError(),
        ],
        const SizedBox(height: 12),
        _buildTraceCard(),
        const SizedBox(height: 12),
        Text('服务端版本: ${controller.serverVersion.value.isEmpty ? '离线/未连接' : controller.serverVersion.value}'),
        const SizedBox(height: 8),
        const Text('可用梗包:', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        if (controller.packs.isEmpty)
          const Text('暂无远程梗包（可直接试玩内置 Demo 关）', style: TextStyle(color: Colors.grey))
        else
          ...controller.packs.map(_buildPackTile),
      ],
    );
  }

  Widget _buildAccountCard() {
    final AuthController auth = controller.authController;
    return Obx(() {
      if (!auth.isLoggedIn.value) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const Text('未登录', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text('登录后同步三星、进度，并打通 manifest 个性化与对局上报。'),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: controller.openLogin,
                  icon: const Icon(Icons.login),
                  label: const Text('登录 / 注册'),
                ),
              ],
            ),
          ),
        );
      }
      final summary = auth.userSummary.value;
      return Card(
        color: Theme.of(Get.context!).colorScheme.secondaryContainer,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  const Icon(Icons.account_circle),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      auth.user.value?.displayName ?? auth.user.value?.username ?? '玩家',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  TextButton(onPressed: controller.logout, child: const Text('退出')),
                ],
              ),
              const SizedBox(height: 8),
              Text('@${auth.user.value?.username ?? ''}'),
              if (summary != null) ...<Widget>[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    Chip(label: Text('总星 ${summary.totalStars}')),
                    Chip(label: Text('通关 ${summary.clearedLevels} 关')),
                    Chip(label: Text('游玩 ${summary.playedLevels} 关')),
                  ],
                ),
              ],
            ],
          ),
        ),
      );
    });
  }

  Widget _buildLevelSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text('Demo 关卡（五原型）', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        ...HomeController.demoLevels.map(_buildLevelCard),
      ],
    );
  }

  Widget _buildLevelCard(DemoLevelEntry entry) {
    return Obx(() {
      final int stars = controller.authController.readLevelStars(entry.levelId);
      return Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          leading: CircleAvatar(child: Text('${stars > 0 ? stars : '-'}')),
          title: Text(entry.title),
          subtitle: Text(entry.subtitle),
          trailing: const Icon(Icons.play_arrow),
          onTap: () => controller.startLevel(entry.levelId),
        ),
      );
    });
  }

  Widget _buildManifestError() {
    return Card(
      color: Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: <Widget>[
            const Icon(Icons.cloud_off, color: Colors.orange),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '梗包服务未连接（不影响本地试玩）\n${controller.errorMessage.value}',
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTraceCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text('链路追踪', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            SelectableText('trace_id: ${controller.lastTraceId.value}'),
          ],
        ),
      ),
    );
  }

  Widget _buildPackTile(MemePackModel pack) {
    return ListTile(
      leading: const Icon(Icons.videogame_asset_outlined),
      title: Text(pack.name),
      subtitle: Text('${pack.version} · ${pack.sizeBytes} bytes'),
      trailing: pack.isDeprecated
          ? const Chip(label: Text('已下线'))
          : IconButton(
              icon: const Icon(Icons.play_circle_outline),
              onPressed: controller.startDemoLevel,
            ),
    );
  }
}
