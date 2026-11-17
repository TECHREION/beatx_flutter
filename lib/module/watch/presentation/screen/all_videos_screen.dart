import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/common/widget/search_collection.dart';
import '../../controller/video_browse_controller.dart';
import '../../services/watch_interface.dart';
import 'video_screen.dart';

/// Every video, to scroll through: trending, or the whole library, filtered
/// by genre. More load as the list nears its end, so a large library never
/// arrives (or is laid out) all at once.
class AllVideosScreen extends StatelessWidget {
  AllVideosScreen({super.key, this.initialFeed = VideoFeed.trending})
    : controller = Get.put(
        VideoBrowseController(initialFeed: initialFeed),
        tag: 'all-videos-${DateTime.now().microsecondsSinceEpoch}',
      );

  final VideoFeed initialFeed;
  final VideoBrowseController controller;

  static const accent = Color(0xFF40DDEB);
  static const _artGradient = [Color(0xFF40DDEB), Color(0xFF32185F)];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SearchPalette.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SearchHeader(
              title: 'All Videos',
              icon: Icons.video_library_rounded,
              accent: accent,
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
                    noun: 'videos',
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
                      final video = controller.results[index];
                      return SearchResultTile(
                        coverUrl: video.coverUrl,
                        title: video.title,
                        subtitle: video.ownerId.name.isNotEmpty
                            ? video.ownerId.name
                            : video.description,
                        fallbackIcon: Icons.play_circle_fill_rounded,
                        gradient: _artGradient,
                        accent: accent,
                        tag: video.genre.name,
                        meta: _formatDuration(video.durationMs),
                        wideCover: true,
                        onTap: () => MusicPlayerScreen.open(video.id),
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

  static String _formatDuration(int durationMs) {
    if (durationMs <= 0) return '';
    final d = Duration(milliseconds: durationMs);
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (d.inHours > 0) {
      final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
      return '${d.inHours}:$m:$s';
    }
    return '${d.inMinutes}:$s';
  }
}

/// Trending · All Videos.
class _FeedTabs extends StatelessWidget {
  const _FeedTabs({required this.selected, required this.onSelected});

  final VideoFeed selected;
  final ValueChanged<VideoFeed> onSelected;

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
            for (final feed in VideoFeed.values)
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
                            ? AllVideosScreen.accent
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                      ),
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
          ],
        ),
      ),
    );
  }
}
