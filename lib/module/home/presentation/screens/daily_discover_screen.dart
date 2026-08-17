import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/common/widget/liked_collection.dart';
import '../../../../core/player/player_controller.dart';
import '../../controller/daily_discover_controller.dart';
import '../../model/listem_miusic_detalis_model.dart';
import 'liked_songs_screen.dart';

/// The day's picks, over `GET /songs/daily-discovery`.
///
/// One unpaged list in the order the backend chose, so there is no paging here
/// — pull to refresh asks for a fresh selection.
class DailyDiscoverScreen extends StatefulWidget {
  const DailyDiscoverScreen({super.key});

  static const accent = Color(0xFFD38BFF);

  static const _artGradient = [Color(0xFF7B3BFF), Color(0xFFD38BFF)];

  @override
  State<DailyDiscoverScreen> createState() => _DailyDiscoverScreenState();
}

class _DailyDiscoverScreenState extends State<DailyDiscoverScreen> {
  final ctrl = DailyDiscoverController.instance;

  static const accent = DailyDiscoverScreen.accent;

  @override
  void initState() {
    super.initState();
    // Asked for on every open, so a first fetch that failed — no token yet, or
    // the network was down — is retried here rather than left as an error the
    // user has to tap "Try again" on. A fetch already running is joined.
    ctrl.fetch();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LikedPalette.background,
      body: SafeArea(
        child: Column(
          children: [
            const LikedHeader(
              title: 'Daily Discover',
              subtitle: 'A fresh set of songs picked for you',
              icon: Icons.auto_awesome_rounded,
              iconColor: accent,
            ),
            const SizedBox(height: 18),
            Obx(
              () => LikedSummaryStrip(
                icon: Icons.auto_awesome_rounded,
                accent: accent,
                count: ctrl.hasLoaded.value ? ctrl.songs.length : null,
                noun: 'Pick',
                // The strip is this screen's play control — a row starts one
                // song, this starts the selection on a random pick.
                onTap: ctrl.songs.isEmpty ? null : ctrl.shuffle,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: RefreshIndicator(
                onRefresh: ctrl.fetch,
                color: accent,
                backgroundColor: LikedPalette.card,
                child: CustomScrollView(
                  // Keeps pull-to-refresh reachable while the list is empty or
                  // short.
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
                            failedTitle: 'Could not load your daily picks',
                            emptyIcon: Icons.auto_awesome_rounded,
                            emptyTitle: 'No picks yet',
                            emptyBody:
                                'Listen to a few songs and a set picked for '
                                'you will land here.',
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
                          itemBuilder: (_, index) => _PickRow(
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
}

class _PickRow extends StatelessWidget {
  const _PickRow({
    required this.song,
    required this.position,
    required this.controller,
  });

  final ListenMusicDetailsModel song;
  final int position;
  final DailyDiscoverController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // All four reads are reactive, so the row repaints when the player moves
      // to another track, when it measures a length this song lacked, and
      // while its like is in flight.
      final playing = Get.find<PlayerController>().trackId.value == song.id;
      final duration = LikedSongsScreen.formatDuration(
        song.id,
        song.durationMs,
      );
      final liked = controller.likedIds.contains(song.id);
      final busy = controller.togglingLikes.contains(song.id);

      return LikedRowCard(
        position: position,
        playing: playing,
        accent: DailyDiscoverScreen.accent,
        coverUrl: song.coverUrl,
        fallbackIcon: Icons.music_note_rounded,
        gradient: DailyDiscoverScreen._artGradient,
        title: song.title,
        subtitle: [song.artist, ?duration].join('  •  '),
        tag: song.genre.name,
        liked: liked,
        busy: busy,
        onTap: () => controller.play(song),
        onUnlike: () => controller.toggleLike(song),
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
              icon: liked
                  ? Icons.heart_broken_rounded
                  : Icons.favorite_rounded,
              label: liked ? 'Remove from Liked' : 'Add to Liked',
              onTap: () => controller.toggleLike(song),
            ),
          ],
        ),
      );
    });
  }
}
