import 'package:beatx_flutter/module/watch/model/music_video_model.dart';
import 'package:get/get.dart';

class MusicPlayerController extends GetxController {

  RxDouble progress = 102.0.obs;

  RxBool autoPlay = true.obs;

  RxBool isPlaying = false.obs;

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