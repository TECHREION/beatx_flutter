import 'package:app_pigeon/app_pigeon.dart';
import 'package:get/get.dart';

import '../../../core/player/player_controller.dart';
import '../../../core/player/player_like_target.dart';
import '../services/audio_book_interface.dart';
import '../services/audio_book_interface_impl.dart';
import 'liked_audiobooks_controller.dart';

/// Like state of the audiobook the player is on, toggled through
/// `POST /audiobooks/:id/like`.
///
/// The like belongs to the book, not to the chapter, so this holds the id of
/// the chapter's parent. Like its song and podcast counterparts it binds to
/// the play session that loaded it, so [canLike] turns false as soon as the
/// shared [PlayerController] moves on to something else.
class AudiobookLikeController extends GetxController
    implements PlayerLikeTarget {
  /// The shared instance, registered on first use.
  static AudiobookLikeController get instance {
    if (!Get.isRegistered<AudiobookLikeController>()) {
      Get.put(AudiobookLikeController(), permanent: true);
    }
    return Get.find<AudiobookLikeController>();
  }

  final audiobookId = ''.obs;
  @override
  final isLiked = false.obs;
  final isToggling = false.obs;
  @override
  final errorMessage = ''.obs;

  // Observable so widgets reading [canLike] inside an Obx rebuild when the
  // loaded book changes.
  final _playSession = (-1).obs;

  // Bumped by anything that settles the like state, so a liked-books fetch
  // that lands late cannot overwrite a newer answer.
  int _stateVersion = 0;

  AudioBookInterface _audioBookInterface() {
    if (!Get.isRegistered<AudioBookInterface>() &&
        Get.isRegistered<AuthorizedPigeon>()) {
      Get.put<AudioBookInterface>(
        AudioBookInterfaceImpl(Get.find<AuthorizedPigeon>()),
      );
    }
    return Get.find<AudioBookInterface>();
  }

  PlayerController _playerController() {
    if (!Get.isRegistered<PlayerController>()) {
      Get.put(PlayerController(), permanent: true);
    }
    return Get.find<PlayerController>();
  }

  /// Adopts the book a chapter belongs to as the one now playing. Call right
  /// after [PlayerController.play], which is what starts the session this is
  /// tied to.
  void load({required String audiobookId, bool isLiked = false}) {
    this.audiobookId.value = audiobookId;
    this.isLiked.value = isLiked;
    errorMessage.value = '';
    _playSession.value = _playerController().playCount.value;

    // Neither the details nor the stream payload carries a per-user flag, so
    // without this an already-liked book comes up with an empty heart.
    _refreshLiked(++_stateVersion);
  }

  /// Settles [isLiked] against the user's liked books on the backend.
  Future<void> _refreshLiked(int version) async {
    final id = audiobookId.value;
    if (id.isEmpty) return;

    final result = await _audioBookInterface().getLikedAudiobooks();

    // A like landed, or another book was loaded, while this was in flight.
    if (version != _stateVersion) return;

    result.fold(
      // Leave the seeded state alone — a heart that is merely stale beats one
      // that flips back on a dropped request.
      (failure) {},
      (success) {
        final liked = success.data ?? const [];
        isLiked.value = liked.any((book) => book.id == id);
      },
    );
  }

  /// Whether the loaded book is still what the shared player is playing.
  @override
  bool get canLike =>
      audiobookId.value.isNotEmpty &&
      _playerController().playCount.value == _playSession.value;

  /// Likes the book, or unlikes it when it is already liked — the endpoint
  /// toggles, so both directions are the same call.
  @override
  Future<void> toggleLike() async {
    final id = audiobookId.value;

    // Cleared ahead of the guards so a tap that does nothing does not leave
    // the caller looking at the previous attempt's error.
    errorMessage.value = '';
    if (id.isEmpty || isToggling.value || !canLike) return;

    isToggling.value = true;
    _stateVersion++;

    final result = await _audioBookInterface().likeAudiobook(id);

    result.fold(
      (failure) => errorMessage.value = failure.uiMessage,
      (success) {
        // A backend that only acknowledges the call reports no flag, so fall
        // back to flipping what is on screen.
        final liked = success.data?.liked ?? !isLiked.value;

        isLiked.value = liked;
        LikedAudiobooksController.syncHearts(id, liked);

        if (Get.isRegistered<LikedAudiobooksController>()) {
          LikedAudiobooksController.instance.fetch();
        }
      },
    );

    isToggling.value = false;
  }
}
