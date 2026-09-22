import 'dart:io' show Platform;

import 'package:app_pigeon/app_pigeon.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:get/get.dart';
import '../../app/app_manager.dart';
import '../player/equalizer/equalizer_controller.dart';
import '../player/equalizer/equalizer_service.dart';
import '../player/equalizer/equalizer_service_impl.dart';
import '../player/equalizer/equalizer_service_ios.dart';
import '../player/player_controller.dart';
import '../../module/audiobook/services/audio_book_interface.dart';
import '../../module/audiobook/services/audio_book_interface_impl.dart';
import '../../module/auth/services/auth_interface.dart';
import '../../module/auth/services/auth_interface_impl.dart';
import '../../module/notification/services/notification_interface.dart';
import '../../module/notification/services/notification_interface_impl.dart';
import '../../module/watch/services/watch_interface.dart';
import '../../module/watch/services/watch_interface_impl.dart';

void internalServiceDI() {
  Get.lazyPut<AuthInterface>(
    () => AuthInterfaceImpl(Get.find<AuthorizedPigeon>()),
    fenix: true,
  );

  Get.lazyPut<AudioBookInterface>(
    () => AudioBookInterfaceImpl(Get.find<AuthorizedPigeon>()),
    fenix: true,
  );

  Get.lazyPut<VideoInterface>(
    () => VideoInterfaceImpl(Get.find<AuthorizedPigeon>()),
    fenix: true,
  );

  Get.lazyPut<NotificationInterface>(
    () => NotificationInterfaceImpl(Get.find<AuthorizedPigeon>()),
    fenix: true,
  );

  Get.put<AppManager>(AppManager());

  Get.put<PlayerController>(PlayerController(), permanent: true);

  // Must come after PlayerController: on Android just_audio fixes a player's
  // audio effects at construction time, so the equalizer effect belongs to the
  // player and the service reads it from there rather than creating its own.
  //
  // The two platforms use entirely different DSP paths — audiofx on ExoPlayer's
  // session vs an AUNBandEQ inside an MTAudioProcessingTap — but both sit
  // behind EqualizerService, so nothing above this line is platform-aware.
  Get.put<EqualizerService>(_equalizerService(), permanent: true);

  Get.put<EqualizerController>(
    EqualizerController(service: Get.find<EqualizerService>()),
    permanent: true,
  );
}

EqualizerService _equalizerService() {
  if (kIsWeb)
    return EqualizerServiceImpl(Get.find<PlayerController>().androidEqualizer);
  if (Platform.isIOS) return IosEqualizerService();
  return EqualizerServiceImpl(Get.find<PlayerController>().androidEqualizer);
}
