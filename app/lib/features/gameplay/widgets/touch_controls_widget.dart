import 'package:flutter/material.dart';
import 'package:meme_game/core/theme/app_colors.dart';
import 'package:meme_game/features/gameplay/controller.dart';

/// 像素风触控按钮（使用 ui/buttons 精灵皮肤）。
class TouchControlsWidget extends StatelessWidget {
  const TouchControlsWidget({super.key, required this.controller});

  final GameplayController controller;

  static const String _leftAsset = 'assets/images/ui/buttons/ui_btn_left.png';
  static const String _rightAsset = 'assets/images/ui/buttons/ui_btn_right.png';
  static const String _jumpAsset = 'assets/images/ui/buttons/ui_btn_jump.png';

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              _PixelControlButton(
                assetPath: _leftAsset,
                onPressed: () => controller.setMoveLeft(true),
                onReleased: () => controller.setMoveLeft(false),
              ),
              const SizedBox(width: 12),
              _PixelControlButton(
                assetPath: _rightAsset,
                onPressed: () => controller.setMoveRight(true),
                onReleased: () => controller.setMoveRight(false),
              ),
              const Spacer(),
              _PixelControlButton(
                assetPath: _jumpAsset,
                size: 76,
                onPressed: () => controller.setJumpHeld(true),
                onReleased: () => controller.setJumpHeld(false),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PixelControlButton extends StatefulWidget {
  const _PixelControlButton({
    required this.assetPath,
    required this.onPressed,
    required this.onReleased,
    this.size = 64,
  });

  final String assetPath;
  final VoidCallback onPressed;
  final VoidCallback onReleased;
  final double size;

  @override
  State<_PixelControlButton> createState() => _PixelControlButtonState();
}

class _PixelControlButtonState extends State<_PixelControlButton> {
  bool _isPressed = false;

  void _handleDown() {
    setState(() => _isPressed = true);
    widget.onPressed();
  }

  void _handleUp() {
    if (!_isPressed) {
      return;
    }
    setState(() => _isPressed = false);
    widget.onReleased();
  }

  @override
  Widget build(BuildContext context) {
    final double offsetY = _isPressed ? 3 : 0;
    return Listener(
      onPointerDown: (_) => _handleDown(),
      onPointerUp: (_) => _handleUp(),
      onPointerCancel: (_) => _handleUp(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 50),
        transform: Matrix4.translationValues(0, offsetY, 0),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: _isPressed
                ? null
                : const <BoxShadow>[
                    BoxShadow(
                      color: AppColors.outline,
                      offset: Offset(0, 4),
                      blurRadius: 0,
                    ),
                  ],
          ),
          child: Image.asset(
            widget.assetPath,
            width: widget.size,
            height: widget.size,
            filterQuality: FilterQuality.none,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => _buildFallbackButton(),
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackButton() {
    return Container(
      width: widget.size,
      height: widget.size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outline, width: 2.5),
      ),
      child: const Icon(Icons.circle, color: Colors.white54, size: 20),
    );
  }
}
