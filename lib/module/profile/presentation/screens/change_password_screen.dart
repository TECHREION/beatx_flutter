import 'package:beatx_flutter/core/common/widget/reactive_button/save_button.dart';
import 'package:beatx_flutter/core/notifiers/snackbar_notifier.dart';
import 'package:beatx_flutter/module/profile/controller/change_password_cintroller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  late final ChangePasswordController _controller;
  late final bool _ownsController;

  static const LinearGradient buttonGradient = LinearGradient(
    colors: [Color(0xFF9BFF4D), Color(0xFF40DDEB)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  @override
  void initState() {
    super.initState();
    _ownsController = !Get.isRegistered<ChangePasswordController>();
    _controller = _ownsController
        ? Get.put(ChangePasswordController())
        : Get.find<ChangePasswordController>();
  }

  @override
  void dispose() {
    if (_ownsController && Get.isRegistered<ChangePasswordController>()) {
      Get.delete<ChangePasswordController>();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050608),
      body: Stack(
        children: [
          /// Purple Glow
          Positioned(
            top: 80,
            left: -80,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.deepPurple.withValues(alpha: .20),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          /// Cyan Glow
          Positioned(
            bottom: -80,
            right: -60,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.cyan.withValues(alpha: .15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// Header
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: .06),
                          ),
                          child: IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(
                              Icons.arrow_back,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          "Change Password",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 26),

                    const _LabelText(title: "Current Password"),
                    const SizedBox(height: 10),
                    Obx(
                      () => _passwordField(
                        controller: _controller.currentPasswordController,
                        obscureText:
                            !_controller.isCurrentPasswordVisible.value,
                        onToggle: _controller.toggleCurrentPasswordVisibility,
                        validator: (value) {
                          if ((value ?? '').isEmpty) {
                            return 'Please enter your current password';
                          }
                          return null;
                        },
                      ),
                    ),

                    const SizedBox(height: 22),

                    const _LabelText(title: "New Password"),
                    const SizedBox(height: 10),
                    Obx(
                      () => _passwordField(
                        controller: _controller.newPasswordController,
                        obscureText: !_controller.isNewPasswordVisible.value,
                        onToggle: _controller.toggleNewPasswordVisibility,
                        validator: _validateNewPassword,
                      ),
                    ),

                    const SizedBox(height: 14),

                    Obx(
                      () => _PasswordRule(
                        text: "8 characters",
                        isValid: _controller.hasMinLength.value,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Obx(
                      () => _PasswordRule(
                        text: "contain number, and upper-case letter",
                        isValid:
                            _controller.hasNumber.value &&
                            _controller.hasUppercase.value,
                      ),
                    ),

                    const SizedBox(height: 22),

                    const _LabelText(title: "Confirm Password"),
                    const SizedBox(height: 10),
                    Obx(
                      () => _passwordField(
                        controller: _controller.confirmPasswordController,
                        obscureText:
                            !_controller.isConfirmPasswordVisible.value,
                        onToggle: _controller.toggleConfirmPasswordVisibility,
                        validator: (value) {
                          if ((value ?? '').isEmpty) {
                            return 'Please confirm your new password';
                          }
                          if (value != _controller.newPasswordController.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                      ),
                    ),

                    const SizedBox(height: 36),

                    RSaveButton(
                      key: const ValueKey('change-password-save-button'),
                      height: 58,
                      borderRadius: BorderRadius.circular(30),
                      activeGradient: buttonGradient,
                      buttonStatusNotifier: _controller.processNotifier,
                      saveText: 'Save Changes',
                      loadingText: 'Saving',
                      doneText: 'Saved',
                      style: const TextStyle(
                        color: Color(0xFF111111),
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                      onSaveTap: _savePassword,
                      onDone: _showSavedMessage,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _passwordField({
    required TextEditingController controller,
    required bool obscureText,
    required VoidCallback onToggle,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      validator: validator,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFF171717),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        prefixIcon: const Icon(Icons.lock_outline, color: Colors.white70),
        suffixIcon: IconButton(
          onPressed: onToggle,
          icon: Icon(
            obscureText
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            color: Colors.white54,
          ),
        ),
        hintText: "••••••••",
        hintStyle: const TextStyle(color: Colors.white54),
        errorStyle: const TextStyle(color: Color(0xFFFF7A7A)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: Color(0xFF40DDEB)),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: Color(0xFFFF7A7A)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: Color(0xFFFF7A7A)),
        ),
      ),
    );
  }

  String? _validateNewPassword(String? value) {
    final password = value ?? '';
    if (password.isEmpty) {
      return 'Please enter a new password';
    }
    if (password.length < 8) {
      return 'Password must be at least 8 characters';
    }
    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      return 'Password must contain an upper-case letter';
    }
    if (!RegExp(r'\d').hasMatch(password)) {
      return 'Password must contain a number';
    }
    return null;
  }

  void _savePassword() {
    if (!_formKey.currentState!.validate()) return;

    _controller.changePassword(
      snackbarNotifier: SnackbarNotifier(context: context),
    );
  }

  void _showSavedMessage() {
    SnackbarNotifier(
      context: context,
    ).notifySuccess(message: _controller.lastSuccessMessage);
    _controller.resetAfterSuccess();
    if (mounted) {
      Navigator.pop(context);
    }
  }
}

class _LabelText extends StatelessWidget {
  final String title;

  const _LabelText({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white54,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

class _PasswordRule extends StatelessWidget {
  final String text;
  final bool isValid;

  const _PasswordRule({required this.text, required this.isValid});

  @override
  Widget build(BuildContext context) {
    final color = isValid ? const Color(0xFF00F5A0) : Colors.white38;

    return Row(
      children: [
        Icon(
          isValid ? Icons.check_circle : Icons.radio_button_unchecked,
          size: 18,
          color: color,
        ),
        const SizedBox(width: 8),
        Text(text, style: TextStyle(color: color, fontSize: 14)),
      ],
    );
  }
}
