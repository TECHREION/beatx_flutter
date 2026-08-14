import 'dart:async';

import 'package:app_pigeon/app_pigeon.dart';
import 'package:get/get.dart';

import '../../../core/player/player_controller.dart';
import '../services/podcast_interface.dart';
import '../services/podcast_interface_impl.dart';

/// Reports podcast listening progress to the backend while an episode plays.
///
/// Once [start] is called the current player position is POSTed every
/// [_interval]. The shared [PlayerController] is also used for songs and
/// audiobooks, so tracking is tied to the play session that started it and
/// ends by itself as soon as the player moves on to a different track.
class SaveProgressController extends GetxController {
  static const Duration _interval = Duration(seconds: 10);

  Timer? _timer;
  String _episodeId = '';
  int _playSession = -1;
  int _lastSavedMs = -1;

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

  /// Starts reporting progress for [episodeId]. Call right after playback
  /// begins; any episode already being tracked is flushed and dropped.
  void start(String episodeId) {
    if (episodeId.isEmpty) return;

    stop();

    _episodeId = episodeId;
    _playSession = _playerController().playCount.value;
    _lastSavedMs = -1;
    _timer = Timer.periodic(_interval, (_) => _tick());
  }

  /// Stops reporting and saves the position reached one last time, so the
  /// final seconds before a pause or a screen exit are not lost.
  void stop() {
    _timer?.cancel();
    _timer = null;

    if (_episodeId.isEmpty) return;

    if (_isCurrentSession) _save(_positionMs);
    _episodeId = '';
    _playSession = -1;
  }

  void _tick() {
    // The shared player moved on to another track — nothing left to report.
    if (!_isCurrentSession) {
      stop();
      return;
    }

    final player = _playerController();

    // Playback finished or was stopped: the position resets to zero, so there
    // is nothing more to send for this episode.
    if (!player.isPlaying.value) {
      if (_positionMs == 0) stop();
      return;
    }

    _save(_positionMs);
  }

  bool get _isCurrentSession =>
      _playerController().playCount.value == _playSession;

  int get _positionMs => _playerController().position.value.inMilliseconds;

  Future<void> _save(int positionMs) async {
    if (positionMs <= 0 || positionMs == _lastSavedMs) return;

    final episodeId = _episodeId;
    _lastSavedMs = positionMs;

    final result = await _podcastInterface().saveProgress(
      episodeId,
      positionMs,
    );

    // Let the next tick retry from wherever playback has reached by then.
    result.fold((failure) => _lastSavedMs = -1, (success) {});
  }

  @override
  void onClose() {
    stop();
    super.onClose();
  }
}
