import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../model/audiobook_model.dart';
import '../widget/book_cover.dart';

class AudiobookDetailScreen extends StatelessWidget {
  const AudiobookDetailScreen({super.key, required this.book});

  final Audiobook book;

  @override
  Widget build(BuildContext context) {
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
                        _ActionPanel(book: book),
                        const SizedBox(height: 20),
                        _RatingsBlock(book: book),
                        const SizedBox(height: 10),
                        const _SynopsisBlock(),
                        const SizedBox(height: 20),
                        _ChaptersBlock(totalChapters: book.totalChapters),
                      ],
                    ),
                  ),
                ],
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
  const _ActionPanel({required this.book});

  final Audiobook book;

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
                  child: FilledButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.play_arrow_rounded, size: 28),
                    label: Text(progress > 0 ? 'Resume' : 'Listen Now'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF40DDEB),
                      foregroundColor: const Color(0xFF111315),
                      textStyle: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 92,
                height: 54,
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white38),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: const Icon(Icons.bookmark_border_rounded),
                ),
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
  const _SynopsisBlock();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(title: 'Synopsis'),
        SizedBox(height: 10),
        Text(
          'Ryland grace is the sole survivor on a desperate, last-chance mission-and if he fails, humanity and the earth itself will perish. Except that right now, he does not know that. He cannot even remember his own name, let alone the nature of his assignment or how to complete it.',
          style: TextStyle(
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
  const _ChaptersBlock({required this.totalChapters});

  final int totalChapters;

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
                totalChapters > 0 ? '$totalChapters Chapters' : 'Coming soon',
                style: const TextStyle(
                  color: Color(0xFFD7F2B8),
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
          if (totalChapters > 0) ...[
            const SizedBox(height: 22),
            for (var i = 1; i <= totalChapters; i++) ...[
              _ChapterRow(index: i),
              if (i != totalChapters) const SizedBox(height: 24),
            ],
          ],
        ],
      ),
    );
  }
}

class _ChapterRow extends StatelessWidget {
  const _ChapterRow({required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 58,
          child: Text(
            index.toString().padLeft(2, '0'),
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
            'Chapter $index',
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
        Container(
          width: 50,
          height: 50,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.north_east_rounded,
            color: Color(0xFF111315),
            size: 25,
          ),
        ),
      ],
    );
  }
}
