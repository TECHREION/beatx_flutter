import 'package:beatx_flutter/core/common/widget/reactive_button/save_button.dart';
import 'package:beatx_flutter/core/notifiers/snackbar_notifier.dart';
import 'package:beatx_flutter/module/auth/presentation/screens/forget_password_screen.dart';
import 'package:beatx_flutter/module/auth/presentation/screens/email_verify_screen.dart';
import 'package:beatx_flutter/module/auth/presentation/screens/signup_screen.dart';
import 'package:beatx_flutter/module/auth/presentation/widget/social_auth_buttons.dart';
import 'package:beatx_flutter/module/auth/presentation/widget/textfield.dart';
import 'package:beatx_flutter/module/app_ground.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_gap.dart';
import '../../../onbording/common/app_logo.dart';
import '../../controller/login_controller.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  late final LoginController _controller;
  late final bool _ownsController;

  @override
  void initState() {
    super.initState();
    _ownsController = !Get.isRegistered<LoginController>();
    _controller = _ownsController
        ? Get.put(LoginController())
        : Get.find<LoginController>();
  }

  @override
  void dispose() {
    if (_ownsController && Get.isRegistered<LoginController>()) {
      Get.delete<LoginController>();
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
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(32, 16, 32, 70),
                  child: _LoginCard(formKey: _formKey, controller: _controller),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoginCard extends StatelessWidget {
  const _LoginCard({required this.formKey, required this.controller});

  final GlobalKey<FormState> formKey;
  final LoginController controller;
  static const _loginGradient = LinearGradient(
    colors: [Color(0xFF9BFF4D), Color(0xFF40DDEB)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 34, 16, 22),
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
            Gap.h32,
            LabeledTextField(
              title: 'EMAIL ADDRESS',
              hintText: "name@email.com",
              prefixIcon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              onChanged: controller.setEmail,
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
            LabeledTextField(
              title: 'PASSWORD',
              hintText: '••••••••',
              prefixIcon: Icons.lock_outline,
              isPassword: true,
              onChanged: controller.setPassword,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Enter your password';
                }
                if (value.length < 6) {
                  return 'Password must be at least 6 characters';
                }
                return null;
              },
            ),
            Gap.h16,
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ForgetPasswordScreen(),
                      ),
                    );
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFCFCBD1),
                    minimumSize: Size.zero,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Forgot Password?',
                    style: TextStyle(
                      color: Color(0xFFCFCBD1),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0,
                    ),
                  ),
                ),
              ],
            ),
            Gap.h16,
            RSaveButton(
              key: const ValueKey('login-save-button'),
              height: 55,
              borderRadius: BorderRadius.circular(28),
              activeGradient: _loginGradient,
              style: const TextStyle(
                color: Color(0xFF111113),
                fontSize: 15,
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
              ),
              saveText: 'Log In',
              loadingText: 'Logging In',
              doneText: 'Logged In',
              errorText: 'Log In Failed',
              buttonStatusNotifier: controller.processNotifier,
              onSaveTap: () {
                if (!(formKey.currentState?.validate() ?? false)) return;
                controller.login(
                  buttonNotifier: controller.processNotifier,
                  snackbarNotifier: SnackbarNotifier(context: context),
                  needVerifyAccount: () {
                    controller.resendVerificationOtp(
                      snackbarNotifier: SnackbarNotifier(context: context),
                      onSent: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => EmailVerificationScreen(
                              email: controller.email.value,
                              mode: OtpMode.emailVerification,
                              onVerified: () {
                                Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => AppGround(),
                                  ),
                                  (route) => false,
                                );
                              },
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
              onDone: () {
                // Navigator.pushAndRemoveUntil(
                //   context,
                //   MaterialPageRoute(builder: (_) => AppGround()),
                //   (route) => false,
                // );
              },
            ),
            Gap.h16,
            const _ConnectDivider(),
            const SizedBox(height: 19),
            const SocialAuthButtons(),
            const SizedBox(height: 19),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SignupScreen()),
                );
              },
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFCFCBD1),
                minimumSize: Size.zero,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text.rich(
                TextSpan(
                  text: 'New to BeatX? ',
                  style: const TextStyle(
                    color: Color(0xFFCFCBD1),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0,
                  ),
                  children: [
                    TextSpan(
                      text: 'Register Now',
                      style: TextStyle(
                        color: Color(0xFFD27BFF),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConnectDivider extends StatelessWidget {
  const _ConnectDivider();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(child: Divider(color: Color(0xFF202022), thickness: 2)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 13),
          child: Text(
            'OR CONNECT WITH',
            style: TextStyle(
              color: Color(0xFFB3AEB6),
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
          ),
        ),
        Expanded(child: Divider(color: Color(0xFF202022), thickness: 2)),
      ],
    );
  }
}
