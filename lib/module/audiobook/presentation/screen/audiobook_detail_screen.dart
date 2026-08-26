import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../../core/notifiers/snackbar_notifier.dart';
import '../../controller/audio_book_details_controller.dart';
import '../../model/audio_book_details_model.dart' as details_model;
import '../../model/audiobook_model.dart';
import '../widget/book_cover.dart';
import '../../../../core/theme/responsive.dart';

class AudiobookDetailScreen extends StatelessWidget {
  const AudiobookDetailScreen({super.key, required this.book});

  final Audiobook book;

  @override
  Widget build(BuildContext context) {
    final detailsController = Get.put(
      AudioBookDetailsController(),
      tag: book.id,
    );
    detailsController.loadDetails(book.id);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: const Color(0xFF080909),
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFF080909),
        body: Stack(
          children: [
            const _DetailGlow(),
            SafeArea(
              bottom: false,
              child: ContentWidth(
                padded: false,
                child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: _DetailHeader(title: book.title)),
                  SliverToBoxAdapter(
                    child: AspectRatio(
                      aspectRatio: 1.0,
                      child: BookCover(url: book.coverUrl, iconSize: 72),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                    sliver: SliverList.list(
                      children: [
                        _ActionPanel(book: book, controller: detailsController),
                        const SizedBox(height: 20),
                        _RatingsBlock(book: book),
                        const SizedBox(height: 10),
                        Obx(
                          () => _SynopsisBlock(
                            synopsis:
                                detailsController.details.value?.book?.synopsis,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Obx(
                          () => _ChaptersBlock(
                            chapters:
                                detailsController.details.value?.chapters ??
                                const [],
                            controller: detailsController,
                          ),
                        ),
                      ],
                    ),
                  ),
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

class _DetailGlow extends StatelessWidget {
  const _DetailGlow();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: -92,
      left: 34,
      right: -34,
      child: Container(
        height: 250,
        decoration: BoxDecoration(
          gradient: RadialGradient(
            colors: [
              const Color(0xFF673BD3).withValues(alpha: 0.82),
              const Color(0xFF111D34).withValues(alpha: 0.58),
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailHeader extends StatelessWidget {
  const _DetailHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
      child: Row(
        children: [
          Material(
            color: const Color(0xFF3B276A),
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => Navigator.maybePop(context),
              child: const SizedBox(
                width: 50,
                height: 50,
                child: Icon(Icons.arrow_back_rounded, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF40DDEB),
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionPanel extends StatelessWidget {
  const _ActionPanel({required this.book, required this.controller});

  final Audiobook book;
  final AudioBookDetailsController controller;

  Future<void> _listenNow(BuildContext context) async {
    final chapter = controller.firstChapter;
    if (chapter == null) {
      SnackbarNotifier(
        context: context,
      ).notifyError(message: 'No chapters available yet.');
      return;
    }

    await controller.playChapter(chapter);

    if (context.mounted && controller.errorMessage.value.isNotEmpty) {
      SnackbarNotifier(
        context: context,
      ).notifyError(message: controller.errorMessage.value);
    }
  }

  Future<void> _toggleLike(BuildContext context) async {
    await controller.toggleLike();

    if (context.mounted && controller.errorMessage.value.isNotEmpty) {
      SnackbarNotifier(
        context: context,
      ).notifyError(message: controller.errorMessage.value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = book is ContinueListeningBook
        ? (book as ContinueListeningBook).progress
        : 0.0;
    final chapterLabel = book is ContinueListeningBook
        ? (book as ContinueListeningBook).chapterTitle
        : '';
    final subtitle = [
      book.author,
      if (book.genreName.isNotEmpty) book.genreName,
    ].join(' - ');

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF202020),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            book.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 25,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFFAAA5AD),
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0,
            ),
          ),
          if (progress > 0) ...[
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: Text(
                    chapterLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF40DDEB),
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '${(progress * 100).round()}% complete',
                  style: const TextStyle(
                    color: Color(0xFFAAA5AD),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 7,
                backgroundColor: Colors.white30,
                valueColor: const AlwaysStoppedAnimation(Color(0xFF40DDEB)),
              ),
            ),
          ],
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 54,
                  child: Obx(() {
                    final isLoading = controller.isStreamLoading.value;
                    return FilledButton.icon(
                      onPressed: isLoading ? null : () => _listenNow(context),
                      icon: isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                color: Color(0xFF111315),
                              ),
                            )
                          : const Icon(Icons.play_arrow_rounded, size: 28),
                      label: Text(progress > 0 ? 'Resume' : 'Listen Now'),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF40DDEB),
                        foregroundColor: const Color(0xFF111315),
                        disabledBackgroundColor: const Color(
                          0xFF40DDEB,
                        ).withValues(alpha: 0.6),
                        textStyle: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 92,
                height: 54,
                child: Obx(() {
                  final liked = controller.isLiked.value;
                  final busy = controller.isTogglingLike.value;

                  return OutlinedButton(
                    onPressed: busy ? null : () => _toggleLike(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: liked
                          ? const Color(0xFFFF4D6D)
                          : Colors.white,
                      side: BorderSide(
                        color: liked
                            ? const Color(0xFFFF4D6D)
                            : Colors.white38,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    child: busy
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              color: Colors.white54,
                            ),
                          )
                        : Icon(
                            liked
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                          ),
                  );
                }),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RatingsBlock extends StatelessWidget {
  const _RatingsBlock({required this.book});

  final Audiobook book;

  @override
  Widget build(BuildContext context) {
    final rating = book.ratingAverage;
    final duration = book.formattedDuration;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ratings',
          style: TextStyle(
            color: Color(0xFFAAA5AD),
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            const Icon(Icons.star_rounded, color: Color(0xFFFFC400), size: 28),
            const SizedBox(width: 6),
            Text(
              rating > 0 ? rating.toStringAsFixed(1) : 'Not rated yet',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w800,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _StatBlock(
                label: 'Total Duration',
                value: duration.isEmpty ? '--' : duration,
              ),
            ),
            Expanded(
              child: _StatBlock(
                label: 'Chapters',
                value: book.totalChapters > 0 ? '${book.totalChapters}' : '--',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatBlock extends StatelessWidget {
  const _StatBlock({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFFAAA5AD),
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}

class _SynopsisBlock extends StatelessWidget {
  const _SynopsisBlock({this.synopsis});

  final String? synopsis;

  @override
  Widget build(BuildContext context) {
    final text = synopsis?.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(title: 'Synopsis'),
        const SizedBox(height: 10),
        Text(
          text?.isNotEmpty == true ? text! : 'No synopsis available.',
          style: const TextStyle(
            color: Color(0xFFB9B5BE),
            fontSize: 13,
            height: 1.28,
            fontWeight: FontWeight.w600,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.w800,
        letterSpacing: 0,
      ),
    );
  }
}

class _ChaptersBlock extends StatelessWidget {
  const _ChaptersBlock({required this.chapters, required this.controller});

  final List<details_model.Chapter> chapters;
  final AudioBookDetailsController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF202020),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(child: _SectionTitle(title: 'Chapters')),
              Text(
                chapters.isNotEmpty
                    ? '${chapters.length} Chapters'
                    : 'Coming soon',
                style: const TextStyle(
                  color: Color(0xFFD7F2B8),
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
          if (chapters.isNotEmpty) ...[
            const SizedBox(height: 22),
            for (var i = 0; i < chapters.length; i++) ...[
              _ChapterRow(chapter: chapters[i], controller: controller),
              if (i != chapters.length - 1) const SizedBox(height: 24),
            ],
          ],
        ],
      ),
    );
  }
}

class _ChapterRow extends StatelessWidget {
  const _ChapterRow({required this.chapter, required this.controller});

  final details_model.Chapter chapter;
  final AudioBookDetailsController controller;

  Future<void> _play(BuildContext context) async {
    await controller.playChapter(chapter);

    if (context.mounted && controller.errorMessage.value.isNotEmpty) {
      SnackbarNotifier(
        context: context,
      ).notifyError(message: controller.errorMessage.value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 58,
          child: Text(
            (chapter.chapterNumber ?? 0).toString().padLeft(2, '0'),
            style: const TextStyle(
              color: Color(0xFF6E6A72),
              fontSize: 29,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
        ),
        Expanded(
          child: Text(
            chapter.title?.isNotEmpty == true
                ? chapter.title!
                : 'Chapter ${chapter.chapterNumber ?? ''}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Obx(() {
          final isLoading = controller.isStreamLoading.value;
          return Material(
            color: Colors.white,
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: isLoading ? null : () => _play(context),
              child: SizedBox(
                width: 50,
                height: 50,
                child: isLoading
                    ? const Padding(
                        padding: EdgeInsets.all(15),
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: Color(0xFF111315),
                        ),
                      )
                    : const Icon(
                        Icons.play_arrow_rounded,
                        color: Color(0xFF111315),
                        size: 27,
                      ),
              ),
            ),
          );
        }),
      ],
    );
  }
}
