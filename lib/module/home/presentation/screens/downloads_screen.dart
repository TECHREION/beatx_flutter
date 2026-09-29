import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/common/widget/liked_collection.dart';
import '../../../../core/player/player_controller.dart';
import '../../controller/download_controller.dart';
import '../../controller/home_controller.dart';
import '../../model/downloaded_song_model.dart';
import '../widgets/download_actions.dart';
import 'liked_songs_screen.dart';

/// Songs saved on this device. Reads only local storage, so it works with no
/// connection at all.
class DownloadsScreen extends StatelessWidget {
  const DownloadsScreen({super.key});

  static const accent = LikedSongsScreen.accent;
  static const _artGradient = [Color(0xFF4DEBFF), Color(0xFF7B3BFF)];

  static HomeController _homeController() {
    if (!Get.isRegistered<HomeController>()) Get.put(HomeController());
    return Get.find<HomeController>();
  }

  static void _play(DownloadedSong song) =>
      _homeController().playSong(song.id);

  /// Bytes as the largest whole unit, e.g. "428 MB".
  static String formatBytes(int bytes) {
    if (bytes <= 0) return '0 MB';
    const units = ['B', 'KB', 'MB', 'GB'];
    var value = bytes.toDouble();
    var unit = 0;
    while (value >= 1024 && unit < units.length - 1) {
      value /= 1024;
      unit++;
    }
    final digits = value >= 100 || unit < 2 ? 0 : 1;
    return '${value.toStringAsFixed(digits)} ${units[unit]}';
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = DownloadController.instance;

    return Scaffold(
      backgroundColor: LikedPalette.background,
      body: SafeArea(
        child: Column(
          children: [
            const LikedHeader(
              title: 'Downloads',
              subtitle: 'Songs saved for listening offline',
              icon: Icons.download_done_rounded,
              iconColor: accent,
            ),
            const SizedBox(height: 18),
            Obx(
              () => LikedSummaryStrip(
                icon: Icons.download_rounded,
                accent: accent,
                count: ctrl.isReady.value ? ctrl.songs.length : null,
                noun: 'Song',
                onTap: ctrl.songs.isEmpty
                    ? null
                    : () => _play(ctrl.songs.first),
              ),
            ),
            Obx(
              () => ctrl.songs.isEmpty
                  ? const SizedBox(height: 16)
                  : Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.sd_storage_outlined,
                            color: LikedPalette.muted,
                            size: 15,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${formatBytes(ctrl.totalBytes)} on this device',
                            style: const TextStyle(
                              color: LikedPalette.muted,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
            Expanded(
              child: Obx(() {
                if (!ctrl.isReady.value) {
                  return const Center(
                    child: CircularProgressIndicator(color: accent),
                  );
                }

                if (ctrl.songs.isEmpty) {
                  return SingleChildScrollView(
                    child: LikedEmptyState(
                      message: '',
                      emptyTitle: 'No downloads yet',
                      emptyBody:
                          'Tap DOWNLOAD while a song is playing to keep it '
                          'on this device and listen without internet.',
                      accent: accent,
                      emptyIcon: Icons.download_for_offline_outlined,
                      onRetry: () {},
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                  itemCount: ctrl.songs.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (_, index) => _DownloadRow(
                    song: ctrl.songs[index],
                    position: index + 1,
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _DownloadRow extends StatelessWidget {
  const _DownloadRow({required this.song, required this.position});

  final DownloadedSong song;
  final int position;

  @override
  Widget build(BuildContext context) {
    final ctrl = DownloadController.instance;
    final coverPath = ctrl.coverPath(song);
    final duration = LikedSongsScreen.formatDuration(song.id, song.durationMs);
    final subtitle = [
      song.artist,
      ?duration,
      DownloadsScreen.formatBytes(song.fileSize),
    ].join('  •  ');

    return Obx(() {
      final playing = Get.find<PlayerController>().trackId.value == song.id;

      return GestureDetector(
        onTap: () => DownloadsScreen._play(song),
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: LikedPalette.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: playing
                  ? DownloadsScreen.accent.withValues(alpha: 0.35)
                  : Colors.white.withValues(alpha: 0.05),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: LikedPalette.chip,
                ),
                child: playing
                    ? const Icon(
                        Icons.equalizer_rounded,
                        color: DownloadsScreen.accent,
                        size: 17,
                      )
                    : Center(
                        child: Text(
                          '$position',
                          style: const TextStyle(
                            color: LikedPalette.muted,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(13),
                child: SizedBox(
                  width: 58,
                  height: 58,
                  child: DecoratedBox(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: DownloadsScreen._artGradient,
                      ),
                    ),
                    // The saved cover first, so the art shows offline.
                    child: coverPath != null
                        ? Image.file(
                            File(coverPath),
                            width: 58,
                            height: 58,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => const SizedBox.shrink(),
                          )
                        : song.artworkUrl.isNotEmpty
                        ? LikedCover(url: song.artworkUrl, size: 58)
                        : const Icon(
                            Icons.music_note_rounded,
                            color: Colors.white,
                            size: 25,
                          ),
                  ),
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      song.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: playing ? DownloadsScreen.accent : Colors.white,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: LikedPalette.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 7),
                    const Row(
                      children: [
                        Icon(
                          Icons.download_done_rounded,
                          color: DownloadsScreen.accent,
                          size: 14,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Downloaded',
                          style: TextStyle(
                            color: DownloadsScreen.accent,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () => DownloadActions.confirmRemove(
                  context,
                  songId: song.id,
                  title: song.title,
                  onPlay: () => DownloadsScreen._play(song),
                ),
                behavior: HitTestBehavior.opaque,
                child: const SizedBox(
                  width: 30,
                  height: 30,
                  child: Icon(
                    Icons.more_vert_rounded,
                    color: Colors.white38,
                    size: 19,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}
