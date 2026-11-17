import 'dart:async';

import 'package:app_pigeon/app_pigeon.dart';
import 'package:dartz/dartz.dart' show Left;
import 'package:get/get.dart';

import '../../../core/api_handler/failure.dart';
import '../../../core/notifiers/snackbar_notifier.dart';
import '../../../core/player/player_controller.dart';
import '../../auth/services/onboarding_service.dart';
import '../model/listen_model.dart';
import '../presentation/screens/audio_play_screen.dart';
import '../services/lister_interface_impl.dart';
import '../services/listen_interface.dart';
import 'download_controller.dart';
import 'song_like_controller.dart';
import 'song_progress_controller.dart';
import '../../../core/common/widget/now_playing_sheet.dart';
import '../../../core/player/now_playing.dart';
import '../../../core/player/progress_store.dart';

class HomeController extends GetxController {
  final isLoading = true.obs;
  final errorMessage = ''.obs;

  /// The last home fetch failed because there was no connection.
  final isOffline = false.obs;
  final listenData = ListenMusicModel().obs;

  /// "Artists to Watch": `GET /discovery/recommended-artists`, i.e. artists
  /// with a public profile the listener does not follow yet.
  final artists = <OnboardingArtist>[].obs;
  final isLoadingArtists = true.obs;

  @override
  void onInit() {
    super.onInit();
    fetchListenData();
  }

  Future<void> fetchArtists() async {
    if (!Get.isRegistered<AuthorizedPigeon>()) {
      isLoadingArtists.value = false;
      return;
    }
    isLoadingArtists.value = true;
    final result = await OnboardingService(
      Get.find<AuthorizedPigeon>(),
    ).recommendedArtists();
    // A failure keeps whatever was shown before.
    result.fold((_) {}, (success) => artists.assignAll(success.data ?? []));
    isLoadingArtists.value = false;
  }

  ListenInterface _listenInterface() {
    if (!Get.isRegistered<ListenInterface>() &&
        Get.isRegistered<AuthorizedPigeon>()) {
      Get.put<ListenInterface>(
        ListenInterfaceImpl(Get.find<AuthorizedPigeon>()),
      );
    }
    return Get.find<ListenInterface>();
  }

  Future<void> fetchListenData() async {
    isLoading.value = true;
    errorMessage.value = '';
    isOffline.value = false;

    // Independent of the home feed, so it loads alongside it.
    unawaited(fetchArtists());

    final result = await _listenInterface().getListen();

    result.fold(
      (failure) {
        errorMessage.value = failure.uiMessage;
        isOffline.value = failure.failure == Failure.socketFailure;
      },
      (success) {
        listenData.value = success.data ?? ListenMusicModel();
      },
    );

    isLoading.value = false;
  }

  List<FeaturedSong> get featured => listenData.value.featured;

  List<TrendingSong> get trending => listenData.value.trending;

  List<NewReleaseSong> get newReleases => listenData.value.newReleases;

  List<DailyDiscoverySong> get dailyDiscovery =>
      listenData.value.dailyDiscovery;

  final isLoadingSong = false.obs;

  /// How long a downloaded song waits on the network for its resume point
  /// and like state before playing without them. Offline, the request fails
  /// straight away; this only bounds a connection that is up but crawling.
  static const _downloadedDetailsWait = Duration(seconds: 3);

  /// Plays a song and navigates to [PlayerScreen].
  ///
  /// A song saved for offline listening plays from the device and never asks
  /// for a stream url. Anything else fetches its details and stream url
  /// concurrently and streams.
  ///
  /// [queue] is the list the song was picked from, in order; the player's
  /// next and previous buttons move through it. Left empty, whatever queue is
  /// already playing is kept if it holds this song. [openPlayer] is false when
  /// the player moves on by itself, so the user is not pulled off the screen
  /// they are on. [source] names that list ("Liked Songs") for the player's
  /// "Playing from" line.
  Future<void> playSong(
    String listenId, {
    List<String> queue = const [],
    String source = '',
    bool openPlayer = true,
  }) async {
    if (isLoadingSong.value) return;
    isLoadingSong.value = true;

    if (queue.isNotEmpty) {
      Get.find<PlayerController>().setQueue(
        queue,
        current: listenId,
        start: (id) => playSong(id, openPlayer: false),
      );
      // Kept while the player stays in this list; dropped once anything
      // else plays.
      attachNowPlaying(
        source.isEmpty
            ? null
            : NowPlayingContext(
                kind: NowPlayingKind.song,
                collectionId: source,
                collectionTitle: source,
              ),
      );
    }

    // Lands whatever was reached in the song playing now before the details
    // are read, so replaying it straight away resumes from the latest point.
    // Bounded, so a dead connection cannot hold up an offline play.
    final songProgress = SongProgressController.instance;
    await songProgress.flush().timeout(
      _downloadedDetailsWait,
      onTimeout: () {},
    );

    final downloads = DownloadController.instance;
    final downloaded = await downloads.playableDownload(listenId);

    final interface = _listenInterface();
    final detailsFuture = interface.getListenDetails(listenId);
    final streamFuture = downloaded == null
        ? interface.getListenStreamUrl(listenId)
        : null;

    final detailsResult = downloaded == null
        ? await detailsFuture
        : await detailsFuture.timeout(
            _downloadedDetailsWait,
            onTimeout: () => Left(
              DataCRUDFailure(
                failure: Failure.timeout,
                fullError: 'Song details timed out.',
              ),
            ),
          );
    final streamResult = await streamFuture;

    String? error;
    var offline = false;
    var title = downloaded?.title ?? '';
    var artist = downloaded?.artist ?? '';
    var coverUrl = downloaded?.artworkUrl ?? '';
    var streamUrl = '';
    var isLiked = false;
    var likeCount = 0;
    var startAt = Duration.zero;

    // Offline (or slow), the server cannot say where this song was left:
    // fall back to what this device saved.
    await ProgressStore.ready();
    final saved = ProgressStore.entry(listenId);
    if (saved != null) {
      startAt = ProgressStore.resumeFrom(
        saved.position,
        Duration(milliseconds: downloaded?.durationMs ?? 0),
      );
    }

    detailsResult.fold(
      (failure) {
        error = failure.uiMessage;
        offline = failure.failure == Failure.socketFailure;
      },
      (success) {
        title = success.data?.title ?? title;
        artist = success.data?.artist ?? artist;
        coverUrl = success.data?.coverUrl ?? coverUrl;
        isLiked = success.data?.isLiked ?? false;
        likeCount = success.data?.likeCount ?? 0;
        // The server's resume point, unless this device saved a newer one.
        final progress = success.data?.userProgress;
        startAt = ProgressStore.choose(
          id: listenId,
          length: Duration(milliseconds: success.data?.durationMs ?? 0),
          server: progress == null
              ? (position: Duration.zero, completed: false, savedAt: null)
              : (
                  position: progress.resumePosition(
                    success.data?.durationMs ?? 0,
                  ),
                  completed: progress.completed,
                  savedAt: progress.lastPlayedAt ?? progress.updatedAt,
                ),
        );
      },
    );
    streamResult?.fold((failure) {
      error ??= failure.uiMessage;
      offline = offline || failure.failure == Failure.socketFailure;
    }, (success) => streamUrl = success.data?.streamUrl ?? '');

    isLoadingSong.value = false;

    final audioSource = downloaded != null
        ? downloads.audioPath(downloaded)
        : streamUrl;

    if (audioSource.isEmpty) {
      errorMessage.value = offline
          ? "You're offline. Only downloaded songs can play without internet."
          : error ?? 'Unable to load song.';
      final context = Get.context;
      if (context != null && context.mounted) {
        SnackbarNotifier(
          context: context,
        ).notifyError(message: errorMessage.value);
      }
      return;
    }

    // The saved cover keeps the art showing with no connection.
    final coverPath = downloaded == null
        ? null
        : downloads.coverPath(downloaded);

    Get.find<PlayerController>().play(
      title: title,
      artist: artist,
      imageAsset: coverPath ?? coverUrl,
      audioAsset: audioSource,
      startAt: startAt,
      trackId: listenId,
    );
    songProgress.start(listenId);

    // After play(), which has already opened the session the like state binds
    // to — the player screen reads the like off this controller.
    SongLikeController.instance.load(
      songId: listenId,
      isLiked: isLiked,
      likeCount: likeCount,
    );

    if (!openPlayer) return;
    Get.to(
      () => const PlayerScreen(),
      transition: Transition.downToUp,
      preventDuplicates: true,
    );
  }
}
