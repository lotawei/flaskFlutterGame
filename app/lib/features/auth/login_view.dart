import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:meme_game/features/auth/login_controller.dart';

/// 登录/注册页面。
class LoginView extends GetView<LoginController> {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Obx(() => Text(controller.isRegisterMode.value ? '注册账号' : '登录账号'))),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: <Widget>[
          const Text(
            '登录后可同步关卡进度、三星与对局记录，并打通 manifest 个性化。',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          Card(
            color: Colors.blue.shade50,
            child: const ListTile(
              leading: Icon(Icons.info_outline),
              title: Text('体验账号'),
              subtitle: Text('用户名 demo / 密码 demo123456'),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: controller.usernameController,
            decoration: const InputDecoration(
              labelText: '用户名',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller.passwordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: '密码（至少 6 位）',
              border: OutlineInputBorder(),
            ),
          ),
          Obx(() {
            if (!controller.isRegisterMode.value) {
              return const SizedBox.shrink();
            }
            return Column(
              children: <Widget>[
                const SizedBox(height: 12),
                TextField(
                  controller: controller.displayNameController,
                  decoration: const InputDecoration(
                    labelText: '显示名（可选）',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            );
          }),
          const SizedBox(height: 12),
          Obx(
            () => controller.errorMessage.value.isEmpty
                ? const SizedBox.shrink()
                : Text(
                    controller.errorMessage.value,
                    style: const TextStyle(color: Colors.red),
                  ),
          ),
          const SizedBox(height: 16),
          Obx(
            () => ElevatedButton(
              onPressed: controller.isLoading.value ? null : controller.submit,
              child: controller.isLoading.value
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(controller.isRegisterMode.value ? '注册并登录' : '登录'),
            ),
          ),
          TextButton(
            onPressed: controller.toggleMode,
            child: Obx(
              () => Text(
                controller.isRegisterMode.value ? '已有账号？去登录' : '没有账号？去注册',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
