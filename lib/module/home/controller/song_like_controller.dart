import 'package:app_pigeon/app_pigeon.dart';
import 'package:get/get.dart';

import '../../../core/player/player_controller.dart';
import '../services/linter_interface_impl.dart';
import '../services/listen_interface.dart';

/// Like state of the song the player is on, toggled through
/// `POST /songs/:id/like`.
///
/// The [PlayerController] is shared with podcasts and audiobooks, so the state
/// is tied to the play session that loaded it: [canLike] turns false the
/// moment the player moves on to anything else, which stops the player screen
/// from sending a song like while an episode is playing.
class SongLikeController extends GetxController {
  /// The shared instance, registered on first use.
  static SongLikeController get instance {
    if (!Get.isRegistered<SongLikeController>()) {
      Get.put(SongLikeController(), permanent: true);
    }
    return Get.find<SongLikeController>();
  }

  final songId = ''.obs;
  final isLiked = false.obs;
  final likeCount = 0.obs;
  final isToggling = false.obs;
  final errorMessage = ''.obs;

  // Observable so widgets reading [canLike] inside an Obx rebuild when the
  // loaded song changes.
  final _playSession = (-1).obs;

  ListenInterface _listenInterface() {
    if (!Get.isRegistered<ListenInterface>() &&
        Get.isRegistered<AuthorizedPigeon>()) {
      Get.put<ListenInterface>(
        ListenInterfaceImpl(Get.find<AuthorizedPigeon>()),
      );
    }
    return Get.find<ListenInterface>();
  }

  PlayerController _playerController() {
    if (!Get.isRegistered<PlayerController>()) {
      Get.put(PlayerController(), permanent: true);
    }
    return Get.find<PlayerController>();
  }

  // Bumped by anything that settles the like state, so a liked-songs fetch
  // that lands late cannot overwrite a newer answer.
  int _stateVersion = 0;

  /// Adopts [songId] as the song now playing. Call right after
  /// [PlayerController.play], which is what starts the session this is tied
  /// to.
  void load({
    required String songId,
    bool isLiked = false,
    int likeCount = 0,
  }) {
    this.songId.value = songId;
    this.isLiked.value = isLiked;
    this.likeCount.value = likeCount;
    errorMessage.value = '';
    _playSession.value = _playerController().playCount.value;

    // `GET /songs/:id` reports likeCount but no per-user flag, so without this
    // an already-liked song comes up with an empty heart on every fresh run.
    _refreshLiked(++_stateVersion);
  }

  /// Settles [isLiked] against the user's liked songs on the backend.
  Future<void> _refreshLiked(int version) async {
    if (songId.value.isEmpty) return;

    final result = await _listenInterface().getLikedSong();

    // A like landed, or another song was loaded, while this was in flight.
    if (version != _stateVersion) return;

    result.fold(
      // Leave the seeded state alone — a heart that is merely stale beats one
      // that flips back on a dropped request.
      (failure) {},
      (success) {
        final liked = success.data ?? const [];
        isLiked.value = liked.any((song) => song.id == songId.value);
      },
    );
  }

  /// Whether the loaded song is still what the shared player is playing.
  bool get canLike =>
      songId.value.isNotEmpty &&
      _playerController().playCount.value == _playSession.value;

  /// Likes the song, or unlikes it when it is already liked — the endpoint
  /// toggles, so both directions are the same call.
  Future<void> toggleLike() async {
    final id = songId.value;

    // Cleared ahead of the guards so a tap that does nothing does not leave
    // the caller looking at the previous attempt's error.
    errorMessage.value = '';
    if (id.isEmpty || isToggling.value || !canLike) return;

    isToggling.value = true;
    _stateVersion++;

    final result = await _listenInterface().likesong(id);

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
