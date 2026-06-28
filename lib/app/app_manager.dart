import 'dart:async';

import 'package:app_pigeon/app_pigeon.dart';
import 'package:beatx_flutter/module/app_ground.dart';
import 'package:beatx_flutter/module/auth/presentation/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AppManager extends GetxController {
  final AuthorizedPigeon _pigeon;
  AppManager(this._pigeon);

  final authStatus = Rx<AuthStatus>(AuthLoading());

  StreamSubscription<AuthStatus>? _sub;

  @override
  void onInit() {
    super.onInit();
    _sub = _pigeon.authStream.listen(_onAuthChanged);
    _checkAuthNow();
  }

  Future<void> _checkAuthNow() async {
    final auth = await _pigeon.getCurrentAuthRecord();
    if (authStatus.value is AuthLoading) {
      _onAuthChanged(auth != null ? Authenticated(auth: auth) : UnAuthenticated());
    }
  }

  void _onAuthChanged(AuthStatus status) {
    authStatus.value = status;
    debugPrint('[AppManager] auth status → $status');

    if (status is Authenticated) {
      Get.offAll(() => AppGround());
    } else if (status is UnAuthenticated || status is AuthError) {
      Get.offAll(() => const LoginScreen());
    }
    // AuthLoading: stay on splash, do nothing
  }

  @override
  void onClose() {
    _sub?.cancel();
    super.onClose();
  }
}
