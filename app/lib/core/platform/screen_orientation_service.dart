import 'package:flutter/services.dart';

/// 屏幕方向管理：首页竖屏，闯关横屏。
class ScreenOrientationService {
  ScreenOrientationService._();

  static const List<DeviceOrientation> _portraitOrientations = <DeviceOrientation>[
    DeviceOrientation.portraitUp,
  ];

  static const List<DeviceOrientation> _landscapeOrientations = <DeviceOrientation>[
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ];

  static Future<void> lockPortrait() async {
    await SystemChrome.setPreferredOrientations(_portraitOrientations);
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  static Future<void> lockLandscape() async {
    await SystemChrome.setPreferredOrientations(_landscapeOrientations);
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }
}
