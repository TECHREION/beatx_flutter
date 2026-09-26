import 'package:app_pigeon/app_pigeon.dart';
import 'package:get/get.dart';

import '../../../core/player/player_controller.dart';
import '../model/listen_model.dart';
import '../presentation/screens/audio_play_screen.dart';
import '../services/lister_interface_impl.dart';
import '../services/listen_interface.dart';
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

  /// Fetches song details and its stream url concurrently, then plays it
  /// through [PlayerController] and navigates to [PlayerScreen].
  Future<void> playSong(String listenId) async {
    if (isLoadingSong.value) return;
    isLoadingSong.value = true;

    // Lands whatever was reached in the song playing now before the details
    // are read, so replaying it straight away resumes from the latest point.
    final songProgress = SongProgressController.instance;
    await songProgress.flush();

    final interface = _listenInterface();
    final detailsFuture = interface.getListenDetails(listenId);
    final streamFuture = interface.getListenStreamUrl(listenId);

    final detailsResult = await detailsFuture;
    final streamResult = await streamFuture;

    String? error;
    var title = '';
    var artist = '';
    var coverUrl = '';
    var streamUrl = '';
    var isLiked = false;
    var likeCount = 0;
    var startAt = Duration.zero;

    detailsResult.fold((failure) => error = failure.uiMessage, (success) {
      title = success.data?.title ?? '';
      artist = success.data?.artist ?? '';
      coverUrl = success.data?.coverUrl ?? '';
      isLiked = success.data?.isLiked ?? false;
      likeCount = success.data?.likeCount ?? 0;
      startAt =
          success.data?.userProgress?.resumePosition(
            success.data?.durationMs ?? 0,
          ) ??
          Duration.zero;
    });
    streamResult.fold((failure) => error ??= failure.uiMessage, (success) {
      streamUrl = success.data?.streamUrl ?? '';
    });

    isLoadingSong.value = false;

    if (streamUrl.isEmpty) {
      errorMessage.value = error ?? 'Unable to load song.';
      return;
    }

    Get.find<PlayerController>().play(
      title: title,
      artist: artist,
      imageAsset: coverUrl,
      audioAsset: streamUrl,
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
