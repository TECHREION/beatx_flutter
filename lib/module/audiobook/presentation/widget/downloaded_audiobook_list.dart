import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/notifiers/snackbar_notifier.dart';
import '../../../../core/player/player_controller.dart';
import '../../../home/model/downloaded_song_model.dart';
import '../../../home/presentation/screens/audio_play_screen.dart';
import '../../../home/presentation/widgets/downloaded_item_list.dart';
import '../../controller/audiobook_download_controller.dart';

/// The audiobooks saved on this device, for the Downloads screen. A book
/// plays from its first chapter with the rest queued, all from the device.
class DownloadedAudiobookList extends StatelessWidget {
  const DownloadedAudiobookList({
    super.key,
    required this.accent,
    required this.formatBytes,
  });

  final Color accent;
  final String Function(int bytes) formatBytes;

  /// Plays a saved book's [chapters], from [index] on, and opens the player.
  static Future<void> play(
    List<DownloadedSong> chapters, {
    int index = 0,
  }) async {
    if (chapters.isEmpty) return;
    if (!Get.isRegistered<PlayerController>()) {
      Get.put(PlayerController(), permanent: true);
    }
    final player = Get.find<PlayerController>();
    final downloads = AudiobookDownloadController.instance;

    Future<bool> start(String chapterId) async {
      final chapter = chapters.firstWhereOrNull((c) => c.id == chapterId);
      final path = chapter == null
          ? null
          : await downloads.playablePath(chapter.id);
      if (chapter == null || path == null) {
        final context = Get.context;
        if (context != null && context.mounted) {
          SnackbarNotifier(
            context: context,
          ).notifyError(message: 'This book is no longer on the device.');
        }
        return false;
      }
      await player.play(
        title: chapter.title,
        artist: chapter.artist,
        imageAsset: downloads.coverPath(chapter) ?? chapter.artworkUrl,
        audioAsset: path,
        trackId: chapter.id,
      );
      return true;
    }

    final first = chapters[index.clamp(0, chapters.length - 1)].id;
    // Set before playing, so play() sees the chapter as part of the queue.
    player.setQueue(
      [for (final chapter in chapters) chapter.id],
      current: first,
      start: start,
    );
    final started = start(first);
    Get.to(
      () => const PlayerScreen(),
      transition: Transition.downToUp,
      preventDuplicates: true,
    );
    await started;
  }

  @override
  Widget build(BuildContext context) {
    return DownloadedItemList(
      controller: AudiobookDownloadController.instance,
      accent: accent,
      formatBytes: formatBytes,
      singular: 'audiobook',
      plural: 'audiobooks',
      placeholderIcon: Icons.menu_book_rounded,
      emptyIcon: Icons.auto_stories_outlined,
      emptyBody:
          'Tap the download button on a book to keep every chapter on this '
          'device and listen without internet.',
      onPlay: play,
    );
  }
}
