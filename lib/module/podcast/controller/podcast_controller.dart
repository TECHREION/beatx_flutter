import 'package:app_pigeon/app_pigeon.dart';
import 'package:beatx_flutter/core/player/player_controller.dart';
import 'package:beatx_flutter/module/home/presentation/screens/audio_play_screen.dart';
import 'package:get/get.dart';

import '../model/podcast_home_model.dart';
import '../services/podcast_interface.dart';
import '../services/podcast_interface_impl.dart';

class PodcastController extends GetxController {
  final home = Rxn<PodcastHomeData>();
  final isLoading = true.obs;
  final errorMessage = ''.obs;
  final featuredIndex = 0.obs;

  /// Id of the episode whose stream URL is being fetched, or '' when idle.
  final loadingEpisodeId = ''.obs;

  bool get isStreamLoading => loadingEpisodeId.value.isNotEmpty;

  @override
  void onInit() {
    super.onInit();
    fetchHome();
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

  PlayerController _playerController() {
    if (!Get.isRegistered<PlayerController>()) {
      Get.put(PlayerController(), permanent: true);
    }
    return Get.find<PlayerController>();
  }

  Future<void> fetchHome() async {
    isLoading.value = true;
    errorMessage.value = '';

    final result = await _podcastInterface().podcastHome();
    result.fold((failure) => errorMessage.value = failure.uiMessage, (
      success,
    ) {
      home.value = success.data;
      if (featuredIndex.value >= featured.length) featuredIndex.value = 0;
    });

    isLoading.value = false;
  }

  List<ContinueListening> get continueListening =>
      home.value?.continueListening ?? const [];

  List<FeaturedPodcast> get featured => home.value?.featured ?? const [];

  FeaturedPodcast? get featuredPodcast =>
      featured.isEmpty ? null : featured[featuredIndex.value];

  List<TopCategory> get categories => home.value?.topCategories ?? const [];

  List<Podcaster> get podcasters => home.value?.topPodcasters.data ?? const [];

  List<RecentEpisode> get episodes => home.value?.recentEpisodes ?? const [];

  void showPreviousFeatured() {
    if (featured.isEmpty) return;
    featuredIndex.value =
        (featuredIndex.value - 1 + featured.length) % featured.length;
  }

  void showNextFeatured() {
    if (featured.isEmpty) return;
    featuredIndex.value = (featuredIndex.value + 1) % featured.length;
  }

  /// Plays the first recent episode belonging to [podcast], if any is loaded.
  Future<void> playFeatured(FeaturedPodcast podcast) async {
    RecentEpisode? episode;
    for (final candidate in episodes) {
      if (candidate.podcastId.id == podcast.id) {
        episode = candidate;
        break;
      }
    }

    if (episode == null) {
      errorMessage.value = 'No episodes available for this podcast yet.';
      return;
    }

    await playEpisode(episode);
  }

  /// Fetches the stream URL for [episode] and starts playback via the app's
  /// shared [PlayerController], then opens the full-screen player.
  Future<void> playEpisode(RecentEpisode episode) async {
    if (isStreamLoading) return;

    loadingEpisodeId.value = episode.id;
    errorMessage.value = '';

    final result = await _podcastInterface().getStreamUrl(episode.id);

    result.fold((failure) => errorMessage.value = failure.uiMessage, (
      success,
    ) {
      final streamUrl = success.data?.streamUrl ?? '';
      if (streamUrl.isEmpty) {
        errorMessage.value = 'Stream URL is unavailable right now.';
        return;
      }

      _playerController().play(
        title: episode.title,
        artist: episode.podcastId.title,
        imageAsset: episode.coverUrl ?? episode.podcastId.coverUrl ?? '',
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
