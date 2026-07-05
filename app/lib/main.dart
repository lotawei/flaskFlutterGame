import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:meme_game/app/app_module.dart';
import 'package:meme_game/core/theme/app_theme.dart';
import 'package:meme_game/core/ui/app_loading_overlay.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppModule.init();
  runApp(const MemeGameApp());
}

/// 应用入口 Widget。
class MemeGameApp extends StatelessWidget {
  const MemeGameApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: '搞事事',
      theme: AppTheme.buildLightTheme(),
      initialRoute: '/',
      getPages: AppModule.pages,
      debugShowCheckedModeBanner: false,
      builder: (BuildContext context, Widget? child) {
        return Stack(
          children: <Widget>[
            if (child != null) child,
            const AppLoadingOverlay(),
          ],
        );
      },
    );
  }
}
