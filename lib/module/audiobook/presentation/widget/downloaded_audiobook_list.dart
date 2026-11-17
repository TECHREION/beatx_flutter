import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/common/widget/now_playing_sheet.dart';
import '../../../../core/notifiers/snackbar_notifier.dart';
import '../../../../core/player/now_playing.dart';
import '../../../../core/player/player_controller.dart';
import '../../../home/model/downloaded_song_model.dart';
import '../../../home/presentation/screens/audio_play_screen.dart';
import '../../../home/presentation/widgets/downloaded_item_list.dart';
import '../../controller/audiobook_download_controller.dart';

/// The audiobooks saved on this device, for the Downloads screen. Tapping a
/// book lists its chapters; any of them plays with the rest queued, all from
/// the device.
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
    chapters = inOrder(chapters);
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
    // Which book this is and its chapters, so the player can say "Chapter 3
    // of 12" rather than show a bare chapter title.
    final book = chapters.first;
    attachNowPlaying(
      NowPlayingContext(
        kind: NowPlayingKind.chapter,
        collectionId: book.groupId,
        collectionTitle: book.groupTitle,
        collectionSubtitle: book.artist,
        collectionCoverUrl: downloads.coverPath(book) ?? book.artworkUrl,
        entries: [
          for (var i = 0; i < chapters.length; i++)
            NowPlayingEntry(
              id: chapters[i].id,
              title: chapters[i].title,
              label: chapterLabel(chapters[i], i),
              durationMs: chapters[i].durationMs,
            ),
        ],
        playEntry: start,
      ),
    );
    final started = start(first);
    Get.to(
      () => const PlayerScreen(),
      transition: Transition.downToUp,
      preventDuplicates: true,
    );
    await started;
  }

  /// A book's files in chapter order. Saved files carry their chapter number;
  /// the list order is only a fallback.
  static List<DownloadedSong> inOrder(List<DownloadedSong> chapters) {
    final indexed = [for (var i = 0; i < chapters.length; i++) (i, chapters[i])]
      ..sort((a, b) {
        final an = a.$2.trackNumber, bn = b.$2.trackNumber;
        if (an > 0 && bn > 0 && an != bn) return an.compareTo(bn);
        return a.$1.compareTo(b.$1);
      });
    return [for (final (_, chapter) in indexed) chapter];
  }

  static String chapterLabel(DownloadedSong chapter, int index) =>
      'Chapter ${chapter.trackNumber > 0 ? chapter.trackNumber : index + 1}';

  /// Lists a saved book's chapters so the listener can pick where to start.
  static Future<void> showChapters(
    BuildContext context,
    List<DownloadedSong> chapters,
  ) {
    final ordered = inOrder(chapters);
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF111214),
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: ordered.length > 6 ? 0.75 : 0.55,
        minChildSize: 0.35,
        maxChildSize: 0.95,
        builder: (context, scroll) =>
            _ChaptersSheet(chapters: ordered, scroll: scroll),
      ),
    );
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
      onPlay: (files) => showChapters(context, files),
      playLabel: 'Show Chapters',
    );
  }
}

/// A downloaded book: its cover and title, "Play from start", and every
/// chapter, the one playing marked. Works with no connection.
class _ChaptersSheet extends StatelessWidget {
  const _ChaptersSheet({required this.chapters, required this.scroll});

  final List<DownloadedSong> chapters;
  final ScrollController scroll;

  static const _accent = Color(0xFF9BFF4D);

  void _play(BuildContext context, int index) {
    Navigator.of(context).pop();
    DownloadedAudiobookList.play(chapters, index: index);
  }

  @override
  Widget build(BuildContext context) {
    final book = chapters.first;
    final downloads = AudiobookDownloadController.instance;
    final totalMs = chapters.fold(0, (sum, c) => sum + c.durationMs);
    final player = Get.isRegistered<PlayerController>()
        ? Get.find<PlayerController>()
        : Get.put(PlayerController(), permanent: true);

    return Obx(() {
      final playingId = player.trackId.value;
      final playing = player.isPlaying.value;
      final current = chapters.indexWhere((c) => c.id == playingId);
      return ListView(
        controller: scroll,
        padding: EdgeInsets.only(
          bottom: 24 + MediaQuery.paddingOf(context).bottom,
        ),
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 14),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                CoverImage(
                  url: downloads.coverPath(book) ?? book.artworkUrl,
                  size: 72,
                  radius: 14,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'DOWNLOADED AUDIOBOOK',
                        style: TextStyle(
                          color: _accent,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        book.groupTitle.isNotEmpty
                            ? book.groupTitle
                            : book.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        [
                          if (book.artist.isNotEmpty) book.artist,
                          chapters.length == 1
                              ? '1 chapter'
                              : '${chapters.length} chapters',
                          if (totalMs > 0) formatClock(totalMs),
                        ].join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
            child: SizedBox(
              height: 48,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: _accent,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                // Carries on where the listener is, if this book is playing.
                onPressed: () => _play(context, current < 0 ? 0 : current),
                icon: const Icon(Icons.play_arrow_rounded),
                label: Text(
                  current < 0
                      ? 'Play from Chapter 1'
                      : 'Continue ${DownloadedAudiobookList.chapterLabel(chapters[current], current)}',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 14, 20, 4),
            child: Text(
              'Chapters',
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          for (var i = 0; i < chapters.length; i++)
            _ChapterTile(
              label: DownloadedAudiobookList.chapterLabel(chapters[i], i),
              title: chapters[i].title,
              durationMs: chapters[i].durationMs,
              isCurrent: i == current,
              isPlaying: i == current && playing,
              onTap: () => _play(context, i),
            ),
        ],
      );
    });
  }
}

class _ChapterTile extends StatelessWidget {
  const _ChapterTile({
    required this.label,
    required this.title,
    required this.durationMs,
    required this.isCurrent,
    required this.isPlaying,
    required this.onTap,
  });

  final String label;
  final String title;
  final int durationMs;
  final bool isCurrent;
  final bool isPlaying;
  final VoidCallback onTap;

  static const _accent = Color(0xFF9BFF4D);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            Icon(
              isCurrent
                  ? (isPlaying ? Icons.graphic_eq_rounded : Icons.pause)
                  : Icons.play_circle_outline_rounded,
              color: isCurrent ? _accent : Colors.white54,
              size: 26,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isCurrent ? '$label · NOW PLAYING' : label,
                    style: TextStyle(
                      color: isCurrent ? _accent : Colors.white54,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isCurrent ? _accent : Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            if (durationMs > 0) ...[
              const SizedBox(width: 12),
              Text(
                formatClock(durationMs),
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
            const SizedBox(width: 8),
            const Icon(
              Icons.download_done_rounded,
              color: Colors.white38,
              size: 16,
              semanticLabel: 'Downloaded',
            ),
          ],
        ),
      ),
    );
  }
}
