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

  RxDouble progress = 0.0.obs;

  RxBool autoPlay = true.obs;

  RxBool isPlaying = false.obs;

  String? _loadedVideoId;

  final upNextList = <MusicModel>[
    MusicModel(
      title: 'Neon Dreams: The Making of Pulse',
      artist: 'Lumina Synthesis',
      image:
          'https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f',
      duration: '03:42',
      description: '',
      views: 'NEW VIDEO',
    ),

    MusicModel(
      title: 'Cybernetic Resonance (Official Audio)',
      artist: 'Vector Soul',
      image:
          'https://images.unsplash.com/photo-1511379938547-c1f69419868d',
      duration: '05:18',
      description: '',
      views: '450K views',
    ),

    MusicModel(
      title: 'The Architecture of Sound: Synthesis 101',
      artist: 'BeatX Labs',
      image:
          'https://images.unsplash.com/photo-1500530855697-b586d89ba3ee',
      duration: '04:01',
      description: '',
      views: '12K views',
    ),
  ].obs;

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

    final detailsResult = await detailsRequest;
    final streamUrlResult = await streamUrlRequest;

    detailsResult.fold(
      (failure) => errorMessage.value = failure.uiMessage,
      (success) => details.value = success.data,
    );

    streamUrlResult.fold(
      (failure) => errorMessage.value = failure.uiMessage,
      (success) => streamUrlData.value = success.data,
    );

    isLoading.value = false;
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
