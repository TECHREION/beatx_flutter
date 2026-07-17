import 'package:app_pigeon/app_pigeon.dart';
import 'package:beatx_flutter/core/notifiers/button_status_notifier.dart';
import 'package:beatx_flutter/core/notifiers/snackbar_notifier.dart';
import 'package:beatx_flutter/module/profile/model/change_password_model.dart';
import 'package:beatx_flutter/module/profile/services/profile_interface.dart';
import 'package:beatx_flutter/module/profile/services/profile_interface_impl.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ChangePasswordController extends GetxController {
  final ProcessStatusNotifier processNotifier = ProcessStatusNotifier(
    initialStatus: DisabledStatus(),
  );

  final currentPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  final isCurrentPasswordVisible = false.obs;
  final isNewPasswordVisible = false.obs;
  final isConfirmPasswordVisible = false.obs;

  final hasMinLength = false.obs;
  final hasUppercase = false.obs;
  final hasNumber = false.obs;
  final passwordsMatch = false.obs;
  final canSubmit = false.obs;

  String lastSuccessMessage = 'Password changed successfully';

  @override
  void onInit() {
    super.onInit();
    currentPasswordController.addListener(_validate);
    newPasswordController.addListener(_validate);
    confirmPasswordController.addListener(_validate);
    _validate();
  }

  void toggleCurrentPasswordVisibility() {
    isCurrentPasswordVisible.value = !isCurrentPasswordVisible.value;
  }

  void toggleNewPasswordVisibility() {
    isNewPasswordVisible.value = !isNewPasswordVisible.value;
  }

  void toggleConfirmPasswordVisibility() {
    isConfirmPasswordVisible.value = !isConfirmPasswordVisible.value;
  }

  Future<void> changePassword({SnackbarNotifier? snackbarNotifier}) async {
    _validate();

    if (!canSubmit.value) {
      processNotifier.setDisabled();
      return;
    }

    processNotifier.setLoading();

    final result = await _getOrCreateProfileInterface().changePassword(
      ChangePasswordRequest(
        currentPassword: currentPasswordController.text,
        newPassword: newPasswordController.text,
        confirmPassword: confirmPasswordController.text,
      ),
    );

    result.fold(
      (failure) {
        processNotifier.setEnabled();
        snackbarNotifier?.notifyError(message: failure.uiMessage);
      },
      (success) {
        lastSuccessMessage = success.message;
        processNotifier.setSuccess(message: success.message);
      },
    );
  }

  void resetAfterSuccess() {
    currentPasswordController.clear();
    newPasswordController.clear();
    confirmPasswordController.clear();
    lastSuccessMessage = 'Password changed successfully';
    processNotifier.setDisabled();
  }

  ProfileInterface _getOrCreateProfileInterface() {
    if (!Get.isRegistered<ProfileInterface>() &&
        Get.isRegistered<AuthorizedPigeon>()) {
      Get.put<ProfileInterface>(
        ProfileInterfaceImpl(Get.find<AuthorizedPigeon>()),
      );
    }
    return Get.find<ProfileInterface>();
  }

  void _validate() {
    final currentPassword = currentPasswordController.text;
    final newPassword = newPasswordController.text;
    final confirmPassword = confirmPasswordController.text;

    hasMinLength.value = newPassword.length >= 8;
    hasUppercase.value = RegExp(r'[A-Z]').hasMatch(newPassword);
    hasNumber.value = RegExp(r'\d').hasMatch(newPassword);
    passwordsMatch.value =
        newPassword.isNotEmpty && newPassword == confirmPassword;
    canSubmit.value =
        currentPassword.isNotEmpty &&
        hasMinLength.value &&
        hasUppercase.value &&
        hasNumber.value &&
        passwordsMatch.value;

    if (processNotifier.status is LoadingStatus ||
        processNotifier.status is SuccessStatus) {
      return;
    }

    canSubmit.value
        ? processNotifier.setEnabled()
        : processNotifier.setDisabled();
  }

  @override
  void onClose() {
    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    processNotifier.dispose();
    super.onClose();
  }
}
