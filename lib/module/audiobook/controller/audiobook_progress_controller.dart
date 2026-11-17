import 'dart:async';

import 'package:app_pigeon/app_pigeon.dart';
import 'package:get/get.dart';

import '../../../core/player/progress_store.dart';
import '../../../core/player/progress_tracker.dart';
import '../services/audio_book_interface.dart';
import '../services/audio_book_interface_impl.dart';

/// Saves where the listener is in an audiobook — the chapter and how far into
/// it — so "Listen Now" picks up there next time, on this device or another.
///
/// The shared [ProgressTracker] decides when (every 10 s while playing, and
/// at once on a pause, a chapter ending, another track taking over, or the
/// app going to the background). Positions are also kept on the device, by
/// chapter, so a downloaded book played offline resumes too.
class AudiobookProgressController extends GetxController {
  static AudiobookProgressController get instance =>
      Get.isRegistered<AudiobookProgressController>()
      ? Get.find<AudiobookProgressController>()
      : Get.put(AudiobookProgressController(), permanent: true);

  final _tracker = ProgressTracker();

  AudioBookInterface _interface() {
    if (!Get.isRegistered<AudioBookInterface>() &&
        Get.isRegistered<AuthorizedPigeon>()) {
      Get.put<AudioBookInterface>(
        AudioBookInterfaceImpl(Get.find<AuthorizedPigeon>()),
      );
    }
    return Get.find<AudioBookInterface>();
  }

  /// Stands in for the current chapter of a book listened to the end.
  static const finished = '#finished';

  /// The key under which the device remembers a book's current chapter.
  static String bookKey(String audiobookId) => 'audiobook:$audiobookId';

  /// Starts saving progress for [chapterId] of [audiobookId]. Call right
  /// after the chapter has been handed to the player. [nextChapterId] is the
  /// chapter after it, or null for the last one — whose end is the end of
  /// the book.
  void start({
    required String audiobookId,
    required String chapterId,
    required String? nextChapterId,
  }) {
    final isLastChapter = nextChapterId == null || nextChapterId.isEmpty;
    if (audiobookId.isEmpty || chapterId.isEmpty) return;
    ProgressStore.setCurrent(bookKey(audiobookId), chapterId);
    _tracker.start(chapterId, (id, positionMs, completed) async {
      // A chapter played through: next time starts at the one after it, or
      // — the book finished — from the top.
      if (completed) {
        ProgressStore.setCurrent(
          bookKey(audiobookId),
          isLastChapter ? finished : nextChapterId,
        );
      }
      // `completed` means the whole book to the server; a chapter ending
      // only moves the position to its end.
      final result = await _interface().saveAudiobookProgress(
        audiobookId,
        chapterId: id,
        positionMs: positionMs,
        completed: completed && isLastChapter,
      );
      return result.isRight();
    });
  }

  /// Saves the position reached right now.
  Future<void> flush() => _tracker.flush();

  @override
  void onClose() {
    unawaited(_tracker.stop());
    super.onClose();
  }
}
