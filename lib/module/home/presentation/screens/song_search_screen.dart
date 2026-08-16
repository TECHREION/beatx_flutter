import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/common/widget/search_collection.dart';
import '../../controller/song_search_controller.dart';
import 'liked_songs_screen.dart';

/// Song search, over `GET /songs/search` — by name, by genre, or both.
///
/// Opens on everything the backend holds, so the query and the genre chips
/// narrow a list that is already there.
class SongSearchScreen extends StatelessWidget {
  SongSearchScreen({super.key});

  static const accent = Color(0xFF9BFF4D);

  static const _artGradient = [Color(0xFF4DEBFF), Color(0xFF7B3BFF)];

  final SongSearchController controller = Get.put(SongSearchController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SearchPalette.background,
      body: SafeArea(
        child: Column(
          children: [
            const SearchHeader(
              title: 'Search Songs',
              icon: Icons.music_note_rounded,
              accent: accent,
            ),
            SearchQueryField(
              hint: 'Song or artist name',
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
                    noun: 'songs',
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
                    final song = controller.results[index];
                    final duration = LikedSongsScreen.formatDuration(
                      song.id,
                      song.durationMs,
                    );

                    return SearchResultTile(
                      coverUrl: song.coverUrl,
                      title: song.title,
                      subtitle: song.artist,
                      fallbackIcon: Icons.music_note_rounded,
                      gradient: _artGradient,
                      accent: accent,
                      tag: song.genre.name,
                      meta: duration ?? '',
                      onTap: () => controller.play(song),
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
}
