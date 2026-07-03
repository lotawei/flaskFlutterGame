import 'package:flutter/material.dart';
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
              const SizedBox(width: 8),
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
                width: 72,
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
    this.width = 56,
  });

  final String label;
  final VoidCallback onPressed;
  final VoidCallback onReleased;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => onPressed(),
      onPointerUp: (_) => onReleased(),
      onPointerCancel: (_) => onReleased(),
      child: Container(
        width: width,
        height: 56,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white24),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
