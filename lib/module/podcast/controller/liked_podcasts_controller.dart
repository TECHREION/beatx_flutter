import 'package:app_pigeon/app_pigeon.dart';
import 'package:get/get.dart';

import '../model/podcast_details_model.dart';
import '../services/podcast_interface.dart';
import '../services/podcast_interface_impl.dart';
import 'podcast_like_controller.dart';

/// The podcasts the signed-in user has liked, behind `GET /podcasts/liked`.
///
/// Shared rather than screen-scoped so the podcast screen's button can show
/// the count without the liked screen being open.
class LikedPodcastsController extends GetxController {
  /// The shared instance, registered on first use.
  static LikedPodcastsController get instance {
    if (!Get.isRegistered<LikedPodcastsController>()) {
      Get.put(LikedPodcastsController(), permanent: true);
    }
    return Get.find<LikedPodcastsController>();
  }

  final podcasts = <Podcast>[].obs;
  final isLoading = false.obs;
  final errorMessage = ''.obs;

  /// False until a fetch has come back, so the count can be held back rather
  /// than shown as a zero that only means "not asked yet".
  final hasLoaded = false.obs;

  /// Podcasts with an unlike in flight, kept out of the way of a second tap.
  final unliking = <String>{}.obs;

  @override
  void onInit() {
    super.onInit();
    fetch();
  }

  PodcastInterface _podcastInterface() {
    if (!Get.isRegistered<PodcastInterface>() &&
        Get.isRegistered<AuthorizedPigeon>()) {
      Get.put<PodcastInterface>(
        PodcastInterfaceImpl(Get.find<AuthorizedPigeon>()),
      );
    }
    return Get.find<PodcastInterface>();
  }

  Future<void>? _inFlight;

  /// Reloads the list.
  ///
  /// A second caller joins the fetch already running rather than being turned
  /// away — the screen asks on open at the same moment this controller's own
  /// first fetch is still in flight, and a dropped call would leave the screen
  /// waiting on a future that never ran.
  Future<void> fetch() =>
      _inFlight ??= _fetch().whenComplete(() => _inFlight = null);

  Future<void> _fetch() async {
    isLoading.value = true;
    errorMessage.value = '';

    final result = await _podcastInterface().getLikedPodcast();

    result.fold(
      (failure) => errorMessage.value = failure.uiMessage,
      (success) => podcasts.assignAll(success.data ?? const []),
    );

    hasLoaded.value = true;
    isLoading.value = false;
  }

  /// Removes [podcast] from the user's likes and drops it from the list.
  Future<void> unlike(Podcast podcast) async {
    if (unliking.contains(podcast.id)) return;

    unliking.add(podcast.id);
    errorMessage.value = '';

    final result = await _podcastInterface().likePodcast(podcast.id);

    result.fold(
      (failure) => errorMessage.value = failure.uiMessage,
      (success) {
        // The endpoint toggles, so a `liked: true` answer means the podcast
        // was not liked to begin with and is now — leave it on the list.
        if (success.data?.liked == true) return;

        podcasts.removeWhere((item) => item.id == podcast.id);

        // Keep the heart on the player screen honest when the podcast
        // unliked here is the one playing.
        final playing = PodcastLikeController.instance;
        if (playing.podcastId.value == podcast.id) {
          playing.isLiked.value = false;
        }
      },
    );

    unliking.remove(podcast.id);
  }
}
