import 'package:audioplayers/audioplayers.dart';
import 'package:get/get.dart';

class PlayerController extends GetxController {
  final _player = AudioPlayer();

  final isPlaying = false.obs;
  final title = ''.obs;
  final artist = ''.obs;
  final imageAsset = ''.obs;
  final audioAsset = ''.obs;
  final position = Rx<Duration>(Duration.zero);
  final duration = Rx<Duration>(Duration.zero);
  // Increments on every play() call — guaranteed to fire ever() listeners
  // even when the same song is replayed after dismissal.
  final playCount = 0.obs;

  @override
  void onInit() {
    super.onInit();
    _player.onPositionChanged.listen((pos) => position.value = pos);
    _player.onDurationChanged.listen((dur) => duration.value = dur);
    _player.onPlayerComplete.listen((_) {
      isPlaying.value = false;
      position.value = Duration.zero;
    });
  }

  Future<void> play({
    required String title,
    required String artist,
    required String imageAsset,
    required String audioAsset,
  }) async {
    playCount.value++;
    this.title.value = title;
    this.artist.value = artist;
    this.imageAsset.value = imageAsset;
    this.audioAsset.value = audioAsset;
    position.value = Duration.zero;
    duration.value = Duration.zero;
    isPlaying.value = true;
    await _player.stop();
    await _player.play(AssetSource(audioAsset));
  }

  Future<void> seek(Duration position) async {
    this.position.value = position;
    await _player.seek(position);
  }

  Future<void> pause() async {
    isPlaying.value = false;
    await _player.pause();
  }

  Future<void> resume() async {
    isPlaying.value = true;
    await _player.resume();
  }

  Future<void> stop() async {
    isPlaying.value = false;
    await _player.stop();
    title.value = '';
    artist.value = '';
    imageAsset.value = '';
    audioAsset.value = '';
    position.value = Duration.zero;
    duration.value = Duration.zero;
  }

  @override
  void onClose() {
    _player.dispose();
    super.onClose();
  }
}
