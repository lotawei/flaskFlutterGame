import 'package:flutter/material.dart';
import 'package:meme_game/core/theme/app_colors.dart';

/// 主 CTA 按钮（粗描边 + 按压阴影）。
class MemePrimaryButton extends StatelessWidget {
  const MemePrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isAccent = false,
    this.isLoading = false,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isAccent;
  final bool isLoading;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final Color bg = isAccent ? AppColors.accent : AppColors.primary;
    final Widget child = isLoading
        ? const SizedBox(
            height: 22,
            width: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: Colors.white,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              if (icon != null) ...<Widget>[
                Icon(icon, size: 22),
                const SizedBox(width: 8),
              ],
              Text(label),
            ],
          );
    final Widget button = Material(
      color: bg,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: isLoading ? null : onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
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
          child: DefaultTextStyle(
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
            child: child,
          ),
        ),
      ),
    );
    if (expand) {
      return SizedBox(width: double.infinity, child: button);
    }
    return button;
  }
}
