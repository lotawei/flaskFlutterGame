import 'package:flutter/material.dart';

/// 搞事事 UI 色板（对齐 shared/art/asset_manifest.json）。
class AppColors {
  AppColors._();

  static const Color sky = Color(0xFFB3E5FC);
  static const Color skyDeep = Color(0xFF81D4FA);
  static const Color primary = Color(0xFF7C4DFF);
  static const Color primaryDark = Color(0xFF5E35B1);
  static const Color accent = Color(0xFFFF6D00);
  static const Color coin = Color(0xFFFFD54F);
  static const Color outline = Color(0xFF1A1A1A);
  static const Color surface = Color(0xFFFFFDE7);
  static const Color surfaceCard = Color(0xFFFFFFFF);
  static const Color danger = Color(0xFFD50000);
  static const Color success = Color(0xFF66BB6A);
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF616161);
  static const Color hudBg = Color(0xCC1A1A1A);

  static const LinearGradient skyGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: <Color>[Color(0xFF81D4FA), Color(0xFFB3E5FC), Color(0xFFE1F5FE)],
  );
}
