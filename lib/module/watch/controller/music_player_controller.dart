import 'package:app_pigeon/app_pigeon.dart';
import 'package:get/get.dart';

import '../model/get_stream_url_model.dart';
import '../model/video_details_model.dart';
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

  VideoInterface _videoInterface() {
    if (!Get.isRegistered<VideoInterface>() &&
        Get.isRegistered<AuthorizedPigeon>()) {
      Get.put<VideoInterface>(
        VideoInterfaceImpl(Get.find<AuthorizedPigeon>()),
      );
    }
    return Get.find<VideoInterface>();
  }

  Future<void> loadVideo(String videoId) async {
    if (videoId.isEmpty || _loadedVideoId == videoId) return;
    _loadedVideoId = videoId;

    isLoading.value = true;
    errorMessage.value = '';

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
}
