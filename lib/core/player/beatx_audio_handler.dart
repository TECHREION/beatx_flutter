import 'package:audio_service/audio_service.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';

import 'player_controller.dart';

/// Bridges [PlayerController] to the platform's media notification, lock
/// screen and hardware media buttons.
///
/// The handler owns no playback state of its own. It mirrors the player's
/// streams outward, and routes remote commands back into [PlayerController] so
/// that a notification tap and an in-app tap take exactly the same code path.
///
/// There is deliberately no queue: the app plays one track at a time and has
/// no playlist model, so no skip-to-next/previous controls are advertised
/// rather than advertising buttons that would do nothing.
class BeatxAudioHandler extends BaseAudioHandler with SeekHandler {
  BeatxAudioHandler(this._controller) {
    _publishPlaybackState();
    _publishMediaItem();
  }

  final PlayerController _controller;

  AudioPlayer get _player => _controller.internalPlayer;

  void _publishPlaybackState() {
    _player.playbackEventStream.listen(
      (event) => playbackState.add(_stateFrom(event)),
      // A malformed event must never take down the isolate; playback itself is
      // unaffected and the next event repairs the reported state.
      onError: (Object _, StackTrace _) {},
    );
  }

  PlaybackState _stateFrom(PlaybackEvent event) {
    final playing = _player.playing;
    return PlaybackState(
      controls: [
        if (playing) MediaControl.pause else MediaControl.play,
        MediaControl.stop,
      ],
      systemActions: const {MediaAction.seek},
      androidCompactActionIndices: const [0, 1],
      processingState: _processingStates[_player.processingState]!,
      playing: playing,
      updatePosition: _player.position,
      bufferedPosition: event.bufferedPosition,
      speed: _player.speed,
      queueIndex: event.currentIndex,
    );
  }

  static const _processingStates = <ProcessingState, AudioProcessingState>{
    ProcessingState.idle: AudioProcessingState.idle,
    ProcessingState.loading: AudioProcessingState.loading,
    ProcessingState.buffering: AudioProcessingState.buffering,
    ProcessingState.ready: AudioProcessingState.ready,
    ProcessingState.completed: AudioProcessingState.completed,
  };

  /// Republishes the now-playing metadata whenever the controller starts a new
  /// track. [PlayerController.playCount] increments on every play() call, so it
  /// fires even when the same track is replayed.
  void _publishMediaItem() {
    ever<int>(_controller.playCount, (_) {
      final id = _controller.audioAsset.value;
      if (id.isEmpty) {
        mediaItem.add(null);
        return;
      }
      mediaItem.add(
        MediaItem(
          id: id,
          title: _controller.title.value,
          artist: _controller.artist.value,
          artUri: _artUri(_controller.imageAsset.value),
          duration: _knownDuration(),
        ),
      );
    });

    // The length usually arrives after the track starts, so patch the existing
    // item rather than waiting for it before showing anything.
    ever<Duration>(_controller.duration, (value) {
      final current = mediaItem.value;
      if (current == null || value == Duration.zero) return;
      if (current.duration == value) return;
      mediaItem.add(current.copyWith(duration: value));
    });
  }

  Duration? _knownDuration() {
    final remembered = _controller.measuredDuration(_controller.trackId.value);
    if (remembered != null) return remembered;
    final current = _controller.duration.value;
    return current > Duration.zero ? current : null;
  }

  Uri? _artUri(String imageAsset) {
    if (imageAsset.isEmpty) return null;
    return Uri.tryParse(imageAsset);
  }

  @override
  Future<void> play() => _controller.resume();

  @override
  Future<void> pause() => _controller.pause();

  @override
  Future<void> stop() => _controller.stop();

  @override
  Future<void> seek(Duration position) => _controller.seek(position);
}
