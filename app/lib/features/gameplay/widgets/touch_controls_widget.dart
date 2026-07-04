import 'package:flutter/material.dart';
import 'package:meme_game/core/theme/app_colors.dart';
import 'package:meme_game/features/gameplay/controller.dart';

/// 触控按钮（移动端）。
class TouchControlsWidget extends StatelessWidget {
  const TouchControlsWidget({super.key, required this.controller});

  final GameplayController controller;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Row(
            children: <Widget>[
              _ControlButton(
                label: '←',
                onPressed: () => controller.setMoveLeft(true),
                onReleased: () => controller.setMoveLeft(false),
              ),
              const SizedBox(width: 10),
              _ControlButton(
                label: '→',
                onPressed: () => controller.setMoveRight(true),
                onReleased: () => controller.setMoveRight(false),
              ),
              const Spacer(),
              _ControlButton(
                label: '跳',
                onPressed: () => controller.setJumpHeld(true),
                onReleased: () => controller.setJumpHeld(false),
                width: 76,
                isAccent: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  const _ControlButton({
    required this.label,
    required this.onPressed,
    required this.onReleased,
    this.width = 60,
    this.isAccent = false,
  });

  final String label;
  final VoidCallback onPressed;
  final VoidCallback onReleased;
  final double width;
  final bool isAccent;

  @override
  Widget build(BuildContext context) {
    final Color bg = isAccent ? AppColors.accent : AppColors.primary;
    return Listener(
      onPointerDown: (_) => onPressed(),
      onPointerUp: (_) => onReleased(),
      onPointerCancel: (_) => onReleased(),
      child: Container(
        width: width,
        height: 60,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.outline, width: 2.5),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: AppColors.outline,
              offset: Offset(0, 4),
              blurRadius: 0,
            ),
          ],
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}
