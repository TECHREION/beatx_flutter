import 'package:beatx_flutter/core/common/widget/reactive_button/save_button.dart';
import 'package:beatx_flutter/core/notifiers/snackbar_notifier.dart';
import 'package:beatx_flutter/module/auth/controller/forget_password_controller.dart';
import 'package:beatx_flutter/module/auth/presentation/widget/textfield.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../../core/theme/app_gap.dart';
import '../../../onbording/common/app_logo.dart';
import 'otp_verification_screen.dart';

class ForgetPasswordScreen extends StatefulWidget {
  const ForgetPasswordScreen({super.key});

  @override
  State<ForgetPasswordScreen> createState() => _ForgetPasswordScreenState();
}

class _ForgetPasswordScreenState extends State<ForgetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  ForgetPasswordController? _controller;
  bool _ownsController = false;

  ForgetPasswordController get controller => _controller!;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller != null) return;

    _ownsController = !Get.isRegistered<ForgetPasswordController>();
    _controller = _ownsController
        ? Get.put(ForgetPasswordController(SnackbarNotifier(context: context)))
        : Get.find<ForgetPasswordController>();
  }

  @override
  void dispose() {
    if (_ownsController && Get.isRegistered<ForgetPasswordController>()) {
      Get.delete<ForgetPasswordController>();
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
              const _BackgroundGlow(),
              const Positioned(left: 16, top: 14, child: _BackButton()),
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(32, 92, 32, 90),
                  child: _ForgetPasswordCard(
                    formKey: _formKey,
                    controller: controller,
                  ),
                ),
              ),
              const Positioned(right: 14, bottom: 18, child: _HelpButton()),
            ],
          ),
        ),
      ),
    );
  }
}

class _ForgetPasswordCard extends StatelessWidget {
  const _ForgetPasswordCard({required this.formKey, required this.controller});

  final GlobalKey<FormState> formKey;
  final ForgetPasswordController controller;
  static const _continueGradient = LinearGradient(
    colors: [Color(0xFF9BFF4D), Color(0xFF40DDEB)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 20),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D0E),
        borderRadius: BorderRadius.circular(48),
        border: Border.all(color: const Color(0xFF77727F), width: 1.1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 28,
            offset: Offset(0, 18),
          ),
        ],
      ),
      child: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppLogo(),
            const SizedBox(height: 40),
            const Text(
              'Forgot Password?',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'If you need help resetting your password, we can help\nby sending you a link to reset it.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFFA9A3AC),
                fontSize: 11,
                height: 1.25,
                fontWeight: FontWeight.w400,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 22),
            LabeledTextField(
              controller: controller.emailController,
              title: 'EMAIL ADDRESS',
              hintText: 'name@email.com',
              prefixIcon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Enter your email';
                }
                if (!GetUtils.isEmail(value.trim())) {
                  return 'Enter a valid email';
                }
                return null;
              },
            ),
            Gap.h16,
            RSaveButton(
              key: const ValueKey('forget-password-save-button'),
              height: 55,
              borderRadius: BorderRadius.circular(28),
              activeGradient: _continueGradient,
              style: const TextStyle(
                color: Color(0xFF113238),
                fontSize: 15,
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
              ),
              saveText: 'Continue',
              loadingText: 'Sending',
              doneText: 'Sent',
              errorText: 'Failed',
              buttonStatusNotifier: controller.processStatusNotifier,
              onSaveTap: () {
                if (!(formKey.currentState?.validate() ?? false)) return;

                controller.forgetPassword(
                  onSuccess: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => OtpVerificationScreen(
                          email: controller.email,
                          mode: OtpMode.forgetPassword,
                        ),
                      ),
                    );
                  },
                );
              },
              onDone: () {},
            ),
          ],
        ),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF1A1A1D),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => Navigator.maybePop(context),
        child: const SizedBox(
          width: 40,
          height: 40,
          child: Icon(Icons.arrow_back, color: Color(0xFFD5D1D8), size: 22),
        ),
      ),
    );
  }
}

class _HelpButton extends StatelessWidget {
  const _HelpButton();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF1A1A1D),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () {},
        child: const SizedBox(
          width: 40,
          height: 40,
          child: Icon(Icons.help_outline, color: Color(0xFFD5D1D8), size: 22),
        ),
      ),
    );
  }
}

class _BackgroundGlow extends StatelessWidget {
  const _BackgroundGlow();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.bottomRight,
          radius: 1.0,
          colors: [Color(0x3338E1E9), Color(0x111B513F), Color(0x000B0B0C)],
          stops: [0, 0.32, 0.72],
        ),
      ),
      child: SizedBox.expand(),
    );
  }
}
