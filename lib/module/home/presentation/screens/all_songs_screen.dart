import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/common/widget/search_collection.dart';
import '../../controller/song_browse_controller.dart';
import '../../services/listen_interface.dart';
import 'liked_songs_screen.dart';
import 'song_search_screen.dart';

/// Every song, to scroll through: new releases, trending, or the whole
/// library, filtered by genre. More load as the list nears its end.
///
/// The home feed shows only the first ten; "See all" opens this.
class AllSongsScreen extends StatelessWidget {
  AllSongsScreen({super.key, this.initialFeed = SongFeed.newReleases})
    : controller = Get.put(
        SongBrowseController(initialFeed: initialFeed),
        // One per opening, so a second "See all" starts fresh.
        tag: 'all-songs-${DateTime.now().microsecondsSinceEpoch}',
      );

  final SongFeed initialFeed;
  final SongBrowseController controller;

  static const accent = Color(0xFF9BFF4D);
  static const _artGradient = [Color(0xFF4DEBFF), Color(0xFF7B3BFF)];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SearchPalette.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Expanded(
                  child: SearchHeader(
                    title: 'All Songs',
                    icon: Icons.library_music_rounded,
                    accent: accent,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 10, right: 8),
                  child: IconButton(
                    onPressed: () => Get.to<void>(() => SongSearchScreen()),
                    icon: const Icon(
                      Icons.search_rounded,
                      color: Colors.white,
                      semanticLabel: 'Search songs',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Obx(
              () => _FeedTabs(
                selected: controller.feed.value,
                onSelected: controller.selectFeed,
              ),
            ),
            const SizedBox(height: 12),
            Obx(
              () => SearchGenreBar(
                accent: accent,
                selectedId: controller.genreId.value,
                onSelected: controller.selectGenre,
              ),
            ),
            const SizedBox(height: 12),
            // Read here, inside the Obx, so it rebuilds with them.
            Obx(
              () => _PlayAllRow(
                total: controller.total.value,
                ready: controller.results.isNotEmpty,
                onPlayAll: controller.playAll,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value && controller.results.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(color: accent),
                  );
                }
                if (controller.results.isEmpty) {
                  return SearchEmptyState(
                    message: controller.errorMessage.value,
                    query: '',
                    noun: 'songs',
                    accent: accent,
                    onRetry: controller.search,
                  );
                }
                return RefreshIndicator(
                  color: accent,
                  backgroundColor: SearchPalette.card,
                  onRefresh: controller.search,
                  child: SearchResultsList(
                    itemCount: controller.results.length,
                    isLoadingMore: controller.isLoadingMore.value,
                    accent: accent,
                    onLoadMore: controller.loadMore,
                    itemBuilder: (_, index) {
                      final song = controller.results[index];
                      return SearchResultTile(
                        coverUrl: song.coverUrl,
                        title: song.title,
                        subtitle: song.artist,
                        fallbackIcon: Icons.music_note_rounded,
                        gradient: _artGradient,
                        accent: accent,
                        tag: song.genre.name,
                        meta:
                            LikedSongsScreen.formatDuration(
                              song.id,
                              song.durationMs,
                            ) ??
                            '',
                        onTap: () => controller.play(song),
                      );
                    },
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

/// New Releases · Trending · All Songs.
class _FeedTabs extends StatelessWidget {
  const _FeedTabs({required this.selected, required this.onSelected});

  final SongFeed selected;
  final ValueChanged<SongFeed> onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: SearchPalette.card,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Row(
          children: [
            for (final feed in SongFeed.values)
              Expanded(
                child: Semantics(
                  button: true,
                  selected: feed == selected,
                  child: GestureDetector(
                    onTap: () => onSelected(feed),
                    behavior: HitTestBehavior.opaque,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      height: 38,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: feed == selected
                            ? AllSongsScreen.accent
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            feed.label,
                            style: TextStyle(
                              color: feed == selected
                                  ? Colors.black
                                  : Colors.white70,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
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

/// How many songs the list holds, and a button to play them from the top.
class _PlayAllRow extends StatelessWidget {
  const _PlayAllRow({
    required this.total,
    required this.ready,
    required this.onPlayAll,
  });

  final int total;
  final bool ready;
  final VoidCallback onPlayAll;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: Text(
              ready ? (total == 1 ? '1 song' : '$total songs') : '',
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          FilledButton.icon(
            onPressed: ready ? onPlayAll : null,
            style: FilledButton.styleFrom(
              backgroundColor: AllSongsScreen.accent,
              foregroundColor: Colors.black,
              disabledBackgroundColor: AllSongsScreen.accent.withValues(
                alpha: 0.3,
              ),
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              shape: const StadiumBorder(),
            ),
            icon: const Icon(Icons.play_arrow_rounded, size: 20),
            label: const Text(
              'Play all',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}
