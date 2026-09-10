import 'package:app_pigeon/app_pigeon.dart';
import 'package:get/get.dart';

import '../model/get_stream_url_model.dart';
import '../model/video_details_model.dart';
import '../model/video_progress_model.dart';
import '../model/watch_model.dart';
import '../services/watch_interface.dart';
import '../services/watch_interface_impl.dart';

class MusicPlayerController extends GetxController {
  final details = Rxn<VideoDetailsModel>();
  final streamUrlData = Rxn<VideoStreamUrlModel>();
  final isLoading = false.obs;
  final errorMessage = ''.obs;

  final isLiked = false.obs;
  final likeCount = 0.obs;

  RxDouble progress = 0.0.obs;

  RxBool autoPlay = true.obs;

  RxBool isPlaying = false.obs;

  String? _loadedVideoId;

  final upNextList = <VideoModel>[].obs;

  /// How often the position reached is reported while a video plays. The
  /// player ticks several times a second, which is far more often than a
  /// resume point needs to be written.
  static const Duration _saveInterval = Duration(seconds: 10);

  /// The latest progress known for the loaded video: what the details
  /// response reported on load, then whatever each save returns.
  final savedProgress = Rxn<VideoProgressModel>();

  /// The video the counters below belong to, so a position from a player
  /// that is being torn down is never saved against the video replacing it.
  String? _trackedVideoId;
  int _lastSavedMs = -1;
  DateTime? _lastSavedAt;
  bool _completedSaved = false;

  /// Id of whatever is loaded, so the screen can tell what is already playing.
  String? get currentVideoId => _loadedVideoId;

  /// What auto-play rolls on to when the current video ends: the top of Up
  /// Next, skipping the current video in case the related list includes it.
  VideoModel? get nextUpNext {
    for (final video in upNextList) {
      if (video.id != _loadedVideoId) return video;
    }
    return null;
  }

  VideoInterface _videoInterface() {
    if (!Get.isRegistered<VideoInterface>() &&
        Get.isRegistered<AuthorizedPigeon>()) {
      Get.put<VideoInterface>(
        VideoInterfaceImpl(Get.find<AuthorizedPigeon>()),
      );
    }
    return Get.find<VideoInterface>();
  }

  /// Where the player should start: whatever position the server has for
  /// this video, measured against its own duration.
  Duration get resumePosition =>
      savedProgress.value?.resumePosition(details.value?.durationMs ?? 0) ??
      Duration.zero;

  Future<void> loadVideo(String videoId) async {
    if (videoId.isEmpty || _loadedVideoId == videoId) return;
    _loadedVideoId = videoId;
    _resetProgressTracking(videoId);

    isLoading.value = true;
    errorMessage.value = '';
    // Dropped so the screen shows this video's own state while it loads, and
    // so the stream url lands as a fresh value for the player to react to
    // rather than the previous video's still sitting there.
    streamUrlData.value = null;
    details.value = null;

    final videoInterface = _videoInterface();
    final detailsRequest = videoInterface.videoDetails(videoId);
    final streamUrlRequest = videoInterface.getStreamUrl(videoId);
    final relatedRequest = videoInterface.relatedVideos(videoId);

    final detailsResult = await detailsRequest;
    final streamUrlResult = await streamUrlRequest;
    final relatedResult = await relatedRequest;

    detailsResult.fold(
      (failure) => errorMessage.value = failure.uiMessage,
      (success) {
        details.value = success.data;
        savedProgress.value = success.data?.userProgress;
        isLiked.value = success.data?.isLiked ?? false;
        likeCount.value = success.data?.likeCount ?? 0;
      },
    );

    streamUrlResult.fold(
      (failure) => errorMessage.value = failure.uiMessage,
      (success) => streamUrlData.value = success.data,
    );

    relatedResult.fold(
      (failure) => errorMessage.value = failure.uiMessage,
      (success) => upNextList.assignAll(success.data ?? const []),
    );

    isLoading.value = false;
  }

  Future<void> toggleLike() async {
    final videoId = _loadedVideoId;
    if (videoId == null) return;

    final result = await _videoInterface().likeUnlike(videoId);

    result.fold(
      (failure) => errorMessage.value = failure.uiMessage,
      (success) {
        isLiked.value = success.data?.liked ?? isLiked.value;
        likeCount.value = success.data?.likeCount ?? likeCount.value;
      },
    );
  }

  void togglePlay() {
    isPlaying.value = !isPlaying.value;
  }

  void updateProgress(double value) {
    progress.value = value;
  }

  void toggleAutoPlay(bool value) {
    autoPlay.value = value;
  }

  void _resetProgressTracking(String videoId) {
    _trackedVideoId = videoId;
    savedProgress.value = null;
    _lastSavedMs = -1;
    _lastSavedAt = null;
    _completedSaved = false;
  }

  /// Reports the position reached, at most once every [_saveInterval].
  ///
  /// Called from the player's own tick, so it has to be cheap and silent:
  /// a save that fails is simply retried on a later tick.
  void reportProgress(Duration position, Duration duration) {
    final now = DateTime.now();
    final lastSavedAt = _lastSavedAt;
    if (lastSavedAt != null && now.difference(lastSavedAt) < _saveInterval) {
      return;
    }

    _saveProgress(
      positionMs: position.inMilliseconds,
      durationMs: duration.inMilliseconds,
    );
  }

  /// Saves the position reached right now, without waiting for the interval.
  /// Called when playback stops — a pause, a switch to another video, or
  /// leaving the screen — so the last seconds watched are not lost.
  Future<void> flushProgress(Duration position, Duration duration) async {
    await _saveProgress(
      positionMs: position.inMilliseconds,
      durationMs: duration.inMilliseconds,
      force: true,
    );
  }

  /// Marks the video watched to the end, so it starts over next time rather
  /// than resuming at its last frame.
  Future<void> markCompleted(Duration duration) async {
    await _saveProgress(
      positionMs: duration.inMilliseconds,
      durationMs: duration.inMilliseconds,
      completed: true,
      force: true,
    );
  }

  Future<void> _saveProgress({
    required int positionMs,
    required int durationMs,
    bool completed = false,
    bool force = false,
  }) async {
    final videoId = _trackedVideoId;
    if (videoId == null || videoId != _loadedVideoId) return;

    // Nothing worth saving before playback has actually moved, and nothing
    // left to save once the video has been marked finished.
    if (positionMs <= 0 || (_completedSaved && !completed)) return;
    if (!force && positionMs == _lastSavedMs) return;

    // A stale tick can report past the end of a re-cut video.
    final boundedMs =
        durationMs > 0 ? positionMs.clamp(0, durationMs) : positionMs;

    _lastSavedMs = boundedMs;
    _lastSavedAt = DateTime.now();
    if (completed) _completedSaved = true;

    final result = await _videoInterface().saveVideoProgress(
      videoId,
      positionMs: boundedMs,
      completed: completed,
    );

    result.fold(
      (failure) {
        // Let the next tick retry from wherever playback has reached by then.
        _lastSavedMs = -1;
        _lastSavedAt = null;
        if (completed) _completedSaved = false;
      },
      (success) {
        // Keeps the resume point in step without re-fetching the details.
        if (success.data != null && videoId == _loadedVideoId) {
          savedProgress.value = success.data;
        }
      },
    );
  }
}
