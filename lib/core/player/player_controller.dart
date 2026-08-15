import 'dart:convert';

import 'package:app_pigeon/app_pigeon.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:get/get.dart';

class PlayerController extends GetxController {
  static const _measuredDurationsKey = 'measured_track_durations';
  // Room for a long listening history without letting the cache grow without
  // bound. The least recently measured ids drop off first.
  static const _maxMeasuredDurations = 200;

  final _player = AudioPlayer();
  final _storage = const FlutterSecureStorage();

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
  // Id of whatever is loaded (episode, book, song), or '' when the caller
  // does not track one. Lets a screen tell whether it owns the active track.
  final trackId = ''.obs;

  // Lengths read off the stream, in milliseconds by track id. The API reports
  // 0ms for media whose audio has not been measured, so screens that need a
  // length keep getting the real one after the player has moved on — and
  // after a restart, since the map is stored. Observable so a screen showing
  // a remembered length updates once [_restoreMeasuredDurations] lands.
  final _measuredDurations = <String, int>{}.obs;

  @override
  void onInit() {
    super.onInit();
    _restoreMeasuredDurations();
    _player.onPositionChanged.listen((pos) => position.value = pos);
    _player.onDurationChanged.listen((dur) {
      duration.value = dur;
      _rememberDuration(trackId.value, dur);
    });
    _player.onPlayerComplete.listen((_) {
      isPlaying.value = false;
      position.value = Duration.zero;
    });
  }

  /// Starts [audioAsset]. Pass [startAt] to resume part-way in, and [trackId]
  /// to identify what is playing.
  Future<void> play({
    required String title,
    required String artist,
    required String imageAsset,
    required String audioAsset,
    Duration startAt = Duration.zero,
    String trackId = '',
  }) async {
    playCount.value++;
    this.title.value = title;
    this.artist.value = artist;
    this.imageAsset.value = imageAsset;
    this.audioAsset.value = audioAsset;
    this.trackId.value = trackId;
    position.value = startAt;
    duration.value = Duration.zero;
    isPlaying.value = true;
    await _player.stop();
    final isNetworkSource =
        audioAsset.startsWith('http://') || audioAsset.startsWith('https://');
    await _player.play(
      isNetworkSource ? UrlSource(audioAsset) : AssetSource(audioAsset),
      position: startAt > Duration.zero ? startAt : null,
    );
  }

  /// Length the player measured for [trackId] the last time it was played, or
  /// null if it has never been played on this device.
  Duration? measuredDuration(String trackId) {
    final milliseconds = _measuredDurations[trackId] ?? 0;
    return milliseconds > 0 ? Duration(milliseconds: milliseconds) : null;
  }

  Future<void> _restoreMeasuredDurations() async {
    try {
      final stored = await _storage.read(key: _measuredDurationsKey);
      if (stored == null || stored.isEmpty) return;

      final decoded = jsonDecode(stored);
      if (decoded is! Map) return;

      decoded.forEach((key, value) {
        final milliseconds = value is num ? value.toInt() : 0;
        // Anything measured since launch was read off the stream just now, so
        // it beats whatever was stored.
        if (key is String && milliseconds > 0) {
          _measuredDurations.putIfAbsent(key, () => milliseconds);
        }
      });
    } catch (_) {
      // An unreadable cache is not worth failing playback over — the lengths
      // come back as soon as each track is played again.
    }
  }

  Future<void> _rememberDuration(String trackId, Duration value) async {
    final milliseconds = value.inMilliseconds;
    if (trackId.isEmpty ||
        milliseconds <= 0 ||
        _measuredDurations[trackId] == milliseconds) {
      return;
    }

    _measuredDurations[trackId] = milliseconds;
    // Dart maps keep insertion order, so the front of the map is the oldest.
    while (_measuredDurations.length > _maxMeasuredDurations) {
      _measuredDurations.remove(_measuredDurations.keys.first);
    }

    try {
      await _storage.write(
        key: _measuredDurationsKey,
        value: jsonEncode(Map<String, int>.from(_measuredDurations)),
      );
    } catch (_) {
      // Best effort: the length is still right for the rest of this session.
    }
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
    trackId.value = '';
    position.value = Duration.zero;
    duration.value = Duration.zero;
  }

  @override
  void onClose() {
    _player.dispose();
    super.onClose();
  }
}
