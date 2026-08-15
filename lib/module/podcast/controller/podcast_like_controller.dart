import 'package:app_pigeon/app_pigeon.dart';
import 'package:get/get.dart';

import '../../../core/player/player_controller.dart';
import '../../../core/player/player_like_target.dart';
import '../services/podcast_interface.dart';
import '../services/podcast_interface_impl.dart';

/// Like state of the podcast the player is on, toggled through
/// `POST /podcasts/:id/like`.
///
/// The like belongs to the podcast, not to the episode, so this holds the id
/// of the episode's parent. Like its song counterpart it binds to the play
/// session that loaded it, so [canLike] turns false as soon as the shared
/// [PlayerController] moves on to a song or an audiobook.
class PodcastLikeController extends GetxController implements PlayerLikeTarget {
  /// The shared instance, registered on first use.
  static PodcastLikeController get instance {
    if (!Get.isRegistered<PodcastLikeController>()) {
      Get.put(PodcastLikeController(), permanent: true);
    }
    return Get.find<PodcastLikeController>();
  }

  final podcastId = ''.obs;
  @override
  final isLiked = false.obs;
  final likeCount = 0.obs;
  final isToggling = false.obs;
  @override
  final errorMessage = ''.obs;

  // Observable so widgets reading [canLike] inside an Obx rebuild when the
  // loaded podcast changes.
  final _playSession = (-1).obs;

  // Bumped by anything that settles the like state, so a details fetch that
  // lands late cannot overwrite a newer answer.
  int _stateVersion = 0;

  PodcastInterface _podcastInterface() {
    if (!Get.isRegistered<PodcastInterface>() &&
        Get.isRegistered<AuthorizedPigeon>()) {
      Get.put<PodcastInterface>(
        PodcastInterfaceImpl(Get.find<AuthorizedPigeon>()),
      );
    }
    return Get.find<PodcastInterface>();
  }

  PlayerController _playerController() {
    if (!Get.isRegistered<PlayerController>()) {
      Get.put(PlayerController(), permanent: true);
    }
    return Get.find<PlayerController>();
  }

  /// Adopts the podcast an episode belongs to as the one now playing. Call
  /// right after [PlayerController.play], which is what starts the session
  /// this is tied to.
  void load({
    required String podcastId,
    bool isLiked = false,
    int likeCount = 0,
  }) {
    this.podcastId.value = podcastId;
    this.isLiked.value = isLiked;
    this.likeCount.value = likeCount;
    errorMessage.value = '';
    _playSession.value = _playerController().playCount.value;

    _refreshLiked(++_stateVersion);
  }

  /// Settles [isLiked] against the podcast's own record.
  ///
  /// Episodes are played from lists and from `GET /podcasts/episodes/:id`,
  /// none of which carry a liked flag — `GET /podcasts/:id` is where the
  /// backend reports one.
  Future<void> _refreshLiked(int version) async {
    final id = podcastId.value;
    if (id.isEmpty) return;

    final result = await _podcastInterface().podcastDetails(id);

    // A like landed, or another podcast was loaded, while this was in flight.
    if (version != _stateVersion) return;

    result.fold(
      // Leave the seeded state alone — a heart that is merely stale beats one
      // that flips back on a dropped request.
      (failure) {},
      (success) {
        final podcast = success.data?.podcast;
        if (podcast == null) return;

        isLiked.value = podcast.isLiked;
        likeCount.value = podcast.likeCount;
      },
    );
  }

  /// Whether the loaded podcast is still what the shared player is playing.
  @override
  bool get canLike =>
      podcastId.value.isNotEmpty &&
      _playerController().playCount.value == _playSession.value;

  /// Likes the podcast, or unlikes it when it is already liked — the endpoint
  /// toggles, so both directions are the same call.
  @override
  Future<void> toggleLike() async {
    final id = podcastId.value;

    // Cleared ahead of the guards so a tap that does nothing does not leave
    // the caller looking at the previous attempt's error.
    errorMessage.value = '';
    if (id.isEmpty || isToggling.value || !canLike) return;

    isToggling.value = true;
    _stateVersion++;

    final result = await _podcastInterface().likePodcast(id);

    result.fold(
      (failure) => errorMessage.value = failure.uiMessage,
      (success) {
        // A backend that only acknowledges the call reports neither field, so
        // fall back to flipping what is on screen.
        final liked = success.data?.liked ?? !isLiked.value;
        final counted =
            success.data?.likeCount ?? likeCount.value + (liked ? 1 : -1);

        isLiked.value = liked;
        likeCount.value = counted < 0 ? 0 : counted;
      },
    );

    isToggling.value = false;
  }
}
