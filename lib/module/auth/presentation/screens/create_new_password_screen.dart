import 'package:beatx_flutter/core/common/widget/reactive_button/save_button.dart';
import 'package:beatx_flutter/core/notifiers/snackbar_notifier.dart';
import 'package:beatx_flutter/module/auth/controller/create_new_password_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../../core/theme/app_gap.dart';
import '../../../onbording/common/app_logo.dart';
import '../../presentation/widget/textfield.dart';
import 'login_screen.dart';

class CreateNewPasswordScreen extends StatefulWidget {
  const CreateNewPasswordScreen({
    super.key,
    required this.email,
    required this.otp,
  });

  final String email;
  final String otp;

  @override
  State<CreateNewPasswordScreen> createState() => _CreateNewPasswordScreenState();
}

class _CreateNewPasswordScreenState extends State<CreateNewPasswordScreen> {
  final _formKey = GlobalKey<FormState>();

  late final ResetPasswordController _controller;
  late final bool _ownsController;

  String _password = '';

  static const _buttonGradient = LinearGradient(
    colors: [
      Color(0xFF9BFF4D),
      Color(0xFF40DDEB),
    ],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  @override
  void initState() {
    super.initState();
    _ownsController = !Get.isRegistered<ResetPasswordController>();
    _controller = _ownsController
        ? Get.put(
            ResetPasswordController(email: widget.email, otp: widget.otp),
          )
        : Get.find<ResetPasswordController>();
  }

  @override
  void dispose() {
    if (_ownsController && Get.isRegistered<ResetPasswordController>()) {
      Get.delete<ResetPasswordController>();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: const Color(0xFF0B0B0C),
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFF0B0B0C),
        body: SafeArea(
          child: Stack(
            children: [
              Positioned(
                top: 16,
                left: 16,
                child: InkWell(
                  onTap: () => Navigator.pop(context),
                  borderRadius: BorderRadius.circular(30),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .05),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ),

              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 20,
                  ),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(
                      20,
                      34,
                      20,
                      24,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D0D0E),
                      borderRadius: BorderRadius.circular(48),
                      border: Border.all(
                        color: const Color(0xFF77727F),
                        width: 1.1,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x66000000),
                          blurRadius: 28,
                          offset: Offset(0, 18),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          const AppLogo(),

                          Gap.h12,

                          const Text(
                            "Reset Password?",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 30,
                              fontWeight: FontWeight.w700,
                            ),
                          ),

                          const SizedBox(height: 12),

                          const Text(
                            "Please enter a new password for your account. "
                            "Use a strong password to keep your account secure.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFFB6B2B8),
                              fontSize: 13,
                              height: 1.5,
                            ),
                          ),

                          Gap.h32,

                          LabeledTextField(
                            title: "NEW PASSWORD",
                            hintText: "••••••••",
                            prefixIcon: Icons.lock_outline,
                            isPassword: true,
                            onChanged: (value) {
                              _password = value;
                              _controller.newPassword = value;
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return "Enter new password";
                              }

                              if (value.length < 6) {
                                return "Minimum 6 characters";
                              }

                              return null;
                            },
                          ),

                          LabeledTextField(
                            title: "CONFIRM PASSWORD",
                            hintText: "••••••••",
                            prefixIcon: Icons.lock_outline,
                            isPassword: true,
                            onChanged: (value) {
                              _controller.confirmPassword = value;
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return "Confirm password";
                              }

                              if (value != _password) {
                                return "Passwords do not match";
                              }

                              return null;
                            },
                          ),

                          const SizedBox(height: 20),

                          RSaveButton(
                            key: const ValueKey(
                              'create-new-password-save-button',
                            ),
                            height: 55,
                            borderRadius: BorderRadius.circular(28),
                            activeGradient: _buttonGradient,
                            style: const TextStyle(
                              color: Color(0xFF113238),
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0,
                            ),
                            saveText: 'Reset Password',
                            loadingText: 'Saving',
                            doneText: 'Done',
                            errorText: 'Failed',
                            buttonStatusNotifier: _controller.processNotifier,
                            onSaveTap: () {
                              if (!(_formKey.currentState?.validate() ??
                                  false)) {
                                return;
                              }
                              _controller.resetPassword(
                                SnackbarNotifier(context: context),
                              );
                            },
                            onDone: () {
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const LoginScreen(),
                                ),
                                (route) => false,
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
