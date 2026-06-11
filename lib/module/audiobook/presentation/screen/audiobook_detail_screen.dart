import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../model/audiobook_model.dart';

class AudiobookDetailScreen extends StatelessWidget {
  const AudiobookDetailScreen({super.key, required this.book});

  final AudiobookModel book;

  static const _chapters = [
    'Chapter 1: The Eridian',
    'Chapter 2: The Eridian',
    'Chapter 3: The Eridian',
    'Chapter 4: The Eridian',
    'Chapter 5: The Eridian',
    'Chapter 6: The Eridian',
    'Chapter 7: The Eridian',
    'Chapter 8: The Eridian',
    'Chapter 9: The Eridian',
    'Chapter 10: The Eridian',
    'Chapter 11: The Eridian',
    'Chapter 12: The Eridian',
    'Chapter 13: The Eridian',
    'Chapter 14: The Eridian',
  ];

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
                      child: Image.asset(book.cover, fit: BoxFit.cover),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                    sliver: SliverList.list(
                      children: [
                        _ActionPanel(book: book),
                        const SizedBox(height: 20),
                        const _RatingsBlock(),
                        const SizedBox(height: 10),
                        const _SynopsisBlock(),
                        const SizedBox(height: 20),
                        const _UniverseHeader(),
                        const SizedBox(height: 16),
                        _UniverseBookCard(
                          label: 'PREQUEL',
                          labelColor: const Color(0xFF128596),
                          expanded: true,
                          chapters: _chapters.take(5).toList(),
                        ),
                        const SizedBox(height: 20),
                        const _UniverseBookCard(
                          label: 'SEQUEL',
                          labelColor: Color(0xFF667752),
                          expanded: false,
                          chapters: [],
                        ),
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

  final AudiobookModel book;

  @override
  Widget build(BuildContext context) {
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
            '${book.author} - Narrated by ${book.narrator}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFFAAA5AD),
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: Text(
                  book.chapter,
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
                '${(book.progress * 100).round()}% complete',
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
              value: book.progress,
              minHeight: 7,
              backgroundColor: Colors.white30,
              valueColor: const AlwaysStoppedAnimation(Color(0xFF40DDEB)),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 54,
                  child: FilledButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.play_arrow_rounded, size: 28),
                    label: const Text('Listen Now'),
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
  const _RatingsBlock();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ratings',
          style: TextStyle(
            color: Color(0xFFAAA5AD),
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
          ),
        ),
        SizedBox(height: 10),
        Row(
          children: [
            Icon(Icons.star_rounded, color: Color(0xFFFFC400), size: 28),
            SizedBox(width: 6),
            Text(
              '4.9 (24.5k reviews)',
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w800,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _StatBlock(label: 'Total Duration', value: '16h 10m'),
            ),
            Expanded(
              child: _StatBlock(label: 'Language', value: 'English'),
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

class _UniverseHeader extends StatelessWidget {
  const _UniverseHeader();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(child: _SectionTitle(title: 'In this Universe')),
        Text(
          '2 Books',
          style: TextStyle(
            color: Color(0xFFD7F2B8),
            fontSize: 17,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}

class _UniverseBookCard extends StatelessWidget {
  const _UniverseBookCard({
    required this.label,
    required this.labelColor,
    required this.expanded,
    required this.chapters,
  });

  final String label;
  final Color labelColor;
  final bool expanded;
  final List<String> chapters;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      decoration: BoxDecoration(
        color: const Color(0xFF202020),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.asset(
                  'assets/image/audiobook_hail_mary_cover.png',
                  width: 78,
                  height: 78,
                  fit: BoxFit.cover,
                  alignment: Alignment.topLeft,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: labelColor,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        label,
                        style: const TextStyle(
                          color: Color(0xFFDDF5FF),
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Project Hali Mary',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '4h 22m - Narrated by Ray Porter',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Color(0xFFAAA5AD),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'View Chapters',
                  style: TextStyle(
                    color: Color(0xFFAAA5AD),
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
              ),
              Icon(
                expanded
                    ? Icons.keyboard_arrow_up_rounded
                    : Icons.keyboard_arrow_down_rounded,
                color: const Color(0xFFAAA5AD),
                size: 30,
              ),
            ],
          ),
          if (expanded) ...[
            const SizedBox(height: 22),
            for (var i = 0; i < chapters.length; i++) ...[
              _UniverseChapterRow(index: i + 1, title: chapters[i]),
              if (i != chapters.length - 1) const SizedBox(height: 30),
            ],
          ],
        ],
      ),
    );
  }
}

class _UniverseChapterRow extends StatelessWidget {
  const _UniverseChapterRow({required this.index, required this.title});

  final int index;
  final String title;

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
            title,
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
