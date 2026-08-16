import 'package:app_pigeon/app_pigeon.dart';
import 'package:beatx_flutter/core/player/player_controller.dart';
import 'package:beatx_flutter/module/home/presentation/screens/audio_play_screen.dart';
import 'package:get/get.dart';

import '../model/audio_book_details_model.dart';
import '../services/audio_book_interface.dart';
import '../services/audio_book_interface_impl.dart';
import 'audiobook_like_controller.dart';
import 'liked_audiobooks_controller.dart';

class AudioBookDetailsController extends GetxController {
  final details = Rxn<AudiobookDetailsData>();
  final isLoading = false.obs;
  final errorMessage = ''.obs;
  final isStreamLoading = false.obs;

  /// Whether the user has liked this book. Settled against
  /// `GET /audiobooks/liked` once the screen opens, since neither the details
  /// payload nor the home payload carries a per-user flag.
  final isLiked = false.obs;
  final isTogglingLike = false.obs;

  String? _loadedAudiobookId;

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

  Future<void> loadDetails(String audiobookId) async {
    if (audiobookId.isEmpty || _loadedAudiobookId == audiobookId) return;

    _loadedAudiobookId = audiobookId;
    isLoading.value = true;
    errorMessage.value = '';

    final result = await _audioBookInterface().audiobookDetails(audiobookId);
    result.fold(
      (failure) => errorMessage.value = failure.uiMessage,
      (success) => details.value = success.data,
    );
    isLoading.value = false;

    _settleLiked(audiobookId);
  }

  /// Reads the heart off the user's liked books, which is where the backend
  /// reports the like — the details payload has no per-user flag.
  Future<void> _settleLiked(String audiobookId) async {
    final liked = LikedAudiobooksController.instance;

    // The list is shared, so a fetch is only needed when nothing has asked
    // for it yet this run.
    if (!liked.hasLoaded.value) await liked.fetch();

    isLiked.value = liked.isLiked(audiobookId);
  }

  /// Likes the book, or unlikes it when it is already liked — the endpoint
  /// toggles, so both directions are the same call.
  Future<void> toggleLike() async {
    final audiobookId = details.value?.book?.id ?? _loadedAudiobookId ?? '';

    // Cleared ahead of the guards so a tap that does nothing does not leave
    // the caller looking at the previous attempt's error.
    errorMessage.value = '';
    if (audiobookId.isEmpty || isTogglingLike.value) return;

    isTogglingLike.value = true;

    final result = await _audioBookInterface().likeAudiobook(audiobookId);

    result.fold((failure) => errorMessage.value = failure.uiMessage, (success) {
      // A backend that only acknowledges the call reports no flag, so fall
      // back to flipping what is on screen.
      final liked = success.data?.liked ?? !isLiked.value;

      isLiked.value = liked;
      LikedAudiobooksController.syncHearts(audiobookId, liked);
      LikedAudiobooksController.instance.fetch();
    });

    isTogglingLike.value = false;
  }

  /// The chapter `Listen Now` should start from — first chapter in the list.
  Chapter? get firstChapter {
    final chapters = details.value?.chapters;
    return (chapters != null && chapters.isNotEmpty) ? chapters.first : null;
  }

  /// Fetches the stream URL for [chapter] and starts playback via the app's
  /// shared [PlayerController], then opens the full-screen player.
  Future<void> playChapter(Chapter chapter) async {
    if (isStreamLoading.value) return;

    final audiobookId = details.value?.book?.id ?? _loadedAudiobookId ?? '';
    final chapterId = chapter.id ?? '';
    if (audiobookId.isEmpty || chapterId.isEmpty) {
      errorMessage.value = 'This chapter is unavailable right now.';
      return;
    }

    isStreamLoading.value = true;
    errorMessage.value = '';

    final result = await _audioBookInterface().audiobookStreamUrl(
      audiobookId,
      chapterId,
    );

    result.fold((failure) => errorMessage.value = failure.uiMessage, (
      success,
    ) {
      final streamUrl = success.data?.streamUrl ?? '';
      if (streamUrl.isEmpty) {
        errorMessage.value = 'Stream URL is unavailable right now.';
        return;
      }

      final book = details.value?.book;
      _playerController().play(
        title: chapter.title?.isNotEmpty == true
            ? chapter.title!
            : (book?.title ?? ''),
        artist: book?.author ?? '',
        imageAsset: book?.coverUrl ?? '',
        audioAsset: streamUrl,
        trackId: chapterId,
      );

      // The like belongs to the book, not the chapter — the player screen
      // reads it off this controller.
      AudiobookLikeController.instance.load(
        audiobookId: audiobookId,
        isLiked: isLiked.value,
      );

      Get.to(
        () => const PlayerScreen(),
        transition: Transition.downToUp,
        preventDuplicates: true,
      );
    });

    isStreamLoading.value = false;
  }
}
