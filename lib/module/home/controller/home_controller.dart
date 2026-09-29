import 'package:app_pigeon/app_pigeon.dart';
import 'package:dartz/dartz.dart' show Left;
import 'package:get/get.dart';

import '../../../core/api_handler/failure.dart';
import '../../../core/notifiers/snackbar_notifier.dart';
import '../../../core/player/player_controller.dart';
import '../model/listen_model.dart';
import '../presentation/screens/audio_play_screen.dart';
import '../services/lister_interface_impl.dart';
import '../services/listen_interface.dart';
import 'download_controller.dart';
import 'song_like_controller.dart';
import 'song_progress_controller.dart';

class HomeController extends GetxController {
  final isLoading = true.obs;
  final errorMessage = ''.obs;
  final listenData = ListenMusicModel().obs;

  @override
  void onInit() {
    super.onInit();
    fetchListenData();
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

    final result = await _listenInterface().getListen();

    result.fold((failure) => errorMessage.value = failure.uiMessage, (
      success,
    ) {
      listenData.value = success.data ?? ListenMusicModel();
    });

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
  Future<void> playSong(String listenId) async {
    if (isLoadingSong.value) return;
    isLoadingSong.value = true;

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
        startAt =
            success.data?.userProgress?.resumePosition(
              success.data?.durationMs ?? 0,
            ) ??
            Duration.zero;
      },
    );
    streamResult?.fold(
      (failure) {
        error ??= failure.uiMessage;
        offline = offline || failure.failure == Failure.socketFailure;
      },
      (success) => streamUrl = success.data?.streamUrl ?? '',
    );

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
        SnackbarNotifier(context: context).notifyError(
          message: errorMessage.value,
        );
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

    Get.to(
      () => const PlayerScreen(),
      transition: Transition.downToUp,
      preventDuplicates: true,
    );
  }
}
