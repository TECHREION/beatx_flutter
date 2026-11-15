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
import '../core/helpers/onboarding_gate.dart';
import '../core/player/player_controller.dart';
import '../core/network/notification_socket.dart';
import '../module/auth/presentation/screens/select_artist_screen.dart';
import '../module/notification/controller/notification_controller.dart';
import '../module/app_ground.dart';
import '../module/auth/controller/login_controller.dart';
import '../module/onbording/onboarding1.dart';
import '../module/audiobook/controller/liked_audiobooks_controller.dart';
import '../module/home/controller/download_controller.dart';
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

  /// Live notifications; connected while signed in.
  NotificationSocket? _notificationSocket;

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
      _disconnectSocket();
      OnboardingGate.clear();
      // A signed-out app keeps nothing playing from the previous account;
      // stopping also hides the mini player.
      if (Get.isRegistered<PlayerController>()) {
        unawaited(Get.find<PlayerController>().stop());
      }
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

      // Not awaited: offline this fails quietly, and it must not hold up
      // opening the app.
      unawaited(DownloadController.instance.syncWithServer());

      // Taken before the splash gate: a fresh sign-in reports whether the
      // listener still has to pick artists/genres.
      final needsOnboarding = OnboardingGate.takePending();

      await _splashGate;
      if (_launchScreenAlreadyRouted()) return;
      if (needsOnboarding) {
        Get.offAll(
          () => InterestSelectionScreen(
            onContinue: () => Get.offAll(() => AppGround()),
          ),
        );
      } else {
        Get.offAll(() => AppGround());
      }

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
    _connectSocket();
  }

  /// Opens the live notification socket (`/notifications` namespace,
  /// `auth: {token}`). New notifications go straight into the shared feed.
  void _connectSocket() {
    final pigeon = Get.find<AuthorizedPigeon>();
    final socket = _notificationSocket ??= NotificationSocket(
      origin: ApiEndpoints.socketUrl,
      path: ApiEndpoints.socketPath,
      accessToken: () async =>
          (await pigeon.getCurrentAuthRecord())?.toJson()['access_token']
              as String?,
    );
    socket.connect(
      onNotification: (payload) =>
          NotificationController.instance.onPushed(payload),
      onConnectionChanged: (connected) => socketConnected.value = connected,
      // Anything sent while the connection was down is only in the history.
      onReconnected: () => NotificationController.instance.fetch(),
    );
  }

  void _disconnectSocket() {
    _notificationSocket?.disconnect();
    socketConnected.value = false;
  }

  @override
  void onClose() {
    _disconnectSocket();
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
