import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../model/audiobook_model.dart';

class AudiobookNewReleasesScreen extends StatelessWidget {
  const AudiobookNewReleasesScreen({super.key, required this.books});

  final List<AudiobookModel> books;

  static const _genres = [
    'All Genres',
    'Fiction',
    'Non-Fiction',
    'Biography',
    'Mystery',
    'Fantasy',
    'Sci-Fi',
  ];

  @override
  Widget build(BuildContext context) {
    final currentBook = books.isNotEmpty ? books.first : null;

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
              child: CustomScrollView(
                slivers: [
                  const SliverToBoxAdapter(child: _ReleaseHeader()),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 34, 16, 120),
                    sliver: SliverList.list(
                      children: [
                        Wrap(
                          spacing: 12,
                          runSpacing: 14,
                          children: [
                            for (var i = 0; i < _genres.length; i++)
                              _ReleaseChip(label: _genres[i], selected: i == 0),
                          ],
                        ),
                        const SizedBox(height: 34),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: books.length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 24,
                                mainAxisSpacing: 30,
                                childAspectRatio: 0.56,
                              ),
                          itemBuilder: (context, index) =>
                              _ReleaseGridCard(book: books[index]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (currentBook != null) _ReleaseMiniPlayer(book: currentBook),
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
  const _ReleaseChip({required this.label, required this.selected});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFF40DDEB) : const Color(0xFF202020),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: selected ? const Color(0xFF0E1112) : const Color(0xFFAAA5AD),
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class _ReleaseGridCard extends StatelessWidget {
  const _ReleaseGridCard({required this.book});

  final AudiobookModel book;

  @override
  Widget build(BuildContext context) {
    return Column(
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
              child: Image.asset(
                book.cover,
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
                errorBuilder: (context, error, stackTrace) => const ColoredBox(
                  color: Color(0xFF202020),
                  child: Icon(
                    Icons.menu_book_rounded,
                    color: Colors.white38,
                    size: 54,
                  ),
                ),
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
    );
  }
}

class _ReleaseMiniPlayer extends StatelessWidget {
  const _ReleaseMiniPlayer({required this.book});

  final AudiobookModel book;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 16,
      right: 16,
      bottom: 24,
      child: SafeArea(
        top: false,
        child: Container(
          height: 72,
          padding: const EdgeInsets.fromLTRB(12, 8, 10, 8),
          decoration: BoxDecoration(
            color: const Color(0xFF151617),
            borderRadius: BorderRadius.circular(36),
            border: Border.all(color: const Color(0xFF124A56), width: 1),
          ),
          child: Row(
            children: [
              ClipOval(
                child: Image.asset(
                  'assets/image/audiobook_paradox.png',
                  width: 52,
                  height: 52,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      book.author,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFFAAA5AD),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 52,
                height: 52,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF9BFF4D), Color(0xFF40DDEB)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.pause_rounded,
                  color: Color(0xFF111113),
                  size: 32,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
