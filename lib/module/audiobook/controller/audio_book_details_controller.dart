import 'package:app_pigeon/app_pigeon.dart';
import 'package:beatx_flutter/core/player/player_controller.dart';
import 'package:beatx_flutter/module/home/presentation/screens/audio_play_screen.dart';
import 'package:get/get.dart';

import '../model/audio_book_details_model.dart';
import '../services/audio_book_interface.dart';
import '../services/audio_book_interface_impl.dart';

class AudioBookDetailsController extends GetxController {
  final details = Rxn<AudiobookDetailsData>();
  final isLoading = false.obs;
  final errorMessage = ''.obs;
  final isStreamLoading = false.obs;

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
