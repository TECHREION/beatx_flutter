import 'package:app_pigeon/app_pigeon.dart';
import 'package:get/get.dart';

import '../model/watch_model.dart';
import '../services/watch_interface.dart';
import '../services/watch_interface_impl.dart';

class WatchController extends GetxController {
  final home = Rx<HomeData?>(null);
  final isLoading = true.obs;
  final errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchHome();
  }

  VideoInterface _videoInterface() {
    if (!Get.isRegistered<VideoInterface>() &&
        Get.isRegistered<AuthorizedPigeon>()) {
      Get.put<VideoInterface>(
        VideoInterfaceImpl(Get.find<AuthorizedPigeon>()),
      );
    }
    return Get.find<VideoInterface>();
  }

  Future<void> fetchHome() async {
    isLoading.value = true;
    errorMessage.value = '';

    final result = await _videoInterface().videoHome();

    result.fold(
      (failure) => errorMessage.value = failure.uiMessage,
      (success) => home.value = success.data,
    );

    isLoading.value = false;
  }

  VideoModel? get featuredVideo =>
      home.value?.featured.isNotEmpty == true ? home.value!.featured.first : null;

  List<VideoModel> get trendingVideos => home.value?.recent ?? const [];
}
