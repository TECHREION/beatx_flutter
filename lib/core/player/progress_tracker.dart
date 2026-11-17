import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import 'player_controller.dart';
import 'progress_store.dart';

/// Sends a position to the server. Returns false when it did not get there
/// (offline, say), so the next save tries again.
typedef ProgressSaver =
    Future<bool> Function(String id, int positionMs, bool completed);

/// Saves how far the shared player has got into one item (an episode, a
/// chapter), so the next play resumes there.
///
/// The position is sent at most once every [interval] while it plays, and
/// straight away whenever playback stops short of that: a pause, the item
/// ending (marked completed), another track replacing it, the app going to
/// the background, or [flush]. Every save is also kept on the device
/// ([ProgressStore]), so a download played offline resumes too.
///
/// Tracking is tied to the play session that started it and ends by itself
/// once the player moves on to something else.
class ProgressTracker with WidgetsBindingObserver {
  ProgressTracker({this.interval = const Duration(seconds: 10)});

  final Duration interval;

  /// How close to the end counts as having played it through, when the
  /// player has already moved on before saying so.
  static const _endSlack = Duration(seconds: 2);

  String _id = '';
  ProgressSaver? _saver;
  int _session = -1;

  int _positionMs = 0;
  int _durationMs = 0;
  int _lastSavedMs = -1;
  DateTime? _lastSavedAt;
  bool _completedSaved = false;

  final _workers = <Worker>[];

  static PlayerController get _player => Get.isRegistered<PlayerController>()
      ? Get.find<PlayerController>()
      : Get.put(PlayerController(), permanent: true);

  /// The id being tracked, or '' when none.
  String get trackedId => _id;

  void _attach() {
    if (_workers.isNotEmpty) return;
    WidgetsBinding.instance.addObserver(this);
    final player = _player;
    _workers.addAll([
      ever<Duration>(player.position, _onPosition),
      ever<Duration>(player.duration, (d) {
        if (_isCurrent && d > Duration.zero) _durationMs = d.inMilliseconds;
      }),
      ever<bool>(player.isPlaying, _onPlayingChanged),
      ever<int>(player.playCount, (_) => _onSessionChanged()),
    ]);
  }

  /// Starts tracking [id], saved through [save]. Call right after
  /// `PlayerController.play` has been handed it.
  void start(String id, ProgressSaver save) {
    if (id.isEmpty) return;
    _attach();
    _id = id;
    _saver = save;
    _session = _player.playCount.value;
    _positionMs = 0;
    _durationMs = 0;
    _lastSavedMs = -1;
    _lastSavedAt = null;
    _completedSaved = false;
  }

  /// Saves the position reached right now.
  Future<void> flush() => _save();

  /// Saves one last time and stops tracking.
  Future<void> stop() async {
    await _save();
    _id = '';
    _saver = null;
    _session = -1;
  }

  bool get _isCurrent => _id.isNotEmpty && _player.playCount.value == _session;

  bool get _reachedEnd =>
      _durationMs > 0 && _positionMs >= _durationMs - _endSlack.inMilliseconds;

  void _onPosition(Duration position) {
    if (!_isCurrent || position <= Duration.zero) return;
    _positionMs = position.inMilliseconds;

    final lastSavedAt = _lastSavedAt;
    // The first tick only marks the start of the interval, so an item is not
    // saved the instant it begins.
    if (lastSavedAt == null) {
      _lastSavedAt = DateTime.now();
      return;
    }
    if (DateTime.now().difference(lastSavedAt) < interval) return;
    unawaited(_save());
  }

  void _onPlayingChanged(bool playing) {
    if (!_isCurrent) return;
    if (playing) {
      // Played again after finishing: no longer "completed".
      _completedSaved = false;
      return;
    }
    unawaited(_save(completed: _reachedEnd));
  }

  /// Another track took over. The player has already reset its position, so
  /// save what was recorded before the switch — as finished when it got to
  /// the end (a queue moving on by itself).
  void _onSessionChanged() {
    if (_id.isEmpty || _player.playCount.value == _session) return;
    unawaited(_save(completed: _reachedEnd));
    _id = '';
    _session = -1;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      unawaited(_save());
    }
  }

  Future<void> _save({bool completed = false}) async {
    final id = _id;
    final saver = _saver;
    if (id.isEmpty || saver == null) return;

    final positionMs = completed && _durationMs > 0 ? _durationMs : _positionMs;
    // Nothing worth saving before playback has moved, nor after the item has
    // been marked finished.
    if (positionMs <= 0 || (_completedSaved && !completed)) return;
    if (!completed && positionMs == _lastSavedMs) return;

    _lastSavedMs = positionMs;
    _lastSavedAt = DateTime.now();
    if (completed) _completedSaved = true;

    // On the device first: it is what an offline play resumes from.
    ProgressStore.save(id, positionMs, completed: completed);

    final saved = await saver(id, positionMs, completed);
    if (!saved && id == _id) {
      // Let a later save try again from wherever playback has reached.
      _lastSavedMs = -1;
      if (completed) _completedSaved = false;
    }
  }
}
