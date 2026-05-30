import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/helpers/handle_fold.dart';
import '../../../core/localization/app_language_controller.dart';
import '../../../core/notifiers/button_status_notifier.dart';
import '../../../core/notifiers/snackbar_notifier.dart';
import '../model/signup_model.dart';
import '../services/auth_interface.dart';

class SignUpController extends GetxController {
  final ProcessStatusNotifier processNotifier = ProcessStatusNotifier(
    initialStatus: EnabledStatus(),
  );

  final username = ''.obs;
  final email = ''.obs;
  final phoneNumber = ''.obs;
  final password = ''.obs;
  final confirmPassword = ''.obs;
  final preferredLanguage = 'en'.obs;

  @override
  void onInit() {
    super.onInit();
    if (Get.isRegistered<AppLanguageController>()) {
      preferredLanguage.value =
          Get.find<AppLanguageController>().languageCode.value;
    }
  }

  void setUsername(String value) {
    username.value = value;
    processNotifier.setEnabled();
  }

  void setEmail(String value) {
    email.value = value;
    processNotifier.setEnabled();
  }

  void setPhoneNumber(String value) {
    phoneNumber.value = value;
    processNotifier.setEnabled();
  }

  void setPassword(String value) {
    password.value = value;
    processNotifier.setEnabled();
  }

  void setConfirmPassword(String value) {
    confirmPassword.value = value;
    processNotifier.setEnabled();
  }

  void setPreferredLanguage(String value) {
    preferredLanguage.value = value;
    processNotifier.setEnabled();
  }

  SignupModel get signupModel => SignupModel(
    username: username.value,
    email: email.value,
    phoneNumber: phoneNumber.value,
    password: password.value,
    confirmPassword: confirmPassword.value,
    preferredLanguage: preferredLanguage.value,
  );

  Future<void> signup({
    ProcessStatusNotifier? buttonNotifier,
    SnackbarNotifier? snackbarNotifier,
    VoidCallback? onDone,
  }) async {
    buttonNotifier?.setLoading();

    final result = await Get.find<AuthInterface>().signup(signupModel);

    handleFold(
      either: result,
      errorSnackbarNotifier: snackbarNotifier,
      successSnackbarNotifier: snackbarNotifier,
      onError: (failure) {
        buttonNotifier?.setError();
        snackbarNotifier?.notifyError(message: failure.uiMessage);
      },
      onSuccess: (success) {
        buttonNotifier?.setSuccess();
        snackbarNotifier?.notifySuccess(message: success.message);
        onDone?.call();
      },
      processStatusNotifier: buttonNotifier,
    );
  }
}
