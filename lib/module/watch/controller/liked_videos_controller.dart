import 'package:app_pigeon/app_pigeon.dart';
import 'package:beatx_flutter/core/base/paged_list.dart';
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

  /// Loaded a page at a time as the liked screen scrolls, so a long list
  /// is never fetched (or laid out) all at once.
  late final _pages = PagedList<VideoModel>(
    fetch: (page, limit) =>
        _videoInterface().likedVideosPage(page: page, limit: limit),
    idOf: (item) => item.id,
  );

  /// The pages loaded so far.
  RxList<VideoModel> get videos => _pages.items;
  RxBool get isLoading => _pages.isLoading;
  RxString get errorMessage => _pages.errorMessage;

  /// False until a fetch has come back, so the count can be held back rather
  /// than shown as a zero that only means "not asked yet".
  RxBool get hasLoaded => _pages.hasLoaded;

  /// How many are liked in all — more than [videos] until every
  /// page has loaded.
  RxInt get total => _pages.total;
  RxBool get isLoadingMore => _pages.isLoadingMore;
  bool get hasMore => _pages.hasMore;

  /// Appends the next page; called as the liked screen nears its end.
  Future<void> loadMore() => _pages.loadMore();

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

  Future<void> _fetch() => _pages.refresh();

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

      _pages.remove((item) => item.id == video.id);

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
