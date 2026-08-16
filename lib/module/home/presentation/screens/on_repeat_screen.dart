import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/common/widget/liked_collection.dart';
import '../../../../core/player/player_controller.dart';
import '../../controller/on_repeat_controller.dart';
import '../../model/on_repeat_model.dart';
import 'liked_songs_screen.dart';

/// The songs the user plays most, over `GET /songs/on-repeat`.
///
/// Most played first, as the backend orders it. Pages are pulled in as the
/// list is scrolled, so the screen ends up holding the whole list.
class OnRepeatScreen extends StatelessWidget {
  const OnRepeatScreen({super.key});

  static const accent = Color(0xFF6CFF8B);

  static const _artGradient = [Color(0xFF2FA96B), Color(0xFF40DDEB)];

  /// How close to the bottom the list gets before the next page is asked for.
  static const _loadMoreExtent = 240.0;

  @override
  Widget build(BuildContext context) {
    final ctrl = OnRepeatController.instance;

    return Scaffold(
      backgroundColor: LikedPalette.background,
      body: SafeArea(
        child: Column(
          children: [
            const LikedHeader(
              title: 'On Repeat',
              subtitle: 'The songs you keep coming back to',
              icon: Icons.bolt_rounded,
              iconColor: accent,
            ),
            const SizedBox(height: 18),
            Obx(
              () => LikedSummaryStrip(
                icon: Icons.repeat_rounded,
                accent: accent,
                // The backend's total, which counts the pages not fetched yet.
                count: ctrl.hasLoaded.value ? ctrl.total.value : null,
                noun: 'Track',
                // The strip is this screen's play control — a row starts one
                // song, this starts the most played of them.
                onTap: ctrl.entries.isEmpty
                    ? null
                    : () => ctrl.play(ctrl.entries.first),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: NotificationListener<ScrollNotification>(
                onNotification: (notification) {
                  final metrics = notification.metrics;
                  if (metrics.axis != Axis.vertical) return false;

                  if (metrics.maxScrollExtent - metrics.pixels <=
                      _loadMoreExtent) {
                    // Guarded in the controller, so a burst of scroll
                    // notifications still only fetches one page.
                    ctrl.loadMore();
                  }
                  return false;
                },
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
                        if (ctrl.isLoading.value && ctrl.entries.isEmpty) {
                          return const SliverFillRemaining(
                            hasScrollBody: false,
                            child: Center(
                              child: CircularProgressIndicator(color: accent),
                            ),
                          );
                        }

                        if (ctrl.entries.isEmpty) {
                          return SliverFillRemaining(
                            hasScrollBody: false,
                            child: LikedEmptyState(
                              message: ctrl.errorMessage.value,
                              failedTitle: 'Could not load your top played',
                              emptyIcon: Icons.repeat_rounded,
                              emptyTitle: 'Nothing on repeat yet',
                              emptyBody:
                                  'Play a song more than once and it will '
                                  'climb this list.',
                              accent: accent,
                              onRetry: ctrl.fetch,
                            ),
                          );
                        }

                        return SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                          sliver: SliverList.separated(
                            itemCount: ctrl.entries.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 12),
                            itemBuilder: (_, index) => _OnRepeatRow(
                              entry: ctrl.entries[index],
                              position: index + 1,
                              controller: ctrl,
                            ),
                          ),
                        );
                      }),
                      Obx(
                        () => SliverToBoxAdapter(
                          child: ctrl.isLoadingMore.value
                              ? const Padding(
                                  padding: EdgeInsets.fromLTRB(0, 8, 0, 32),
                                  child: Center(
                                    child: SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: accent,
                                      ),
                                    ),
                                  ),
                                )
                              : const SizedBox(height: 24),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnRepeatRow extends StatelessWidget {
  const _OnRepeatRow({
    required this.entry,
    required this.position,
    required this.controller,
  });

  final OnRepeatModel entry;
  final int position;
  final OnRepeatController controller;

  @override
  Widget build(BuildContext context) {
    final song = entry.song;

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
        accent: OnRepeatScreen.accent,
        coverUrl: song.coverUrl,
        fallbackIcon: Icons.music_note_rounded,
        gradient: OnRepeatScreen._artGradient,
        title: song.title,
        subtitle: [song.artist, ?duration].join('  •  '),
        tag: OnRepeatController.formatPlays(entry.playCount),
        liked: liked,
        busy: busy,
        onTap: () => controller.play(entry),
        onUnlike: () => controller.toggleLike(entry),
        onMore: () => LikedActionsSheet.show(
          context,
          title: song.title,
          actions: [
            LikedAction(
              icon: Icons.play_arrow_rounded,
              label: 'Play',
              onTap: () => controller.play(entry),
            ),
            LikedAction(
              icon: liked
                  ? Icons.heart_broken_rounded
                  : Icons.favorite_rounded,
              label: liked ? 'Remove from Liked' : 'Add to Liked',
              onTap: () => controller.toggleLike(entry),
            ),
          ],
        ),
      );
    });
  }
}
