import 'package:app_pigeon/app_pigeon.dart';
import 'package:beatx_flutter/core/player/player_controller.dart';
import 'package:beatx_flutter/module/home/presentation/screens/audio_play_screen.dart';
import 'package:get/get.dart';

import '../../../core/api_handler/paged_result.dart';
import '../../../core/helpers/typedefs.dart';

import '../model/episodes_model.dart';
import '../model/podcast_home_model.dart';
import '../model/search_category_model.dart';
import '../services/podcast_interface.dart';
import '../services/podcast_interface_impl.dart';
import 'podcast_like_controller.dart';
import 'save_progress_controller.dart';
import 'podcast_now_playing.dart';

/// Everything published under one category: the shows themselves and, below
/// them, every episode those shows have.
class PodcastCategoryController extends GetxController {
  PodcastCategoryController({
    required this.categoryId,
    this.allPodcasts = false,
  });

  final String categoryId;

  /// Every show, not one category's: what "See all activity" lists.
  final bool allPodcasts;

  /// Shows a page at a time, and the newest few episodes of each, so a big
  /// category never pulls in every episode of every show at once.
  static const _showsPerPage = 20;
  static const _episodesPerShow = 10;

  final podcasts = <CategoryPodcast>[].obs;
  final episodes = <RecentEpisode>[].obs;
  final isLoading = true.obs;

  /// The next page of shows (and their episodes) is on its way.
  final isLoadingMore = false.obs;

  /// How many shows the category holds, across every page.
  final totalPodcasts = 0.obs;
  int _page = 0;
  int _generation = 0;

  bool get hasMore => podcasts.length < totalPodcasts.value;
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
    if (categoryId.isEmpty && !allPodcasts) {
      errorMessage.value =
          'This category arrived without an id, so its shows cannot be looked '
          'up.';
      isLoading.value = false;
      return;
    }

    final generation = ++_generation;
    isLoading.value = true;
    errorMessage.value = '';

    final result = await _showsPage(1);
    if (generation != _generation) return;
    result.fold((failure) => errorMessage.value = failure.uiMessage, (page) {
      _page = 1;
      podcasts.assignAll(page.items);
      totalPodcasts.value = page.total > page.items.length
          ? page.total
          : page.items.length;
    });
    episodes.clear();
    isLoading.value = false;

    if (podcasts.isNotEmpty) {
      isLoadingEpisodes.value = true;
      final newest = await _newestEpisodes(podcasts);
      if (generation != _generation) return;
      episodes.assignAll(newest);
      isLoadingEpisodes.value = false;
    }
  }

  /// The next page of shows, with their newest episodes appended below the
  /// ones already listed. Called as the screen nears its end.
  Future<void> loadMore() async {
    if (isLoading.value || isLoadingMore.value || !hasMore) return;
    final generation = _generation;
    isLoadingMore.value = true;

    final result = await _showsPage(_page + 1);
    if (generation != _generation) return;
    final added = result.fold((_) => const <CategoryPodcast>[], (page) {
      _page++;
      final known = {for (final p in podcasts) p.id};
      final fresh = page.items.where((p) => !known.contains(p.id)).toList();
      podcasts.addAll(fresh);
      // Nothing new: the server has no more, whatever its count said.
      if (page.items.isEmpty) totalPodcasts.value = podcasts.length;
      return fresh;
    });
    if (added.isNotEmpty) {
      final newest = await _newestEpisodes(added);
      if (generation != _generation) return;
      episodes.addAll(newest);
    }
    isLoadingMore.value = false;
  }

  Future<Request<PagedResult<CategoryPodcast>>> _showsPage(int page) async {
    final result = await _podcastInterface().searchPodcast(
      query: '',
      genreId: categoryId,
      page: page,
      limit: _showsPerPage,
    );
    return result.map((success) => success.data ?? PagedResult());
  }

  /// The newest few episodes of each of [shows], newest first.
  Future<List<RecentEpisode>> _newestEpisodes(
    List<CategoryPodcast> shows,
  ) async {
    final interface = _podcastInterface();
    final results = await Future.wait(
      shows.map(
        (podcast) =>
            interface.podcastEpisodes(podcast.id, limit: _episodesPerShow),
      ),
    );

    final collected = <RecentEpisode>[];
    for (var index = 0; index < results.length; index++) {
      final podcast = shows[index];
      results[index].fold((failure) => null, (success) {
        for (final page in success.data ?? const <EpisodeModel>[]) {
          for (final episode in page.data) {
            collected.add(_toRecentEpisode(episode, podcast));
          }
        }
      });
    }
    collected.sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
    return collected;
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

    // Where this user left off, fetched alongside the stream url.
    final resume = PodcastNowPlaying.resumeFor(
      episode.id,
      durationMs: episode.durationMs,
    );
    final result = await _podcastInterface().getStreamUrl(episode.id);
    final startAt = await resume;

    result.fold((failure) => errorMessage.value = failure.uiMessage, (success) {
      final streamUrl = success.data?.streamUrl ?? '';
      if (streamUrl.isEmpty) {
        errorMessage.value = 'Stream URL is unavailable right now.';
        return;
      }

      // Which show, which episode of it, and the rest of it as the queue.
      PodcastNowPlaying.attach(
        podcastId: episode.podcastId.id,
        podcastTitle: episode.podcastId.title,
        podcastCoverUrl: episode.podcastId.coverUrl,
        episodeId: episode.id,
        episodeTitle: episode.title,
        seasonNumber: episode.seasonNumber,
        episodeNumber: episode.episodeNumber,
        durationMs: episode.durationMs,
      );
      _playerController().play(
        title: episode.title,
        artist: episode.podcastId.title,
        imageAsset: episode.coverUrl ?? episode.podcastId.coverUrl ?? '',
        audioAsset: streamUrl,
        startAt: startAt,
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
