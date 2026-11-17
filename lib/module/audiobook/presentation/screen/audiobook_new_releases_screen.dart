import 'package:flutter/material.dart';
import 'package:beatx_flutter/core/common/widget/app_back_button.dart';
import 'package:beatx_flutter/core/common/widget/mini_player_host.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../../core/common/widget/load_more.dart';
import '../../../genre-artist/controller/genre_controller.dart';
import '../../controller/audiobook_new_releases_controller.dart';

import '../../controller/audiobook_controller.dart';
import '../../model/audiobook_model.dart';
import '../widget/book_cover.dart';
import 'audiobook_detail_screen.dart';

/// Every new-release audiobook, in a grid that loads a page at a time as it
/// scrolls, filtered by genre on the server.
///
/// [books] are what the home feed already had; they show at once while the
/// first page loads.
class AudiobookNewReleasesScreen extends StatefulWidget {
  const AudiobookNewReleasesScreen({super.key, required this.books});

  final List<Audiobook> books;

  @override
  State<AudiobookNewReleasesScreen> createState() =>
      _AudiobookNewReleasesScreenState();
}

class _AudiobookNewReleasesScreenState
    extends State<AudiobookNewReleasesScreen> {
  late final AudiobookNewReleasesController _controller = Get.put(
    AudiobookNewReleasesController(),
    tag: 'audiobook-new-releases-${identityHashCode(this)}',
  );

  static const _accent = Color(0xFF40DDEB);

  @override
  void dispose() {
    Get.delete<AudiobookNewReleasesController>(
      tag: 'audiobook-new-releases-${identityHashCode(this)}',
    );
    super.dispose();
  }

  void _open(Audiobook book) => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => AudiobookDetailScreen(book: book)),
  );

  @override
  Widget build(BuildContext context) {
    final genres = GenreController.instance;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: const Color(0xFF080909),
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFF080909),
        body: Stack(
          children: [
            const _ReleaseGlow(),
            SafeArea(
              bottom: false,
              child: RefreshIndicator(
                onRefresh: _controller.search,
                color: _accent,
                backgroundColor: const Color(0xFF202020),
                child: LoadMoreOnScroll(
                  onLoadMore: _controller.loadMore,
                  child: Obx(() {
                    final c = _controller;
                    // The home feed's books until the first page lands.
                    final books =
                        !c.hasSearched.value && c.genreId.value.isEmpty
                        ? widget.books
                        : c.results.toList();
                    final selected = c.genreId.value;
                    final options = [
                      ('', AudiobookController.allGenres),
                      for (final g in genres.genres) (g.id, g.name),
                    ];

                    return CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        const SliverToBoxAdapter(child: _ReleaseHeader()),
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 34, 16, 34),
                          sliver: SliverToBoxAdapter(
                            child: Wrap(
                              spacing: 12,
                              runSpacing: 14,
                              children: [
                                for (final (id, name) in options)
                                  _ReleaseChip(
                                    label: name,
                                    selected: id == selected,
                                    onTap: () => c.selectGenre(id),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        if (c.isLoading.value && books.isEmpty)
                          const SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 40),
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: _accent,
                                ),
                              ),
                            ),
                          )
                        else if (books.isEmpty)
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 40,
                              ),
                              child: Text(
                                c.errorMessage.value.isNotEmpty
                                    ? c.errorMessage.value
                                    : 'No releases in this genre.',
                                style: const TextStyle(
                                  color: Color(0xFF77727A),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0,
                                ),
                              ),
                            ),
                          )
                        else
                          SliverPadding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            // Lazy: only the cards on screen are built.
                            sliver: SliverGrid.builder(
                              itemCount: books.length,
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    crossAxisSpacing: 24,
                                    mainAxisSpacing: 30,
                                    childAspectRatio: 0.5,
                                  ),
                              itemBuilder: (context, index) => _ReleaseGridCard(
                                book: books[index],
                                onTap: () => _open(books[index]),
                              ),
                            ),
                          ),
                        SliverLoadMoreFooter(
                          loading: c.isLoadingMore.value,
                          color: _accent,
                        ),
                        const SliverToBoxAdapter(child: SizedBox(height: 86)),
                        // Room to scroll the last items clear of the mini
                        // player.
                        const SliverMiniPlayerSpacer(),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReleaseGlow extends StatelessWidget {
  const _ReleaseGlow();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: -92,
      left: 24,
      right: -20,
      child: Container(
        height: 420,
        decoration: BoxDecoration(
          gradient: RadialGradient(
            colors: [
              const Color(0xFFB334D7).withValues(alpha: 0.95),
              const Color(0xFF5125B8).withValues(alpha: 0.58),
              const Color(0xFF071916).withValues(alpha: 0.18),
              Colors.transparent,
            ],
            stops: const [0, 0.4, 0.74, 1],
          ),
        ),
      ),
    );
  }
}

class _ReleaseHeader extends StatelessWidget {
  const _ReleaseHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
      child: Row(
        children: [
          const AppBackButton(),
          const SizedBox(width: 16),
          const Text(
            'New Releases',
            style: TextStyle(
              color: Color(0xFF40DDEB),
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReleaseChip extends StatelessWidget {
  const _ReleaseChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF40DDEB) : const Color(0xFF202020),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? const Color(0xFF0E1112) : const Color(0xFFAAA5AD),
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _ReleaseGridCard extends StatelessWidget {
  const _ReleaseGridCard({required this.book, this.onTap});

  final Audiobook book;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.34),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: AspectRatio(
                aspectRatio: 0.72,
                child: BookCover(
                  url: book.coverUrl,
                  alignment: Alignment.topCenter,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            book.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 23,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            book.author,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFFAAA5AD),
              fontSize: 18,
              fontWeight: FontWeight.w600,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}
