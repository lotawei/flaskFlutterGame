import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:meme_game/app/app_module.dart';

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
      title: '梗次元闯关',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      initialRoute: '/',
      getPages: AppModule.pages,
      debugShowCheckedModeBanner: false,
    );
  }
}
