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
import '../module/audiobook/controller/liked_audiobooks_controller.dart';
import '../module/home/controller/liked_songs_controller.dart';
import '../module/podcast/controller/liked_podcasts_controller.dart';
import '../module/profile/controller/get_profile_controller.dart';
import '../module/profile/controller/settings_controller.dart';

class AppManager extends GetxController {
  AuthStatus _authStatus = AuthLoading();
  AuthStatus get currentAuthStatus => _authStatus;
  Debouncer authDebouncer = Debouncer(delay: const Duration(milliseconds: 100));

  /// Socket connection status
  final RxBool socketConnected = false.obs;

  /// Held closed while the launch clip is on screen. Auth usually resolves in
  /// well under a second, and without this the stream's opening event would
  /// route the app away before the clip had played a frame.
  ///
  /// [SplashView] opens it — and routes the launch itself — once the clip is
  /// done. The timeout is a backstop for a build where no launch screen runs.
  final _splashFinished = Completer<void>();

  Future<void> get _splashGate => _splashFinished.future.timeout(
    const Duration(seconds: 15),
    onTimeout: () {},
  );

  /// Set when the launch screen has already routed the decision that is
  /// parked on [_splashGate], so it is not acted on twice.
  bool _launchRouteHandled = false;

  /// Called by [SplashView] when it has finished with the launch clip and has
  /// routed the app itself.
  void markSplashFinished() {
    // Only a status that has already arrived has a route waiting on the gate
    // for the launch screen to have pre-empted. If none has, the launch screen
    // fell back to sign-in and whatever arrives later still needs routing.
    _launchRouteHandled = _authStatus is! AuthLoading;
    if (!_splashFinished.isCompleted) _splashFinished.complete();
  }

  /// True once, for the decision the launch screen already carried out.
  bool _launchScreenAlreadyRouted() {
    if (!_launchRouteHandled) return false;
    _launchRouteHandled = false;
    return true;
  }

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
      await _splashGate;
      if (_launchScreenAlreadyRouted()) return;
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

      _refreshLikedCollections();

      await _splashGate;
      if (_launchScreenAlreadyRouted()) return;
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

  /// Reloads the liked collections against the account that just signed in.
  ///
  /// They are registered `permanent`, so they outlive the sign-out that came
  /// before this and would otherwise still be holding the previous user's
  /// likes — or the failure their first fetch met while there was no token to
  /// send. Only the ones already registered are touched; the rest fetch on
  /// first use, which is now after this point.
  void _refreshLikedCollections() {
    if (Get.isRegistered<LikedSongsController>()) {
      LikedSongsController.instance.fetch();
    }
    if (Get.isRegistered<LikedPodcastsController>()) {
      LikedPodcastsController.instance.fetch();
    }
    if (Get.isRegistered<LikedAudiobooksController>()) {
      LikedAudiobooksController.instance.fetch();
    }
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