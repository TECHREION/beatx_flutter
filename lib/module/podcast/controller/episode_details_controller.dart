import 'package:app_pigeon/app_pigeon.dart';
import 'package:beatx_flutter/core/player/player_controller.dart';
import 'package:beatx_flutter/module/home/presentation/screens/audio_play_screen.dart';
import 'package:get/get.dart';

import '../model/episodes_details.dart';
import '../model/episodes_model.dart';
import '../services/podcast_interface.dart';
import '../services/podcast_interface_impl.dart';
import 'save_progress_controller.dart';

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

  SaveProgressController _saveProgressController() {
    if (!Get.isRegistered<SaveProgressController>()) {
      Get.put(SaveProgressController(), permanent: true);
    }
    return Get.find<SaveProgressController>();
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

  /// Duration of the loaded episode. The API reports 0 for episodes whose
  /// audio has not been measured, so fall back to the length the player
  /// itself read off the stream.
  int get durationMs {
    final reported = details.value?.episode.durationMs ?? 0;
    if (reported > 0) return reported;
    return _isActiveTrack
        ? _playerController().duration.value.inMilliseconds
        : 0;
  }

  UserProgress? get _progress => details.value?.userProgress;

  bool get isCompleted => _progress?.completed ?? false;

  /// True while this episode is the track the shared player is on.
  bool get _isActiveTrack =>
      _loadedEpisodeId != null &&
      _playerController().trackId.value == _loadedEpisodeId;

  /// Position to show on the progress bar: the live player position while
  /// this episode is playing, otherwise the last position saved server-side.
  int get listenedMs {
    final position = _isActiveTrack
        ? _playerController().position.value.inMilliseconds
        : (_progress?.positionMs ?? 0);
    if (position <= 0) return 0;
    // A stale saved position can outrun a re-cut episode.
    return durationMs > 0 ? position.clamp(0, durationMs) : position;
  }

  /// How much of the episode has been listened to, as a 0–1 fraction.
  double get listenedFraction {
    if (durationMs > 0) return (listenedMs / durationMs).clamp(0.0, 1.0);
    // No duration to measure against — fall back to the server's own figure.
    return ((_progress?.percentComplete ?? 0) / 100).clamp(0.0, 1.0);
  }

  /// Where playback should pick up. A finished episode — or one stopped in
  /// its last seconds — starts over rather than resuming at the very end.
  Duration get resumePosition {
    final progress = _progress;
    if (progress == null || progress.completed) return Duration.zero;

    final positionMs = progress.positionMs;
    if (positionMs <= 0) return Duration.zero;
    if (durationMs > 0 && positionMs >= durationMs - 1000) return Duration.zero;

    return Duration(milliseconds: positionMs);
  }

  bool get canResume => resumePosition > Duration.zero;

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
        // Only the episode this screen loaded has a progress record to
        // resume from.
        startAt: episodeId == _loadedEpisodeId ? resumePosition : Duration.zero,
        trackId: episodeId,
      );

      _saveProgressController().start(episodeId);

      Get.to(
        () => const PlayerScreen(),
        transition: Transition.downToUp,
        preventDuplicates: true,
      )?.then((_) => _refreshProgress(episodeId));
    });

    loadingEpisodeId.value = '';
  }

  /// Re-reads the episode once the player is dismissed so the progress bar
  /// shows what was just listened to. Silent — on failure the previous
  /// values stay on screen.
  Future<void> _refreshProgress(String episodeId) async {
    // Send the position reached before asking the server for it back.
    await _saveProgressController().flush();

    final result = await _podcastInterface().episodeDetails(episodeId);
    result.fold((failure) => null, (success) {
      if (success.data != null) details.value = success.data;
    });
  }
}
