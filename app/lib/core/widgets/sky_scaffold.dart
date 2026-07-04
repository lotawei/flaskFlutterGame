import 'package:flutter/material.dart';
import 'package:meme_game/core/theme/app_colors.dart';

/// 天空渐变背景 + 可选 AppBar。
class SkyScaffold extends StatelessWidget {
  const SkyScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.floatingActionButton,
  });

  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: appBar != null,
      appBar: appBar,
      floatingActionButton: floatingActionButton,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.skyGradient),
        child: body,
      ),
    );
  }
}
