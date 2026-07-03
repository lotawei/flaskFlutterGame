import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:meme_game/data/models/manifest_model.dart';
import 'package:meme_game/features/home/controller.dart';

/// 首页：试玩入口 + manifest 状态。
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
        if (controller.isLoading.value) {
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
        _buildPlayCard(),
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

  Widget _buildPlayCard() {
    return Card(
      color: Theme.of(Get.context!).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const Text(
              '哈基高原 · Demo',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('跑跳收集金币，到达终点旗子通关。支持键盘和触控。'),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: controller.startDemoLevel,
              icon: const Icon(Icons.play_arrow),
              label: const Text('开始试玩'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
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
