import 'dart:async';

import 'package:app_pigeon/app_pigeon.dart';
import 'package:get/get.dart';

import '../../../core/player/progress_tracker.dart';
import '../services/podcast_interface.dart';
import '../services/podcast_interface_impl.dart';

/// Reports podcast listening progress to the backend while an episode plays,
/// so the next play of it resumes where the listener left off.
///
/// The shared [ProgressTracker] decides when: every 10 s while playing, and
/// at once on a pause, the episode ending (sent as completed), another track
/// taking over, or the app going to the background. Each position is also
/// kept on the device, so a downloaded episode played offline resumes too.
class SaveProgressController extends GetxController {
  final _tracker = ProgressTracker();

  PodcastInterface _podcastInterface() {
    if (!Get.isRegistered<PodcastInterface>() &&
        Get.isRegistered<AuthorizedPigeon>()) {
      Get.put<PodcastInterface>(
        PodcastInterfaceImpl(Get.find<AuthorizedPigeon>()),
      );
    }
    return Get.find<PodcastInterface>();
  }

  /// Starts reporting progress for [episodeId]. Call right after playback
  /// begins.
  void start(String episodeId) => _tracker.start(episodeId, _send);

  /// Saves the position reached right now without interrupting tracking, so
  /// a resume taken straight afterwards is not behind.
  Future<void> flush() => _tracker.flush();

  /// Saves one last time and stops reporting.
  void stop() => unawaited(_tracker.stop());

  Future<bool> _send(String episodeId, int positionMs, bool completed) async {
    final result = await _podcastInterface().saveProgress(
      episodeId,
      positionMs,
      completed: completed,
    );
    return result.isRight();
  }

  @override
  void onClose() {
    stop();
    super.onClose();
  }
}
