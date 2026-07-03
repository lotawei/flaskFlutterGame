import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:meme_game/features/result/controller.dart';

/// 结算页面。
class ResultView extends GetView<ResultController> {
  const ResultView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('本局结算')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Obx(() {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Icon(
                controller.isVictory ? Icons.emoji_events : Icons.sentiment_dissatisfied,
                size: 72,
                color: controller.isVictory ? Colors.amber : Colors.grey,
              ),
              const SizedBox(height: 16),
              Text(
                controller.isVictory ? '搞事成功！' : '搞事失败…',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                controller.levelName.value,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              _StatRow(
                label: '收集金币',
                value: '${controller.coins.value}/${controller.totalCoins.value}',
              ),
              _StatRow(
                label: '用时',
                value: '${controller.seconds.value.toStringAsFixed(1)} 秒',
              ),
              _StatRow(
                label: 'trace_id',
                value: controller.traceId.value,
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: controller.replay,
                child: const Text('再来一局'),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: controller.goHome,
                child: const Text('回首页'),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: <Widget>[
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
