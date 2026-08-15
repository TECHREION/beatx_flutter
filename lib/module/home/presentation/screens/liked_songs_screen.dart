import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/common/widget/liked_collection.dart';
import '../../../../core/player/player_controller.dart';
import '../../controller/liked_songs_controller.dart';
import '../../model/listem_miusic_detalis_model.dart';

/// Every song the user has liked, over `GET /songs/liked`.
class LikedSongsScreen extends StatelessWidget {
  const LikedSongsScreen({super.key});

  static const accent = Color(0xFF9BFF4D);

  static const _artGradient = [Color(0xFF4DEBFF), Color(0xFF7B3BFF)];

  @override
  Widget build(BuildContext context) {
    final ctrl = LikedSongsController.instance;

    return Scaffold(
      backgroundColor: LikedPalette.background,
      body: SafeArea(
        child: Column(
          children: [
            const LikedHeader(
              title: 'Liked Songs',
              subtitle: 'Your favorite songs, all in one place',
            ),
            const SizedBox(height: 18),
            Obx(
              () => LikedSummaryStrip(
                icon: Icons.headphones_rounded,
                accent: accent,
                count: ctrl.hasLoaded.value ? ctrl.songs.length : null,
                noun: 'Liked Song',
                // The strip is this screen's play control — a row starts one
                // song, this starts the collection.
                onTap: ctrl.songs.isEmpty
                    ? null
                    : () => ctrl.play(ctrl.songs.first),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: RefreshIndicator(
                onRefresh: ctrl.fetch,
                color: accent,
                backgroundColor: LikedPalette.card,
                child: CustomScrollView(
                  // Keeps pull-to-refresh reachable while the list is empty
                  // or short.
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    Obx(() {
                      if (ctrl.isLoading.value && ctrl.songs.isEmpty) {
                        return const SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(
                            child: CircularProgressIndicator(color: accent),
                          ),
                        );
                      }

                      if (ctrl.songs.isEmpty) {
                        return SliverFillRemaining(
                          hasScrollBody: false,
                          child: LikedEmptyState(
                            message: ctrl.errorMessage.value,
                            emptyTitle: 'No liked songs yet',
                            emptyBody:
                                'Tap the heart while a song is playing and it '
                                'will show up here.',
                            accent: accent,
                            onRetry: ctrl.fetch,
                          ),
                        );
                      }

                      return SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                        sliver: SliverList.separated(
                          itemCount: ctrl.songs.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 12),
                          itemBuilder: (_, index) => _SongRow(
                            song: ctrl.songs[index],
                            position: index + 1,
                            controller: ctrl,
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// `durationMs` comes back as 0 for songs the backend never measured, so
  /// fall back to whatever the player measured the last time it played one.
  static String? formatDuration(String songId, int durationMs) {
    var value = Duration(milliseconds: durationMs);
    if (value == Duration.zero && Get.isRegistered<PlayerController>()) {
      value =
          Get.find<PlayerController>().measuredDuration(songId) ??
          Duration.zero;
    }
    if (value == Duration.zero) return null;

    final minutes = value.inMinutes;
    final seconds = value.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

class _SongRow extends StatelessWidget {
  const _SongRow({
    required this.song,
    required this.position,
    required this.controller,
  });

  final ListenMusicDetailsModel song;
  final int position;
  final LikedSongsController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // All three reads are reactive, so the row repaints when the player
      // moves to another track, when it measures a length this song lacked,
      // and while its unlike is in flight.
      final playing = Get.find<PlayerController>().trackId.value == song.id;
      final duration = LikedSongsScreen.formatDuration(
        song.id,
        song.durationMs,
      );
      final busy = controller.unliking.contains(song.id);

      return LikedRowCard(
        position: position,
        playing: playing,
        accent: LikedSongsScreen.accent,
        coverUrl: song.coverUrl,
        fallbackIcon: Icons.music_note_rounded,
        gradient: LikedSongsScreen._artGradient,
        title: song.title,
        subtitle: [song.artist, ?duration].join('  •  '),
        tag: song.genre.name,
        busy: busy,
        onTap: () => controller.play(song),
        onUnlike: () => controller.unlike(song),
        onMore: () => LikedActionsSheet.show(
          context,
          title: song.title,
          actions: [
            LikedAction(
              icon: Icons.play_arrow_rounded,
              label: 'Play',
              onTap: () => controller.play(song),
            ),
            LikedAction(
              icon: Icons.heart_broken_rounded,
              label: 'Remove from Liked',
              onTap: () => controller.unlike(song),
            ),
          ],
        ),
      );
    });
  }
}
