import 'package:app_pigeon/app_pigeon.dart';
import 'package:get/get.dart';
import '../../app/app_manager.dart';
import '../player/player_controller.dart';
import '../../module/auth/services/auth_interface.dart';
import '../../module/auth/services/auth_interface_impl.dart';

void internalServiceDI() {
  Get.lazyPut<AuthInterface>(
    () => AuthInterfaceImpl(Get.find<AuthorizedPigeon>()),
    fenix: true,
  );

  Get.put<AppManager>(
    AppManager(Get.find<AuthorizedPigeon>()),
  );

  Get.put<PlayerController>(PlayerController(), permanent: true);
}
