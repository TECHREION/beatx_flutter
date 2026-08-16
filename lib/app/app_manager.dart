// import 'dart:async';

// import 'package:app_pigeon/app_pigeon.dart';
// import 'package:beatx_flutter/module/app_ground.dart';
// import 'package:beatx_flutter/module/auth/presentation/screens/login_screen.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';

// class AppManager extends GetxController {
//   final AuthorizedPigeon _pigeon;
//   AppManager(this._pigeon);

//   final authStatus = Rx<AuthStatus>(AuthLoading());

//   StreamSubscription<AuthStatus>? _sub;

//   @override
//   void onInit() {
//     super.onInit();
//     _sub = _pigeon.authStream.listen(_onAuthChanged);
//     _checkAuthNow();
//   }

//   Future<void> _checkAuthNow() async {
//     final auth = await _pigeon.getCurrentAuthRecord();
//     if (authStatus.value is AuthLoading) {
//       _onAuthChanged(auth != null ? Authenticated(auth: auth) : UnAuthenticated());
//     }
//   }

//   void _onAuthChanged(AuthStatus status) {
//     authStatus.value = status;
//     debugPrint('[AppManager] auth status → $status');

//     if (status is Authenticated) {
//       Get.offAll(() => AppGround());
//     } else if (status is UnAuthenticated || status is AuthError) {
//       Get.offAll(() => const LoginScreen());
//     }
//     // AuthLoading: stay on splash, do nothing
//   }

//   @override
//   void onClose() {
//     _sub?.cancel();
//     super.onClose();
//   }
// }
import 'dart:async';
import 'package:app_pigeon/app_pigeon.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_rx/src/rx_workers/utils/debouncer.dart';
import '../core/constants/api_endpoints.dart';
import '../core/helpers/auth_role.dart';
import '../module/app_ground.dart';
import '../module/auth/controller/login_controller.dart';
import '../module/onbording/onboarding1.dart';
import '../module/profile/controller/get_profile_controller.dart';
import '../module/profile/controller/settings_controller.dart';

class AppManager extends GetxController {
  AuthStatus _authStatus = AuthLoading();
  AuthStatus get currentAuthStatus => _authStatus;
  Debouncer authDebouncer = Debouncer(delay: const Duration(milliseconds: 100));

  /// Socket connection status
  final RxBool socketConnected = false.obs;

  StreamSubscription<dynamic>? _socketConnectSub;
  StreamSubscription<dynamic>? _socketDisconnectSub;
  StreamSubscription<dynamic>? _socketErrorSub;

  /// Initializes the stream to listen to auth status
  AppManager() {
    _init();
  }

  // listen to auth change
  void _init() async {
    debugPrint("AppManager initialized");

    // await Get.find<AuthorizedPigeon>().getCurrentAuthRecord().then((initialAuthStatus) {
    //   _decideRoute(initialAuthStatus);
    // });

    // Start listening to the auth status changes
    Get.find<AuthorizedPigeon>().authStream.listen((authStatus) {
      _decideRoute(authStatus);
    });
  }

  void _decideRoute(AuthStatus? authStatus) async {
    if (authStatus is UnAuthenticated) {
      _authStatus = authStatus;
      if (Get.isRegistered<LoginController>()) {
        Get.delete<LoginController>(force: true);
      }
      Get.offAll(() => Onboarding1Screen());
      // navigatorKey.currentState?.pushNamedAndRemoveUntil(
      //   RouteNames.login,
      //   (route) => false,
      // );
    } else if (authStatus is Authenticated) {
      debugPrint(
        "currentAuthStatus: $_authStatus, beforeAuthStatus: $authStatus",
      );
      debugPrint(
        "New auth:: ${!(currentAuthStatus is Authenticated && (authStatus).auth.userId != (currentAuthStatus as Authenticated).auth.userId)}",
      );
      _authStatus = authStatus;
      await _initializeControllers();
      if (Get.isRegistered<ProfileController>()) {
        Get.delete<ProfileController>();
      }
      Get.put(ProfileController());

      // Dropped with the profile, so the settings screens do not open on the
      // previous user's switches.
      if (Get.isRegistered<SettingsController>()) {
        Get.delete<SettingsController>();
      }
      Get.put(SettingsController());

      Get.offAll(() => AppGround());

      // navigatorKey.currentState?.pushNamedAndRemoveUntil(
      //   RouteNames.home,
      //   (route) => false,
      // );
    }
    update();
    // if (authStatus != null && authStatus != _authStatus) {
    //   debugPrint("(In Appmanager)Auth status: $authStatus");

    // }
  }

  // initiate controllers on auth change[Authenticated]
  Future<void> _initializeControllers() async {
    if ((currentAuthStatus as Authenticated).auth.userId.isNotEmpty) {
      final userId = (currentAuthStatus as Authenticated).auth.userId;

      await Get.find<AppPigeon>()
          .socketInit(
            SocketConnetParamX(
              token: null,
              socketUrl: ApiEndpoints.socketUrl,
              joinId: userId,
            ),
          )
          .then((_) async {
            final appPigeon = Get.find<AppPigeon>();
            appPigeon.emit("joinChatRoom", userId);
            // Keep notification sockets ready as soon as auth socket is live.
            appPigeon.emit("joinNotificationRoom", userId);
            appPigeon.emit("joinNotification", userId);
            _bindSocketStatus();
            // Get.find<NotificationController>();
            // if (Get.isRegistered<AppGlobalControllers>()) {
            //   await Get.delete<AppGlobalControllers>();
            // }

            // Get.put<AppGlobalControllers>(
            //   AppGlobalControllers(),
            // );
          });
    }
  }

  void _bindSocketStatus() {
    _socketConnectSub?.cancel();
    _socketDisconnectSub?.cancel();
    _socketErrorSub?.cancel();

    final appPigeon = Get.find<AppPigeon>();
    _socketConnectSub = appPigeon.listen("connect").listen((_) {
      socketConnected.value = true;
    });
    _socketDisconnectSub = appPigeon.listen("disconnect").listen((_) {
      socketConnected.value = false;
    });
    _socketErrorSub = appPigeon.listen("connect_error").listen((_) {
      socketConnected.value = false;
    });
  }

  @override
  void onClose() {
    _socketConnectSub?.cancel();
    _socketDisconnectSub?.cancel();
    _socketErrorSub?.cancel();
    super.onClose();
  }
}
// class AppManager extends GetxController {
//   AuthStatus _authStatus = AuthLoading();
//   AuthStatus get currentAuthStatus => _authStatus;

//   final Debouncer authDebouncer =
//       Debouncer(delay: const Duration(milliseconds: 100));

//   @override
//   void onInit() {
//     super.onInit();
//     _init();
//   }

//   Future<void> _init() async {
//     debugPrint("AppManager initialized");

//     final initialAuthStatus =
//         await Get.find<AppPigeon>().currentAuth();

//     // ✅ WAIT until UI is ready
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       _decideRoute(initialAuthStatus);
//     });
//   }

//   Future<void> _decideRoute(AuthStatus? authStatus) async {
//     if (authStatus is UnAuthenticated) {
//       _authStatus = authStatus;

//       Get.offAll(() => SignupScreen());

//     } else if (authStatus is Authenticated) {
//       _authStatus = authStatus;

//       await _initializeControllers();

//       if (Get.isRegistered<ProfileController>()) {
//         Get.delete<ProfileController>();
//       }

//       Get.put(ProfileController());

//       Get.offAll(() => AppGround());
//     }

//     update();
//   }

//   Future<void> _initializeControllers() async {
//     if (_authStatus is! Authenticated) return;

//     final userId =
//         (_authStatus as Authenticated).auth.userId;

//     if (userId.isEmpty) return;

//     await Get.find<AppPigeon>().socketInit(
//       SocketConnetParamX(
//         token: null,
//         socketUrl: ApiEndpoints.socketUrl,
//         joinId: userId,
//       ),
//     );

//     Get.find<AppPigeon>().emit("join", userId);
//   }
// }