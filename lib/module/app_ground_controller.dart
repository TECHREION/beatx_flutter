import 'package:get/get.dart';

/// The destinations along the bottom of [AppGround], in the order they sit
/// in the bar.
enum AppTab { listen, watch, podcast, audiobook, shop }

/// Which destination the shell is showing.
///
/// Shared rather than kept by the shell itself so anything inside a tab can
/// move to another one — the home screen's Shop, Podcasts and Audiobooks
/// tiles switch destination this way instead of pushing a second copy of a
/// section on top of the nav bar.
class AppGroundController extends GetxController {
  /// The shared instance, registered on first use.
  static AppGroundController get instance {
    if (!Get.isRegistered<AppGroundController>()) {
      Get.put(AppGroundController(), permanent: true);
    }
    return Get.find<AppGroundController>();
  }

  final currentIndex = 0.obs;

  AppTab get currentTab => AppTab.values[currentIndex.value];

  void goTo(AppTab tab) => currentIndex.value = tab.index;

  /// Ignores an index no destination answers to, so a bad caller leaves the
  /// shell on the tab it was already showing rather than crashing it.
  void goToIndex(int index) {
    if (index < 0 || index >= AppTab.values.length) return;
    currentIndex.value = index;
  }
}
