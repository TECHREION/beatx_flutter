import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/common/widget/search_collection.dart';
import '../../controller/audiobook_search_controller.dart';
import 'audiobook_detail_screen.dart';

/// Audiobook search, over `GET /audiobooks/search` — by name, by genre, or
/// both.
///
/// Opens on everything the backend holds, so the query and the genre chips
/// narrow a list that is already there.
class AudiobookSearchScreen extends StatelessWidget {
  AudiobookSearchScreen({super.key});

  static const accent = Color(0xFFBD89FF);

  static const _artGradient = [Color(0xFF673BD3), Color(0xFF40DDEB)];

  final AudiobookSearchController controller = Get.put(
    AudiobookSearchController(),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SearchPalette.background,
      body: SafeArea(
        child: Column(
          children: [
            const SearchHeader(
              title: 'Search Audiobooks',
              icon: Icons.menu_book_rounded,
              accent: accent,
            ),
            SearchQueryField(
              hint: 'Book or author name',
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
                    noun: 'audiobooks',
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
                    final book = controller.results[index];
                    final chapters = book.totalChapters;

                    return SearchResultTile(
                      coverUrl: book.coverUrl,
                      title: book.title,
                      subtitle: [
                        if (book.author.isNotEmpty) book.author,
                        if (chapters > 0)
                          chapters == 1 ? '1 chapter' : '$chapters chapters',
                      ].join('  •  '),
                      fallbackIcon: Icons.menu_book_rounded,
                      gradient: _artGradient,
                      accent: accent,
                      tag: book.genreName,
                      meta: book.formattedDuration,
                      onTap: () => Get.to(
                        () => AudiobookDetailScreen(book: book),
                        preventDuplicates: false,
                      ),
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
