import 'package:beatx_flutter/module/auth/services/auth_interface.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/api_handler/failure.dart';
import '../../../core/helpers/handle_fold.dart';
import '../../../core/helpers/validation.dart';
import '../../../core/localization/app_language_controller.dart';
import '../../../core/notifiers/button_status_notifier.dart';
import '../../../core/notifiers/snackbar_notifier.dart';
import '../model/login_request_model.dart';

class LoginController extends GetxController {
  final ProcessStatusNotifier processNotifier = ProcessStatusNotifier(
    initialStatus: DisabledStatus(),
  );

  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final isPasswordVisible = false.obs;
  final keepSignedIn = false.obs;
  final isLoading = false.obs;

  final email = ''.obs;
  final password = ''.obs;
  final preferredLanguage = 'en'.obs;

  @override
  void onInit() {
    super.onInit();
    if (Get.isRegistered<AppLanguageController>()) {
      preferredLanguage.value =
          Get.find<AppLanguageController>().languageCode.value;
    }
    emailController.addListener(() {
      setEmail(emailController.text);
    });
    passwordController.addListener(() {
      setPassword(passwordController.text);
    });
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }

  void setEmail(String value) {
    email.value = value.trim();
    canLogin();
  }

  void setPassword(String value) {
    password.value = value;
    canLogin();
  }

  void canLogin() {
    if (email.value.isNotEmpty &&
        isEmail(email.value) &&
        password.value.isNotEmpty) {
      processNotifier.setEnabled();
    } else {
      processNotifier.setDisabled();
    }
  }

  void togglePasswordVisibility() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }

  void toggleKeepSignedIn(bool value) {
    keepSignedIn.value = value;
  }

  LoginRequestModel get loginModel => LoginRequestModel(
    email: email.value,
    password: password.value,
    preferredLanguage: preferredLanguage.value,
  );

  Future<void> login({
    ProcessStatusNotifier? buttonNotifier,
    SnackbarNotifier? snackbarNotifier,
    VoidCallback? onDone,
    VoidCallback? needVerifyAccount,
  }) async {
    buttonNotifier?.setLoading();

    final result = await Get.find<AuthInterface>().login(loginModel);

    handleFold(
      either: result,
      processStatusNotifier: buttonNotifier,
      successSnackbarNotifier: snackbarNotifier,
      errorSnackbarNotifier: snackbarNotifier,
      onError: (error) {
        if (error.failure == Failure.forbidden) {
          needVerifyAccount?.call();
        }
      },
      onSuccess: (_) {
        onDone?.call();
      },
    );
  }
}
