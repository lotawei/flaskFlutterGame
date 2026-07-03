import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:meme_game/data/models/manifest_model.dart';
import 'package:meme_game/features/home/controller.dart';

/// 首页视图：基座演示 + manifest 列表。
class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('梗次元闯关 · 基座'),
        actions: <Widget>[
          IconButton(
            onPressed: controller.loadManifest,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.hasError.value) {
          return _buildError();
        }
        return _buildContent();
      }),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
            const SizedBox(height: 12),
            Text(controller.errorMessage.value, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: controller.loadManifest,
              child: const Text('重试'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        _buildTraceCard(),
        const SizedBox(height: 12),
        Text('服务端版本: ${controller.serverVersion.value}'),
        const SizedBox(height: 8),
        const Text('可用梗包:', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...controller.packs.map(_buildPackTile),
      ],
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
            const SizedBox(height: 4),
            const Text(
              '排查时在日志平台搜索此 trace_id，可串联客户端与服务端日志。',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
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
          : const Icon(Icons.check_circle_outline, color: Colors.green),
    );
  }
}
