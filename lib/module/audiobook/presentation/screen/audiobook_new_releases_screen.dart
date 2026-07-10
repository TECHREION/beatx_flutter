import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../controller/audiobook_controller.dart';
import '../../model/audiobook_model.dart';
import '../widget/book_cover.dart';
import 'audiobook_detail_screen.dart';

class AudiobookNewReleasesScreen extends StatefulWidget {
  const AudiobookNewReleasesScreen({super.key, required this.books});

  final List<Audiobook> books;

  @override
  State<AudiobookNewReleasesScreen> createState() =>
      _AudiobookNewReleasesScreenState();
}

class _AudiobookNewReleasesScreenState
    extends State<AudiobookNewReleasesScreen> {
  String _selectedGenre = AudiobookController.allGenres;

  List<String> get _genres {
    final names = <String>{for (final book in widget.books) book.genreName}
      ..removeWhere((name) => name.isEmpty);

    return [AudiobookController.allGenres, ...names];
  }

  List<Audiobook> get _filteredBooks {
    if (_selectedGenre == AudiobookController.allGenres) return widget.books;
    return widget.books
        .where((book) => book.genreName == _selectedGenre)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final books = _filteredBooks;

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
                            for (final genre in _genres)
                              _ReleaseChip(
                                label: genre,
                                selected: genre == _selectedGenre,
                                onTap: () =>
                                    setState(() => _selectedGenre = genre),
                              ),
                          ],
                        ),
                        const SizedBox(height: 34),
                        if (books.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 40),
                            child: Text(
                              'No releases in this genre.',
                              style: TextStyle(
                                color: Color(0xFF77727A),
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0,
                              ),
                            ),
                          )
                        else
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
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
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      AudiobookDetailScreen(book: books[index]),
                                ),
                              ),
                            ),
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
