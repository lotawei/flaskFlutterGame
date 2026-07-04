import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:meme_game/core/theme/app_colors.dart';
import 'package:meme_game/core/widgets/meme_primary_button.dart';
import 'package:meme_game/core/widgets/sky_scaffold.dart';
import 'package:meme_game/features/auth/login_controller.dart';

/// 登录/注册页面。
class LoginView extends GetView<LoginController> {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    return SkyScaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: Get.back<void>,
        ),
        title: Obx(
          () => Text(controller.isRegisterMode.value ? '注册账号' : '登录账号'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        children: <Widget>[
          _buildHeader(),
          const SizedBox(height: 24),
          _buildDemoAccountCard(),
          const SizedBox(height: 20),
          TextField(
            controller: controller.usernameController,
            decoration: const InputDecoration(
              labelText: '用户名',
              prefixIcon: Icon(Icons.person_outline_rounded),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: controller.passwordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: '密码（至少 6 位）',
              prefixIcon: Icon(Icons.lock_outline_rounded),
            ),
          ),
          Obx(() {
            if (!controller.isRegisterMode.value) {
              return const SizedBox.shrink();
            }
            return Column(
              children: <Widget>[
                const SizedBox(height: 14),
                TextField(
                  controller: controller.displayNameController,
                  decoration: const InputDecoration(
                    labelText: '显示名（可选）',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                ),
              ],
            );
          }),
          const SizedBox(height: 12),
          Obx(
            () => controller.errorMessage.value.isEmpty
                ? const SizedBox.shrink()
                : Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.danger.withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      children: <Widget>[
                        const Icon(Icons.error_outline, color: AppColors.danger, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            controller.errorMessage.value,
                            style: const TextStyle(
                              color: AppColors.danger,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
          const SizedBox(height: 20),
          Obx(
            () => MemePrimaryButton(
              label: controller.isRegisterMode.value ? '注册并登录' : '登录',
              icon: Icons.login_rounded,
              isLoading: controller.isLoading.value,
              onPressed: controller.isLoading.value ? null : controller.submit,
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: controller.toggleMode,
            child: Obx(
              () => Text(
                controller.isRegisterMode.value ? '已有账号？去登录' : '没有账号？去注册',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: <Widget>[
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Image.asset(
            'assets/icon/app_icon.png',
            width: 80,
            height: 80,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          '登录存档，三星云同步',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          '进度、对局记录、梗包个性化一次打通',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildDemoAccountCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[
            AppColors.primary.withValues(alpha: 0.12),
            Colors.white.withValues(alpha: 0.95),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outline, width: 2),
      ),
      child: const Row(
        children: <Widget>[
          Icon(Icons.tips_and_updates_rounded, color: AppColors.primary),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  '体验账号',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                ),
                SizedBox(height: 4),
                Text(
                  'demo / demo123456',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
