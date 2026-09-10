import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/common/widget/search_collection.dart';
import '../../controller/podcast_search_controller.dart';
import '../../model/search_category_model.dart';
import 'podcast_category_screen.dart';

/// Podcast search, over `GET /podcasts/search` — by name, by category, or
/// both.
///
/// Opens on everything the backend holds, so the query and the category chips
/// narrow a list that is already there.
class PodcastSearchScreen extends StatelessWidget {
  PodcastSearchScreen({super.key});

  static const accent = Color(0xFFBD89FF);

  static const _artGradient = [Color(0xFFBD89FF), Color(0xFF2A1B4A)];

  final PodcastSearchController controller = Get.put(
    PodcastSearchController(),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SearchPalette.background,
      body: SafeArea(
        child: Column(
          children: [
            const SearchHeader(
              title: 'Search Podcasts',
              icon: Icons.mic_rounded,
              accent: accent,
            ),
            SearchQueryField(
              hint: 'Podcast title',
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
                // Categories, not genres: this route filters on `category`,
                // and those ids are a different set.
                options: controller.categories,
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
                    noun: 'podcasts',
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
                    final podcast = controller.results[index];

                    return SearchResultTile(
                      coverUrl: podcast.coverUrl ?? '',
                      title: podcast.title,
                      subtitle: podcast.description,
                      fallbackIcon: Icons.mic_rounded,
                      gradient: _artGradient,
                      accent: accent,
                      tag: podcast.category.name,
                      meta: podcast.episodeCountLabel,
                      onTap: () => _openPodcast(podcast.category),
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

  /// Opens the show's category, which is the only screen that lists shows
  /// and their episodes — there is no per-podcast screen yet.
  void _openPodcast(PodcastCategory category) {
    if (category.id.isEmpty) return;

    Get.to(
      () => PodcastCategoryScreen(
        categoryId: category.id,
        categoryName: category.name,
      ),
      transition: Transition.rightToLeft,
      preventDuplicates: true,
    );
  }
}
