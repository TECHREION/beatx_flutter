import 'package:app_pigeon/app_pigeon.dart';
import 'package:get/get.dart';

import '../model/watch_model.dart';
import '../services/watch_interface.dart';
import '../services/watch_interface_impl.dart';
import 'music_player_controller.dart';

/// The videos the signed-in user has liked, behind `GET /videos/liked`.
///
/// Shared rather than screen-scoped so the Watch screen's button can show the
/// count without the liked screen being open, and so a like made on the video
/// page shows up here.
class LikedVideosController extends GetxController {
  /// The shared instance, registered on first use.
  static LikedVideosController get instance {
    if (!Get.isRegistered<LikedVideosController>()) {
      Get.put(LikedVideosController(), permanent: true);
    }
    return Get.find<LikedVideosController>();
  }

  final videos = <VideoModel>[].obs;
  final isLoading = false.obs;
  final errorMessage = ''.obs;

  /// False until a fetch has come back, so the count can be held back rather
  /// than shown as a zero that only means "not asked yet".
  final hasLoaded = false.obs;

  /// Videos with an unlike in flight, kept out of the way of a second tap.
  final unliking = <String>{}.obs;

  @override
  void onInit() {
    super.onInit();
    fetch();
  }

  VideoInterface _videoInterface() {
    if (!Get.isRegistered<VideoInterface>() &&
        Get.isRegistered<AuthorizedPigeon>()) {
      Get.put<VideoInterface>(VideoInterfaceImpl(Get.find<AuthorizedPigeon>()));
    }
    return Get.find<VideoInterface>();
  }

  bool isLiked(String videoId) => videos.any((video) => video.id == videoId);

  Future<void>? _inFlight;

  /// Reloads the list. A second caller joins the fetch already running.
  Future<void> fetch() =>
      _inFlight ??= _fetch().whenComplete(() => _inFlight = null);

  Future<void> _fetch() async {
    isLoading.value = true;
    errorMessage.value = '';

    final result = await _videoInterface().getLikedVideos();

    result.fold(
      (failure) => errorMessage.value = failure.uiMessage,
      (success) => videos.assignAll(success.data ?? const []),
    );

    hasLoaded.value = true;
    isLoading.value = false;
  }

  /// Removes [video] from the user's likes and drops it from the list.
  Future<void> unlike(VideoModel video) async {
    if (unliking.contains(video.id)) return;

    unliking.add(video.id);
    errorMessage.value = '';

    final result = await _videoInterface().likeUnlike(video.id);

    result.fold((failure) => errorMessage.value = failure.uiMessage, (success) {
      // The endpoint toggles, so a `liked: true` answer means the video was
      // not liked to begin with and is now — leave it on the list.
      if (success.data?.liked == true) return;

      videos.removeWhere((item) => item.id == video.id);

      // The video page's heart, if that video is open behind this screen.
      if (Get.isRegistered<MusicPlayerController>()) {
        final page = Get.find<MusicPlayerController>();
        if (page.currentVideoId == video.id) {
          page.isLiked.value = false;
          if (page.likeCount.value > 0) page.likeCount.value--;
        }
      }
    });

    unliking.remove(video.id);
  }
}
