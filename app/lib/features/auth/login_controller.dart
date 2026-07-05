import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:meme_game/core/observability/trace_context.dart';
import 'package:meme_game/core/ui/app_loading_service.dart';
import 'package:meme_game/data/repositories/auth_repository.dart';
import 'package:meme_game/features/auth/auth_controller.dart';

/// 登录/注册页控制器。
class LoginController extends GetxController {
  LoginController({
    required AuthRepository authRepository,
    required AuthController authController,
  })  : _authRepository = authRepository,
        _authController = authController;

  final AuthRepository _authRepository;
  final AuthController _authController;

  final TextEditingController usernameController = TextEditingController(text: 'demo');
  final TextEditingController passwordController = TextEditingController(text: 'demo123456');
  final TextEditingController displayNameController = TextEditingController();
  final RxBool isRegisterMode = false.obs;
  final RxString errorMessage = ''.obs;

  Future<void> submit() async {
    errorMessage.value = '';
    AppLoadingService.to.show(
      message: isRegisterMode.value ? '注册中…' : '登录中…',
    );
    final TraceContext traceContext = TraceContext.create();
    try {
      if (isRegisterMode.value) {
        await _authRepository.register(
          username: usernameController.text.trim(),
          password: passwordController.text,
          displayName: displayNameController.text.trim().isEmpty
              ? usernameController.text.trim()
              : displayNameController.text.trim(),
          traceContext: traceContext,
        );
      } else {
        await _authRepository.login(
          username: usernameController.text.trim(),
          password: passwordController.text,
          traceContext: traceContext,
        );
      }
      await _authController.restoreSession();
      Get.back<void>();
    } on AuthException catch (err) {
      errorMessage.value = err.message;
    } catch (err) {
      errorMessage.value = err.toString();
    } finally {
      AppLoadingService.to.dismiss();
    }
  }

  void toggleMode() {
    isRegisterMode.value = !isRegisterMode.value;
    errorMessage.value = '';
  }

  @override
  void onClose() {
    usernameController.dispose();
    passwordController.dispose();
    displayNameController.dispose();
    super.onClose();
  }
}
