import 'dart:async';

import 'package:app_pigeon/app_pigeon.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';

import '../module/app_ground.dart';
import '../module/auth/presentation/screens/login_screen.dart';
import 'app_manager.dart';

/// The launch screen: the intro clip playing full-bleed, then straight into
/// wherever the current sign-in belongs.
///
/// [AppManager] holds its own routing back while this is on screen (see
/// [AppManager.markSplashFinished]) so the auth stream cannot cut the clip off
/// part-way through.
class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> {
  static const _videoAsset = 'assets/logo/3.mp4';

  /// Longest the launch screen may hold the app, whatever the clip does. A
  /// file that will not decode, or a device that stalls on it, must not leave
  /// someone staring at a black screen.
  static const _maxHold = Duration(seconds: 12);

  late final VideoPlayerController _controller;
  Timer? _failsafe;
  bool _handedOff = false;

  @override
  void initState() {
    super.initState();
    _failsafe = Timer(_maxHold, _handOff);
    _controller = VideoPlayerController.asset(_videoAsset)
      ..setLooping(false)
      ..setVolume(0)
      ..addListener(_onTick);

    _controller.initialize().then(
      (_) {
        if (!mounted) return;
        setState(() {});
        _controller.play();
      },
      onError: (Object error, StackTrace stackTrace) {
        debugPrint('splash video failed to open: $error\n$stackTrace');
        _handOff();
      },
    );
  }

  void _onTick() {
    final video = _controller.value;
    if (video.hasError) {
      debugPrint('splash video errored: ${video.errorDescription}');
      _handOff();
      return;
    }
    // Played itself out — the clip does not loop, so this fires once.
    if (video.isInitialized &&
        !video.isPlaying &&
        video.duration > Duration.zero &&
        video.position >= video.duration) {
      _handOff();
    }
  }

  /// Leaves the launch screen. Runs once: the clip ending, a decode failure
  /// and [_failsafe] can all reach it.
  void _handOff() {
    if (_handedOff || !mounted) return;
    _handedOff = true;
    _failsafe?.cancel();
    _controller.removeListener(_onTick);

    final appManager = Get.find<AppManager>();
    final authenticated = appManager.currentAuthStatus is Authenticated;

    // Routes the launch itself and lets AppManager move freely from here on;
    // AppManager drops the decision this just carried out. Signed-out
    // listeners go straight to sign-in rather than through the intro screen,
    // which would play this same clip over again.
    appManager.markSplashFinished();
    Get.offAll(() => authenticated ? AppGround() : const LoginScreen());
  }

  @override
  void dispose() {
    _failsafe?.cancel();
    _controller.removeListener(_onTick);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SizedBox.expand(
        child: _controller.value.isInitialized
            // Cover rather than contain: the clip fills the screen edge to
            // edge instead of sitting in letterbox bars.
            ? FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _controller.value.size.width,
                  height: _controller.value.size.height,
                  child: VideoPlayer(_controller),
                ),
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}
