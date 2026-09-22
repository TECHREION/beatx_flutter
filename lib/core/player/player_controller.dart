import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:app_pigeon/app_pigeon.dart';
import 'package:flutter/foundation.dart' show debugPrint, kDebugMode, kIsWeb;
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';

class PlayerController extends GetxController {
  static const _measuredDurationsKey = 'measured_track_durations';
  // Room for a long listening history without letting the cache grow without
  // bound. The least recently measured ids drop off first.
  static const _maxMeasuredDurations = 200;

  /// The equalizer effect attached to this player's audio pipeline.
  ///
  /// just_audio fixes the effect list at player-construction time, so the
  /// effect cannot be created independently and handed to the player later.
  /// [EqualizerService] reads this instance off the controller rather than
  /// building its own.
  ///
  /// Android-only, and it must only ever be added to the pipeline on Android.
  ///
  /// just_audio activates every effect in an [AudioPipeline] regardless of
  /// platform, and the Darwin plugin has no implementation for
  /// `androidEqualizerGetParameters`. Including this effect on iOS therefore
  /// throws a MissingPluginException out of `setUrl`, which stops the source
  /// loading at all — playback silently never starts.
  final androidEqualizer = AndroidEqualizer();

  /// True only where the native equalizer effect actually exists.
  static final bool _supportsAndroidEffects = !kIsWeb && Platform.isAndroid;

  late final AudioPlayer _player = AudioPlayer(
    audioPipeline: AudioPipeline(
      androidAudioEffects: [
        if (_supportsAndroidEffects) androidEqualizer,
      ],
    ),
  );
  final _storage = const FlutterSecureStorage();

  /// The underlying player, exposed solely so [BeatxAudioHandler] can mirror
  /// its streams into the notification/lock-screen playback state. Feature
  /// code must go through this controller's own API instead.
  AudioPlayer get internalPlayer => _player;

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

  /// Set when a track could not be loaded, cleared when one loads. Lets a
  /// screen tell the user why nothing is playing instead of showing a
  /// transport that claims to be running.
  final loadError = RxnString();

  // Lengths read off the stream, in milliseconds by track id. The API reports
  // 0ms for media whose audio has not been measured, so screens that need a
  // length keep getting the real one after the player has moved on — and
  // after a restart, since the map is stored. Observable so a screen showing
  // a remembered length updates once [_restoreMeasuredDurations] lands.
  final _measuredDurations = <String, int>{}.obs;

  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration?>? _durationSub;
  StreamSubscription<PlayerState>? _stateSub;

  @override
  void onInit() {
    super.onInit();
    _restoreMeasuredDurations();
    _positionSub = _player.positionStream.listen((pos) => position.value = pos);
    _durationSub = _player.durationStream.listen((dur) {
      // just_audio reports null until the length is known; the old player
      // simply never emitted in that case, so keep the last known value.
      if (dur == null) return;
      duration.value = dur;
      _rememberDuration(trackId.value, dur);
    });
    // audioplayers had a dedicated completion callback. just_audio folds it
    // into the player state, so filter for the completed edge and reproduce
    // the previous behaviour exactly: stop reporting playback and rewind the
    // reported position. Deliberately no auto-advance — there is no queue.
    _stateSub = _player.playerStateStream.listen((state) {
      if (state.processingState != ProcessingState.completed) return;
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
    final session = ++playCount.value;
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
    final initialPosition = startAt > Duration.zero ? startAt : null;

    // Callers invoke play() without awaiting or catching, so a load failure
    // here would otherwise surface as nothing at all: the transport would sit
    // showing a pause button over silence. Report it instead.
    try {
      if (isNetworkSource) {
        await _player.setUrl(audioAsset, initialPosition: initialPosition);
      } else {
        await _player.setAsset(
          _assetPath(audioAsset),
          initialPosition: initialPosition,
        );
      }
    } catch (error, stackTrace) {
      // A newer play() already superseded this one; its state must stand.
      if (playCount.value != session) return;
      isPlaying.value = false;
      loadError.value = 'This track could not be played.';
      if (kDebugMode) {
        debugPrint('[Player] failed to load source: $error\n$stackTrace');
      }
      return;
    }

    if (playCount.value != session) return;
    loadError.value = null;

    // Deliberately not awaited: just_audio's play() future completes when
    // playback *finishes*, not when it starts. Awaiting it would leave every
    // caller hanging for the length of the track.
    unawaited(_player.play());
  }

  /// audioplayers resolved an [AssetSource] relative to `assets/`, so callers
  /// pass paths like `audio/music1.mp3`. just_audio wants the full asset key,
  /// so restore the prefix the old player used to add implicitly.
  String _assetPath(String asset) =>
      asset.startsWith('assets/') ? asset : 'assets/$asset';

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
    // Same as in [play]: this future completes on playback end, never await it.
    unawaited(_player.play());
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
    loadError.value = null;
  }

  @override
  void onClose() {
    _positionSub?.cancel();
    _durationSub?.cancel();
    _stateSub?.cancel();
    // Disposing the player also tears down the audio pipeline, which releases
    // the native equalizer effect. Nothing else releases it.
    _player.dispose();
    super.onClose();
  }
}
