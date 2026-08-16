import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/common/widget/liked_collection.dart';
import '../../controller/audiobook_like_controller.dart';
import '../../controller/liked_audiobooks_controller.dart';
import '../../model/audiobook_model.dart';
import 'audiobook_detail_screen.dart';

/// Every audiobook the user has liked, over `GET /audiobooks/liked`.
///
/// Same layout as the liked songs and liked podcasts screens — all three are
/// built from the shared chrome in `liked_collection.dart` — with the
/// audiobook tab's accent.
class LikedAudiobooksScreen extends StatelessWidget {
  const LikedAudiobooksScreen({super.key});

  static const accent = Color(0xFF40DDEB);

  static const _artGradient = [Color(0xFF673BD3), Color(0xFF40DDEB)];

  @override
  Widget build(BuildContext context) {
    final ctrl = LikedAudiobooksController.instance;

    return Scaffold(
      backgroundColor: LikedPalette.background,
      body: SafeArea(
        child: Column(
          children: [
            const LikedHeader(
              title: 'Liked Audiobooks',
              subtitle: 'Your favorite audiobooks, all in one place',
            ),
            const SizedBox(height: 18),
            Obx(
              () => LikedSummaryStrip(
                icon: Icons.menu_book_rounded,
                accent: accent,
                count: ctrl.hasLoaded.value ? ctrl.books.length : null,
                noun: 'Liked Audiobook',
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
                      if (ctrl.isLoading.value && ctrl.books.isEmpty) {
                        return const SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(
                            child: CircularProgressIndicator(color: accent),
                          ),
                        );
                      }

                      if (ctrl.books.isEmpty) {
                        return SliverFillRemaining(
                          hasScrollBody: false,
                          child: LikedEmptyState(
                            message: ctrl.errorMessage.value,
                            emptyTitle: 'No liked audiobooks yet',
                            emptyBody:
                                'Tap the heart on a book and it will show up '
                                'here.',
                            accent: accent,
                            onRetry: ctrl.fetch,
                          ),
                        );
                      }

                      return SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                        sliver: SliverList.separated(
                          itemCount: ctrl.books.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 12),
                          itemBuilder: (_, index) => _AudiobookRow(
                            book: ctrl.books[index],
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

class _AudiobookRow extends StatelessWidget {
  const _AudiobookRow({
    required this.book,
    required this.position,
    required this.controller,
  });

  final Audiobook book;
  final int position;
  final LikedAudiobooksController controller;

  @override
  Widget build(BuildContext context) {
    final chapters = book.totalChapters;
    final duration = book.formattedDuration;

    return Obx(() {
      // Both reads are reactive, so the row lights up when a chapter of this
      // book starts playing and while its unlike is in flight.
      final playing =
          AudiobookLikeController.instance.audiobookId.value == book.id;
      final busy = controller.unliking.contains(book.id);

      return LikedRowCard(
        position: position,
        playing: playing,
        accent: LikedAudiobooksScreen.accent,
        coverUrl: book.coverUrl,
        fallbackIcon: Icons.menu_book_rounded,
        gradient: LikedAudiobooksScreen._artGradient,
        title: book.title,
        subtitle: [
          if (book.author.isNotEmpty) book.author,
          if (chapters > 0) chapters == 1 ? '1 chapter' : '$chapters chapters',
          if (duration.isNotEmpty) duration,
        ].join('  •  '),
        tag: book.genreName,
        busy: busy,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => AudiobookDetailScreen(book: book)),
        ),
        onUnlike: () => controller.unlike(book),
        onMore: () => LikedActionsSheet.show(
          context,
          title: book.title,
          actions: [
            LikedAction(
              icon: Icons.menu_book_rounded,
              label: 'Open',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AudiobookDetailScreen(book: book),
                ),
              ),
            ),
            LikedAction(
              icon: Icons.heart_broken_rounded,
              label: 'Remove from Liked',
              onTap: () => controller.unlike(book),
            ),
          ],
        ),
      );
    });
  }
}
