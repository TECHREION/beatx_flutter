import 'package:beatx_flutter/core/common/widget/reactive_button/save_button.dart';
import 'package:beatx_flutter/core/notifiers/snackbar_notifier.dart';
import 'package:beatx_flutter/module/auth/controller/verify_account_view_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../onbording/common/app_logo.dart';

enum OtpMode { emailVerification, forgetPassword }

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({
    super.key,
    required this.email,
    this.onVerified,
    this.mode = OtpMode.forgetPassword,
  });

  final String email;
  final VoidCallback? onVerified;
  final OtpMode mode;

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  late final VerifyOtpController _controller;
  late final List<TextEditingController> _fieldControllers;
  late final List<FocusNode> _focusNodes;
  bool _controllerReady = false;

  static const _buttonGradient = LinearGradient(
    colors: [Color(0xFF9BFF4D), Color(0xFF40DDEB)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  @override
  void initState() {
    super.initState();
    _fieldControllers = List.generate(6, (_) => TextEditingController());
    _focusNodes = List.generate(6, (_) => FocusNode());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controllerReady) return;

    final snackbar = SnackbarNotifier(context: context);
    _controller = widget.mode == OtpMode.emailVerification
        ? VerifyEmailOtpController(email: widget.email, snackbarNotifier: snackbar)
        : VerifyForgetPasswordOtpController(email: widget.email, snackbarNotifier: snackbar);
    _controllerReady = true;
  }

  @override
  void dispose() {
    if (_controllerReady) {
      _controller.dispose();
    }
    for (final controller in _fieldControllers) {
      controller.dispose();
    }
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _onDigitChanged(String value, int index) {
    if (value.length > 1) {
      _applyPastedOtp(value);
      return;
    }

    _syncOtp();
    if (value.isNotEmpty && index < _focusNodes.length - 1) {
      _focusNodes[index + 1].requestFocus();
    }
  }

  void _onBackspace(int index, KeyEvent event) {
    if (event is! KeyDownEvent ||
        event.logicalKey != LogicalKeyboardKey.backspace) {
      return;
    }
    if (_fieldControllers[index].text.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  void _applyPastedOtp(String value) {
    final digits = value
        .replaceAll(RegExp(r'\D'), '')
        .split('')
        .take(6)
        .toList();
    for (var i = 0; i < _fieldControllers.length; i++) {
      _fieldControllers[i].text = i < digits.length ? digits[i] : '';
    }
    _syncOtp();
    final nextIndex = digits.length.clamp(0, _focusNodes.length - 1);
    _focusNodes[nextIndex].requestFocus();
  }

  void _syncOtp() {
    _controller.otp = _fieldControllers
        .map((controller) => controller.text)
        .join();
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
                  child: _OtpCard(
                    controller: _controller,
                    fieldControllers: _fieldControllers,
                    focusNodes: _focusNodes,
                    onDigitChanged: _onDigitChanged,
                    onBackspace: _onBackspace,
                    onVerified: widget.onVerified,
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

class _OtpCard extends StatelessWidget {
  const _OtpCard({
    required this.controller,
    required this.fieldControllers,
    required this.focusNodes,
    required this.onDigitChanged,
    required this.onBackspace,
    required this.onVerified,
  });

  final VerifyOtpController controller;
  final List<TextEditingController> fieldControllers;
  final List<FocusNode> focusNodes;
  final void Function(String value, int index) onDigitChanged;
  final void Function(int index, KeyEvent event) onBackspace;
  final VoidCallback? onVerified;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 22),
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AppLogo(height: 72, width: 180),
          Text.rich(
            TextSpan(
              text: 'Welcome to BEAT',
              children: [
                TextSpan(
                  text: 'X',
                  style: TextStyle(
                    color: const Color(0xFFD27BFF),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            style: const TextStyle(
              color: Color(0xFFC6C0C8),
              fontSize: 13,
              fontWeight: FontWeight.w500,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 28),
          const Text(
            'Otp Verification',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Please check your email and enter the 6 digit\nverification code to continue.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFFA9A3AC),
              fontSize: 11,
              height: 1.35,
              fontWeight: FontWeight.w400,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 28),
          _OtpFields(
            controllers: fieldControllers,
            focusNodes: focusNodes,
            onDigitChanged: onDigitChanged,
            onBackspace: onBackspace,
          ),
          const SizedBox(height: 30),
          RSaveButton(
            key: const ValueKey('otp-verify-save-button'),
            height: 55,
            borderRadius: BorderRadius.circular(28),
            activeGradient: _EmailVerificationScreenState._buttonGradient,
            style: const TextStyle(
              color: Color(0xFF113238),
              fontSize: 15,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
            saveText: 'Verify Now',
            loadingText: 'Verifying',
            doneText: 'Verified',
            errorText: 'Failed',
            buttonStatusNotifier: controller.prcessNotifier,
            onSaveTap: controller.verify,
            onDone: () {
              if (onVerified != null) {
                onVerified!();
              } else {
                Navigator.maybePop(context);
              }
            },
          ),
          const SizedBox(height: 18),
          _ResendButton(controller: controller),
        ],
      ),
    );
  }
}

class _OtpFields extends StatelessWidget {
  const _OtpFields({
    required this.controllers,
    required this.focusNodes,
    required this.onDigitChanged,
    required this.onBackspace,
  });

  final List<TextEditingController> controllers;
  final List<FocusNode> focusNodes;
  final void Function(String value, int index) onDigitChanged;
  final void Function(int index, KeyEvent event) onBackspace;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(controllers.length, (index) {
        return Focus(
          onKeyEvent: (node, event) {
            onBackspace(index, event);
            return KeyEventResult.ignored;
          },
          child: SizedBox(
            width: 38,
            height: 46,
            child: TextField(
              controller: controllers[index],
              focusNode: focusNodes[index],
              keyboardType: TextInputType.number,
              textInputAction: index == controllers.length - 1
                  ? TextInputAction.done
                  : TextInputAction.next,
              textAlign: TextAlign.center,
              maxLength: 1,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: 0,
              ),
              decoration: InputDecoration(
                counterText: '',
                filled: true,
                fillColor: const Color(0xFF1B1B1C),
                contentPadding: EdgeInsets.zero,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(23),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(23),
                  borderSide: const BorderSide(
                    color: Color(0xFF4ADDE8),
                    width: 1.5,
                  ),
                ),
              ),
              onChanged: (value) => onDigitChanged(value, index),
            ),
          ),
        );
      }),
    );
  }
}

class _ResendButton extends StatefulWidget {
  const _ResendButton({required this.controller});
  final VerifyOtpController controller;

  @override
  State<_ResendButton> createState() => _ResendButtonState();
}

class _ResendButtonState extends State<_ResendButton> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_rebuild);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_rebuild);
    super.dispose();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final emailCtrl = widget.controller is VerifyEmailOtpController
        ? widget.controller as VerifyEmailOtpController
        : null;

    if (emailCtrl == null) return const SizedBox.shrink();

    final canResend = emailCtrl.canResend;
    final secondsLeft = emailCtrl.resendSecondsLeft;

    return TextButton(
      onPressed: canResend ? emailCtrl.resendOtp : null,
      style: TextButton.styleFrom(
        foregroundColor: const Color(0xFF40DDEB),
        disabledForegroundColor: const Color(0xFF555558),
        minimumSize: Size.zero,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
        canResend ? 'Resend Code' : 'Resend in ${secondsLeft}s',
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
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
