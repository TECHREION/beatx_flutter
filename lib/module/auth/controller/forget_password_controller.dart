import 'dart:async';
import 'package:beatx_flutter/module/auth/services/auth_interface.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/helpers/handle_fold.dart';
import '../../../core/notifiers/button_status_notifier.dart';
import '../../../core/notifiers/snackbar_notifier.dart';
import '../model/forget_password_model.dart';
class ForgetPasswordController extends GetxController {
  final ProcessStatusNotifier processStatusNotifier = ProcessStatusNotifier(
    initialStatus: EnabledStatus(),
  );

  final SnackbarNotifier snackbarNotifier;

  ForgetPasswordController(this.snackbarNotifier);

  final TextEditingController emailController = TextEditingController();

  String get email => emailController.text.trim();

  Timer? _timer;

  Future<void> forgetPassword({required VoidCallback onSuccess}) async {
    if (!GetUtils.isEmail(email)) {
      snackbarNotifier.notifyError(message: "Please enter a valid email");
      return;
    }

    processStatusNotifier.setLoading();

    final result = await Get.find<AuthInterface>().forgetpassword(
      ForgetPasswordModel(email: email),
    );

    handleFold(
      either: result,
      processStatusNotifier: processStatusNotifier,
      successSnackbarNotifier: snackbarNotifier,
      errorSnackbarNotifier: snackbarNotifier,
      onSuccess: (_) {
        onSuccess(); // ✅ NAVIGATE ONLY ON SUCCESS
      },
    );
  }

  @override
  void onClose() {
    _timer?.cancel();
    emailController.dispose();
    super.onClose();
  }
}
