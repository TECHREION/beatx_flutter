import 'package:app_pigeon/app_pigeon.dart';
import 'package:get/get.dart';
import '../../app/app_manager.dart';
import '../player/player_controller.dart';
import '../../module/audiobook/services/audio_book_interface.dart';
import '../../module/audiobook/services/audio_book_interface_impl.dart';
import '../../module/auth/services/auth_interface.dart';
import '../../module/auth/services/auth_interface_impl.dart';
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

  Get.put<AppManager>(AppManager());

  Get.put<PlayerController>(PlayerController(), permanent: true);
}
