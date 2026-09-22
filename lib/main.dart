import 'package:audio_service/audio_service.dart';
import 'package:beatx_flutter/core/di/external_service_di.dart';
import 'package:beatx_flutter/core/di/internal_service_di.dart';
import 'package:beatx_flutter/app/splash_view.dart';
import 'package:beatx_flutter/core/player/beatx_audio_handler.dart';
import 'package:beatx_flutter/core/player/player_controller.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  externalServiceDI();
  internalServiceDI();

  // Must run after internalServiceDI, which registers the PlayerController the
  // handler wraps. A failure here costs the notification controls, not
  // playback, so it must not block startup.
  try {
    await AudioService.init(
      builder: () => BeatxAudioHandler(Get.find<PlayerController>()),
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.example.beatx_flutter.audio',
        androidNotificationChannelName: 'BeatX playback',
        androidNotificationOngoing: true,
        androidStopForegroundOnPause: true,
      ),
    );
  } catch (error, stackTrace) {
    if (kDebugMode) {
      debugPrint('AudioService.init failed: $error\n$stackTrace');
    }
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'BeatX',
      debugShowCheckedModeBanner: false,
      scrollBehavior: const ScrollBehavior().copyWith(scrollbars: false),
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0B0B0C),
      ),
      home: const SplashView(),
    );
  }
}
