import 'package:app_pigeon/app_pigeon.dart';
import 'package:beatx_flutter/core/player/player_controller.dart';
import 'package:beatx_flutter/module/home/presentation/screens/audio_play_screen.dart';
import 'package:get/get.dart';

import '../model/episodes_model.dart';
import '../model/podcast_home_model.dart';
import '../model/search_category_model.dart';
import '../services/podcast_interface.dart';
import '../services/podcast_interface_impl.dart';
import 'podcast_like_controller.dart';
import 'save_progress_controller.dart';

/// Everything published under one category: the shows themselves and, below
/// them, every episode those shows have.
class PodcastCategoryController extends GetxController {
  PodcastCategoryController({required this.categoryId});

  final String categoryId;

  final podcasts = <CategoryPodcast>[].obs;
  final episodes = <RecentEpisode>[].obs;
  final isLoading = true.obs;
  final isLoadingEpisodes = false.obs;
  final errorMessage = ''.obs;

  /// False until the user asks for the rest of the shows in the category.
  final showAllPodcasts = false.obs;

  /// Id of the episode whose stream URL is being fetched, or '' when idle.
  final loadingEpisodeId = ''.obs;

  bool get isStreamLoading => loadingEpisodeId.value.isNotEmpty;

  /// The show that headlines the screen — the first one the search returned.
  CategoryPodcast? get headline => podcasts.isEmpty ? null : podcasts.first;

  /// The rest of the category, shown as cards under the headline.
  List<CategoryPodcast> get otherPodcasts =>
      podcasts.length <= 1 ? const [] : podcasts.sublist(1);

  /// What the card grid actually renders: a first row's worth until the user
  /// taps "View all".
  List<CategoryPodcast> get visiblePodcasts {
    final rest = otherPodcasts;
    if (showAllPodcasts.value || rest.length <= _collapsedPodcastCount) {
      return rest;
    }
    return rest.sublist(0, _collapsedPodcastCount);
  }

  bool get canExpandPodcasts => otherPodcasts.length > _collapsedPodcastCount;

  static const _collapsedPodcastCount = 2;

  @override
  void onInit() {
    super.onInit();
    fetchCategory();
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

  SaveProgressController _saveProgressController() {
    if (!Get.isRegistered<SaveProgressController>()) {
      Get.put(SaveProgressController(), permanent: true);
    }
    return Get.find<SaveProgressController>();
  }

  Future<void> fetchCategory() async {
    // The search endpoint only accepts an ObjectId, so an id the home payload
    // never sent is worth saying out loud rather than posting and failing.
    if (categoryId.isEmpty) {
      errorMessage.value =
          'This category arrived without an id, so its shows cannot be looked '
          'up.';
      isLoading.value = false;
      return;
    }

    isLoading.value = true;
    errorMessage.value = '';

    final result = await _podcastInterface().searchCategory(categoryId);
    result.fold((failure) => errorMessage.value = failure.uiMessage, (success) {
      podcasts.value = success.data?.data ?? const [];
    });

    isLoading.value = false;

    if (podcasts.isNotEmpty) await _fetchEpisodes();
  }

  /// The search only returns shows, so the episode list is stitched together
  /// from each show's own episode call — newest first, whichever show it
  /// belongs to.
  Future<void> _fetchEpisodes() async {
    isLoadingEpisodes.value = true;

    final interface = _podcastInterface();
    final results = await Future.wait(
      podcasts.map((podcast) => interface.podcastEpisodes(podcast.id)),
    );

    final collected = <RecentEpisode>[];
    for (var index = 0; index < results.length; index++) {
      final podcast = podcasts[index];
      results[index].fold((failure) => null, (success) {
        for (final page in success.data ?? const <EpisodeModel>[]) {
          for (final episode in page.data) {
            collected.add(_toRecentEpisode(episode, podcast));
          }
        }
      });
    }

    collected.sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
    episodes.value = collected;
    isLoadingEpisodes.value = false;
  }

  /// The episode screens all speak [RecentEpisode], so search results are
  /// mapped onto it rather than given a second shape to handle.
  RecentEpisode _toRecentEpisode(
    PodcastEpisode episode,
    CategoryPodcast podcast,
  ) {
    return RecentEpisode(
      id: episode.id,
      podcastId: PodcastBasic(
        id: podcast.id,
        title: podcast.title,
        coverUrl: podcast.coverUrl,
      ),
      episodeNumber: episode.episodeNumber,
      seasonNumber: episode.seasonNumber,
      title: episode.title,
      coverUrl: episode.coverUrl,
      durationMs: episode.durationMs,
      publishedAt: episode.publishedAt ?? DateTime.now(),
    );
  }

  void toggleShowAllPodcasts() =>
      showAllPodcasts.value = !showAllPodcasts.value;

  /// Plays the newest episode of [podcast] — what the headline card's
  /// "Listen Now" offers.
  Future<void> playPodcast(CategoryPodcast podcast) async {
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

    result.fold((failure) => errorMessage.value = failure.uiMessage, (success) {
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
        trackId: episode.id,
      );

      _saveProgressController().start(episode.id);

      // The like belongs to the podcast, not the episode — the player screen
      // reads it off this controller.
      PodcastLikeController.instance.load(podcastId: episode.podcastId.id);

      Get.to(
        () => const PlayerScreen(),
        transition: Transition.downToUp,
        preventDuplicates: true,
      );
    });

    loadingEpisodeId.value = '';
  }
}
