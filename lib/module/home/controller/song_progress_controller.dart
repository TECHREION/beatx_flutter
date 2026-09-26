import 'dart:async';

import 'package:app_pigeon/app_pigeon.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart' show ProcessingState;

import '../../../core/player/player_controller.dart';
import '../services/listen_interface.dart';
import '../services/lister_interface_impl.dart';

/// Reports how far the user has listened to the song that is playing, so the
/// next play — after a restart or a fresh sign-in — resumes where they left off.
///
/// The position is saved at most once every [_interval] while the song plays,
/// and straight away whenever playback stops short of that: a pause, the song
/// finishing, another track replacing it, the app going to the background, or
/// a logout ([flush]).
///
/// The shared [PlayerController] also plays podcasts and audiobooks, so
/// tracking is tied to the play session that started it and ends by itself
/// once the player moves on to a different track.
class SongProgressController extends GetxController
    with WidgetsBindingObserver {
  static const Duration _interval = Duration(seconds: 10);

  static SongProgressController get instance {
    if (!Get.isRegistered<SongProgressController>()) {
      Get.put(SongProgressController(), permanent: true);
    }
    return Get.find<SongProgressController>();
  }

  String _songId = '';
  int _playSession = -1;

  /// Last non-zero position the player reported for the tracked song. Kept
  /// separately because the player rewinds to zero on completion and jumps to
  /// the next track's start the moment it is replaced.
  int _positionMs = 0;
  int _lastSavedMs = -1;
  DateTime? _lastSavedAt;
  bool _completedSaved = false;

  final _workers = <Worker>[];

  PlayerController get _player => Get.find<PlayerController>();

  ListenInterface _listenInterface() {
    if (!Get.isRegistered<ListenInterface>() &&
        Get.isRegistered<AuthorizedPigeon>()) {
      Get.put<ListenInterface>(
        ListenInterfaceImpl(Get.find<AuthorizedPigeon>()),
      );
    }
    return Get.find<ListenInterface>();
  }

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    _workers.addAll([
      ever<Duration>(_player.position, _onPosition),
      ever<bool>(_player.isPlaying, _onPlayingChanged),
      ever<int>(_player.playCount, (_) => _onSessionChanged()),
    ]);
  }

  /// Starts tracking [songId]. Call right after [PlayerController.play] has
  /// been handed the song.
  void start(String songId) {
    if (songId.isEmpty) return;

    _songId = songId;
    _playSession = _player.playCount.value;
    _positionMs = 0;
    _lastSavedMs = -1;
    _lastSavedAt = null;
    _completedSaved = false;
  }

  /// Saves the position reached right now. Awaited before a logout, while the
  /// session that owns the progress is still signed in.
  Future<void> flush() => _save();

  bool get _isCurrentSession =>
      _songId.isNotEmpty && _player.playCount.value == _playSession;

  void _onPosition(Duration position) {
    if (!_isCurrentSession || position <= Duration.zero) return;
    _positionMs = position.inMilliseconds;

    final lastSavedAt = _lastSavedAt;
    if (lastSavedAt != null &&
        DateTime.now().difference(lastSavedAt) < _interval) {
      return;
    }
    // The first tick only marks the start of the interval, so a song is not
    // saved the instant it begins.
    if (lastSavedAt == null) {
      _lastSavedAt = DateTime.now();
      return;
    }
    _save();
  }

  void _onPlayingChanged(bool playing) {
    if (!_isCurrentSession) return;

    if (playing) {
      // Played again after finishing: it is no longer "completed".
      _completedSaved = false;
      return;
    }

    final finished =
        _player.internalPlayer.processingState == ProcessingState.completed;
    _save(completed: finished);
  }

  /// Another track took over the player. Its first position has already
  /// replaced the tracked one, so save what was recorded before the switch.
  void _onSessionChanged() {
    if (_songId.isEmpty || _player.playCount.value == _playSession) return;
    _save();
    _songId = '';
    _playSession = -1;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _save();
    }
  }

  Future<void> _save({bool completed = false}) async {
    final songId = _songId;
    if (songId.isEmpty) return;

    final durationMs = _player.duration.value.inMilliseconds;
    final positionMs = completed && durationMs > 0 ? durationMs : _positionMs;

    // Nothing worth saving before playback has actually moved, and nothing
    // left to save once the song has been marked finished.
    if (positionMs <= 0 || (_completedSaved && !completed)) return;
    if (!completed && positionMs == _lastSavedMs) return;

    _lastSavedMs = positionMs;
    _lastSavedAt = DateTime.now();
    if (completed) _completedSaved = true;

    final result = await _listenInterface().saveProgress(
      songId,
      positionMs: positionMs,
      completed: completed,
    );

    result.fold((failure) {
      // Let the next tick retry from wherever playback has reached by then.
      if (songId != _songId) return;
      _lastSavedMs = -1;
      if (completed) _completedSaved = false;
    }, (success) {});
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    for (final worker in _workers) {
      worker.dispose();
    }
    super.onClose();
  }
}
