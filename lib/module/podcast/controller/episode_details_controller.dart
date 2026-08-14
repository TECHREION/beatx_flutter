import 'package:app_pigeon/app_pigeon.dart';
import 'package:beatx_flutter/core/player/player_controller.dart';
import 'package:beatx_flutter/module/home/presentation/screens/audio_play_screen.dart';
import 'package:get/get.dart';

import '../model/episodes_details.dart';
import '../model/episodes_model.dart';
import '../services/podcast_interface.dart';
import '../services/podcast_interface_impl.dart';

class EpisodeDetailsController extends GetxController {
  final details = Rxn<EpisodeDetailsData>();
  final relatedEpisodes = <PodcastEpisode>[].obs;
  final isLoading = false.obs;
  final errorMessage = ''.obs;

  /// Id of the episode whose stream URL is being fetched, or '' when idle.
  final loadingEpisodeId = ''.obs;

  bool get isStreamLoading => loadingEpisodeId.value.isNotEmpty;

  String? _loadedEpisodeId;

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

  Future<void> loadDetails(String episodeId) async {
    if (episodeId.isEmpty || _loadedEpisodeId == episodeId) return;

    _loadedEpisodeId = episodeId;
    isLoading.value = true;
    errorMessage.value = '';

    final result = await _podcastInterface().episodeDetails(episodeId);
    result.fold((failure) => errorMessage.value = failure.uiMessage, (
      success,
    ) {
      final data = success.data;
      details.value = data;
      if (data != null) {
        _loadRelatedEpisodes(data.episode.podcastId.id, episodeId);
      }
    });

    isLoading.value = false;
  }

  Future<void> _loadRelatedEpisodes(
    String podcastId,
    String currentEpisodeId,
  ) async {
    if (podcastId.isEmpty) return;

    final result = await _podcastInterface().podcastEpisodes(podcastId);
    result.fold((failure) => null, (success) {
      relatedEpisodes.value = (success.data ?? const [])
          .expand((page) => page.data)
          .where((episode) => episode.id != currentEpisodeId)
          .toList();
    });
  }

  /// Fetches the stream URL for the episode with [episodeId] and starts
  /// playback via the app's shared [PlayerController], then opens the
  /// full-screen player.
  Future<void> playEpisode({
    required String episodeId,
    required String title,
    required String artist,
    String? coverUrl,
  }) async {
    if (isStreamLoading) return;

    loadingEpisodeId.value = episodeId;
    errorMessage.value = '';

    final result = await _podcastInterface().getStreamUrl(episodeId);

    result.fold((failure) => errorMessage.value = failure.uiMessage, (
      success,
    ) {
      final streamUrl = success.data?.streamUrl ?? '';
      if (streamUrl.isEmpty) {
        errorMessage.value = 'Stream URL is unavailable right now.';
        return;
      }

      _playerController().play(
        title: title,
        artist: artist,
        imageAsset: coverUrl ?? '',
        audioAsset: streamUrl,
      );

      Get.to(
        () => const PlayerScreen(),
        transition: Transition.downToUp,
        preventDuplicates: true,
      );
    });

    loadingEpisodeId.value = '';
  }
}
