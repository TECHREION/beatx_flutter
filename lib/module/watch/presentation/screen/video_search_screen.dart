import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/common/widget/search_collection.dart';
import '../../controller/video_search_controller.dart';
import 'video_screen.dart';

/// Video search, over `GET /videos/search` — by name, by genre, or both.
///
/// Opens on everything the backend holds, so the query and the genre chips
/// narrow a list that is already there.
class VideoSearchScreen extends StatelessWidget {
  VideoSearchScreen({super.key});

  static const accent = Color(0xFF40DDEB);

  static const _artGradient = [Color(0xFF40DDEB), Color(0xFF32185F)];

  final VideoSearchController controller = Get.put(VideoSearchController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SearchPalette.background,
      body: SafeArea(
        child: Column(
          children: [
            const SearchHeader(
              title: 'Search Videos',
              icon: Icons.play_circle_fill_rounded,
              accent: accent,
            ),
            SearchQueryField(
              hint: 'Video title',
              accent: accent,
              onChanged: controller.onQueryChanged,
              onSubmitted: (_) => controller.search(),
              onCleared: controller.clearQuery,
            ),
            const SizedBox(height: 14),
            Obx(
              () => SearchGenreBar(
                accent: accent,
                selectedId: controller.genreId.value,
                onSelected: controller.selectGenre,
              ),
            ),
            const SizedBox(height: 14),
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
                    query: controller.query.value.trim(),
                    noun: 'videos',
                    accent: accent,
                    onRetry: controller.search,
                  );
                }

                return SearchResultsList(
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
                      onTap: () =>
                          Get.to(() => MusicPlayerScreen(videoId: video.id)),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  /// `5:14`, or nothing for a video the backend never measured.
  static String _formatDuration(int durationMs) {
    if (durationMs <= 0) return '';

    final duration = Duration(milliseconds: durationMs);
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (duration.inHours > 0) {
      final minutes = duration.inMinutes.remainder(60).toString().padLeft(
        2,
        '0',
      );
      return '${duration.inHours}:$minutes:$seconds';
    }
    return '${duration.inMinutes}:$seconds';
  }
}
