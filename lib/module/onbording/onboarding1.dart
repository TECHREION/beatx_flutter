import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../auth/presentation/screens/login_screen.dart';

class Onboarding1Screen extends StatefulWidget {
  const Onboarding1Screen({super.key});

  @override
  State<Onboarding1Screen> createState() => _Onboarding1ScreenState();
}

class _Onboarding1ScreenState extends State<Onboarding1Screen> {
  late final VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset("assets/logo/3.mp4")
      ..setLooping(false)
      ..setVolume(0)
      ..initialize().then((_) {
        if (!mounted) return;
        setState(() {});
        _controller.play();
      })
      ..addListener(_onVideoTick);
  }

  void _onVideoTick() {
    if (!mounted) return;
    final value = _controller.value;
    if (value.isInitialized &&
        !value.isPlaying &&
        value.position >= value.duration) {
      _controller.removeListener(_onVideoTick);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SizedBox.expand(
        child: _controller.value.isInitialized
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
