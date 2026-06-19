import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../../core/helpers/handle_fold.dart';
import '../../../core/notifiers/button_status_notifier.dart';
import '../../../core/notifiers/snackbar_notifier.dart';
import '../model/verify_otp_param.dart';
import '../services/auth_interface.dart';

abstract class VerifyOtpController extends ChangeNotifier {
  final AuthInterface authInterface = Get.find<AuthInterface>();
  final ProcessStatusNotifier prcessNotifier = ProcessStatusNotifier(
    initialStatus: DisabledStatus(),
  );

  final SnackbarNotifier snackbarNotifier;
  final String email;

  VerifyOtpController({required this.email, required this.snackbarNotifier});

  int otpLength = 6;
  String _otp = "";

  String get otp => _otp;

  set otp(String value) {
    _otp = value;
    debugPrint("Current OTP → $_otp");

    if (_otp.length == otpLength) {
      prcessNotifier.setEnabled();
    } else {
      prcessNotifier.setDisabled();
    }
  }

  void verify();
}

class VerifyEmailOtpController extends VerifyOtpController {
  VerifyEmailOtpController({
    required super.email,
    required super.snackbarNotifier,
  }) {
    _startCountdown();
  }

  static const _resendCooldown = 60;

  int resendSecondsLeft = _resendCooldown;
  bool get canResend => resendSecondsLeft == 0;
  bool isResending = false;

  Timer? _countdownTimer;

  void _startCountdown() {
    resendSecondsLeft = _resendCooldown;
    notifyListeners();
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (resendSecondsLeft > 0) {
        resendSecondsLeft--;
        notifyListeners();
      } else {
        t.cancel();
      }
    });
  }

  Future<void> resendOtp() async {
    if (!canResend || isResending) return;
    isResending = true;
    notifyListeners();

    final result = await authInterface.resendEmailOtp(email);

    result.fold(
      (err) => snackbarNotifier.notifyError(message: err.uiMessage),
      (success) {
        snackbarNotifier.notifySuccess(message: success.message);
        _startCountdown();
      },
    );

    isResending = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  void verify() async {
    if (prcessNotifier.status is LoadingStatus) return;

    prcessNotifier.setLoading();

    final result = await authInterface.verifyEmail(
      VerifyOtpParam(email: email, otp: otp),
    );

    handleFold(
      either: result,
      processStatusNotifier: prcessNotifier,
      successSnackbarNotifier: snackbarNotifier,
      errorSnackbarNotifier: snackbarNotifier,
    );

    result.fold(
      (err) => prcessNotifier.setError(),
      (success) => prcessNotifier.setSuccess(),
    );
  }
}

class VerifyForgetPasswordOtpController extends VerifyOtpController {
  VerifyForgetPasswordOtpController({
    required super.email,
    required super.snackbarNotifier,
  });

  @override
  void verify() async {
    if (prcessNotifier.status is LoadingStatus) return;

    debugPrint("Verifying OTP for email: $email");

    prcessNotifier.setLoading();

    final result = await authInterface.verifyCode(
      VerifyOtpParam(email: email, otp: otp),
    );

    handleFold(
      either: result,
      processStatusNotifier: prcessNotifier,
      successSnackbarNotifier: snackbarNotifier,
      errorSnackbarNotifier: snackbarNotifier,
    );

    // 🔥 REQUIRED: Mark as Done so button triggers onDone
    result.fold(
      (err) => prcessNotifier.setError(),
      (success) => prcessNotifier.setSuccess(),
    );
  }
}
