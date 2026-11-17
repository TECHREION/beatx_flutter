import 'dart:async';

import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';

import 'music_player_controller.dart';

/// A video that keeps playing in the mini player after its screen was
/// minimized.
class MiniVideoSession {
  MiniVideoSession({
    required this.videoId,
    required this.title,
    required this.channel,
    required this.video,
    required this.details,
  });

  final String videoId;
  final String title;
  final String channel;

  /// The very player the screen was using, so playback carries on without a
  /// hitch and goes back to the screen the same way.
  final VideoPlayerController video;

  /// The screen's controller, kept so a restored screen has its details, Up
  /// Next and progress tracking without loading them again.
  final MusicPlayerController details;
}

/// Holds the video minimized off the player screen (YouTube style).
///
/// The down arrow on the player screen hands its player here and pops; the
/// mini player shows it above every screen. Tapping the mini player opens the
/// screen again, which takes the player back. The back arrow, by contrast,
/// stops the video.
class VideoMiniPlayerController extends GetxService {
  static VideoMiniPlayerController get instance =>
      Get.isRegistered<VideoMiniPlayerController>()
      ? Get.find<VideoMiniPlayerController>()
      : Get.put(VideoMiniPlayerController(), permanent: true);

  /// What the mini player shows. Follows [_current] once the UI may rebuild.
  final session = Rxn<MiniVideoSession>();

  MiniVideoSession? _current;
  bool _reachedEnd = false;

  /// Starts showing [next] in the mini player, stopping anything already
  /// there.
  void minimize(MiniVideoSession next) {
    if (_current != null && _current!.video != next.video) close();
    _current = next;
    _reachedEnd = false;
    next.video.addListener(_onTick);
    _publish();
  }

  /// Hands the player back to a screen opening [videoId].
  ///
  /// Returns null when the mini player holds a different video (or none);
  /// a different video is stopped, since only one plays at a time.
  MiniVideoSession? takeOver(String videoId) {
    final current = _current;
    if (current == null) return null;
    if (current.videoId != videoId) {
      close();
      return null;
    }
    current.video.removeListener(_onTick);
    _current = null;
    _publish();
    return current;
  }

  /// Stops the minimized video and hides the mini player.
  void close() {
    final current = _current;
    if (current == null) return;
    _current = null;
    _publish();

    final video = current.video;
    video.removeListener(_onTick);
    final value = video.value;
    if (value.isInitialized) {
      unawaited(current.details.flushProgress(value.position, value.duration));
    }
    unawaited(video.pause().whenComplete(video.dispose));
  }

  void togglePlay() {
    final video = _current?.video;
    if (video == null) return;
    if (video.value.isPlaying) {
      video.pause();
    } else {
      if (video.value.position >= video.value.duration) {
        video.seekTo(Duration.zero);
        _reachedEnd = false;
      }
      video.play();
    }
  }

  /// Keeps the resume point saved while the video plays minimized.
  void _onTick() {
    final current = _current;
    if (current == null || _reachedEnd) return;
    final value = current.video.value;
    if (!value.isInitialized) return;

    if (value.duration > Duration.zero &&
        !value.isPlaying &&
        value.position >= value.duration) {
      _reachedEnd = true;
      unawaited(current.details.markCompleted(value.duration));
      return;
    }
    if (value.isPlaying) {
      current.details.reportProgress(value.position, value.duration);
    }
  }

  /// A screen hands over or takes back the player from initState/dispose,
  /// when the overlay showing the mini player cannot be asked to rebuild, so
  /// such changes wait for the frame to finish.
  void _publish() {
    final phase = SchedulerBinding.instance.schedulerPhase;
    if (phase == SchedulerPhase.persistentCallbacks ||
        phase == SchedulerPhase.midFrameMicrotasks) {
      SchedulerBinding.instance.addPostFrameCallback(
        (_) => session.value = _current,
      );
    } else {
      session.value = _current;
    }
  }

  @override
  void onClose() {
    close();
    super.onClose();
  }
}
