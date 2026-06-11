import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ArtistHitsScreen extends StatelessWidget {
  const ArtistHitsScreen({super.key});

  static const _bg = Color(0xFF0B0B0C);
  static const _teal = Color(0xFF3BDDEB);
  static const _dimText = Color(0xFFA7A3AA);

  static const _albums = <_AlbumItem>[
    _AlbumItem(
      title: 'Synth Horizon',
      type: 'Album',
      year: '2024',
      image: 'assets/image/genre_synth_wave.png',
    ),
    _AlbumItem(
      title: 'Synth Horizon',
      type: 'Album',
      year: '2024',
      image: 'assets/image/Container.png',
    ),
    _AlbumItem(
      title: 'Static Dreams',
      type: 'EP',
      year: '2022',
      image: 'assets/image/genre_hiphop_soul.png',
    ),
    _AlbumItem(
      title: 'Jazz',
      type: 'Album',
      year: '2024',
      image: 'assets/image/genre_jazz.png',
    ),
    _AlbumItem(
      title: 'Podcasts',
      type: 'EP',
      year: '2022',
      image: 'assets/image/genre_podcasts.png',
    ),
    _AlbumItem(
      title: 'Hip Hop & Soul',
      type: 'Album',
      year: '2024',
      image: 'assets/image/genre_hiphop_soul.png',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: const Color(0xFF202020),
      ),
      child: Scaffold(
        backgroundColor: _bg,
        body: Stack(
          children: [
            const Positioned.fill(child: _PageGradient()),
            SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Header(title: "Hit's"),
                  const SizedBox(height: 24),
                  Expanded(
                    child: GridView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 24,
                        childAspectRatio: 0.8,
                      ),
                      itemCount: _albums.length,
                      itemBuilder: (_, index) =>
                          _AlbumCard(item: _albums[index]),
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

// ── Shared header ─────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          const _PurpleBackButton(),
          const SizedBox(width: 16),
          Text(
            title,
            style: const TextStyle(
              color: ArtistHitsScreen._teal,
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _PurpleBackButton extends StatelessWidget {
  const _PurpleBackButton();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF2E1F72),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => Navigator.of(context).maybePop(),
        child: const SizedBox(
          width: 44,
          height: 44,
          child: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 18,
          ),
        ),
      ),
    );
  }
}

// ── Album card ────────────────────────────────────────────────────────────────

class _AlbumCard extends StatelessWidget {
  const _AlbumCard({required this.item});

  final _AlbumItem item;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.asset(
              item.image,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                color: const Color(0xFF1E1E22),
                child: const Icon(
                  Icons.album_rounded,
                  color: Colors.white24,
                  size: 48,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          item.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          '${item.type} • ${item.year}',
          style: const TextStyle(
            color: ArtistHitsScreen._dimText,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ── Background gradient ───────────────────────────────────────────────────────

class _PageGradient extends StatelessWidget {
  const _PageGradient();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF1E1060),
            const Color(0xFF2A1870),
            const Color(0xFF12093A),
            ArtistHitsScreen._bg,
          ],
          stops: const [0, 0.15, 0.42, 0.72],
        ),
      ),
    );
  }
}

// ── Data class ────────────────────────────────────────────────────────────────

class _AlbumItem {
  const _AlbumItem({
    required this.title,
    required this.type,
    required this.year,
    required this.image,
  });

  final String title;
  final String type;
  final String year;
  final String image;
}
