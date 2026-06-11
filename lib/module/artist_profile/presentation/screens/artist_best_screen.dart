import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ArtistBestScreen extends StatelessWidget {
  const ArtistBestScreen({super.key});

  static const _bg = Color(0xFF0B0B0C);
  static const _teal = Color(0xFF3BDDEB);
  static const _surface = Color(0xFF1C1C1E);
  static const _dimText = Color(0xFFA7A3AA);
  static const _rankColor = Color(0xFF4A4A55);

  static const _songs = <_SongItem>[
    _SongItem(
      rank: '01',
      title: 'Badsah Pulse',
      plays: '42.5M plays',
      image: 'assets/image/a1.png',
    ),
    _SongItem(
      rank: '02',
      title: 'Glow Drive',
      plays: '38.1M plays',
      image: 'assets/image/a2.png',
    ),
    _SongItem(
      rank: '03',
      title: 'Fractal Theory',
      plays: '29.8M plays',
      image: 'assets/image/a3.png',
    ),
    _SongItem(
      rank: '04',
      title: 'Why choose a theme',
      plays: '29.8M plays',
      image: 'assets/image/a4.png',
    ),
    _SongItem(
      rank: '05',
      title: 'How to build a loyal audience',
      plays: '29.8M plays',
      image: 'assets/image/a5.png',
    ),
    _SongItem(
      rank: '06',
      title: 'Start a blog to reach millions',
      plays: '29.8M plays',
      image: 'assets/image/a6.png',
    ),
    _SongItem(
      rank: '07',
      title: 'Starting your travels right',
      plays: '29.8M plays',
      image: 'assets/image/a7.png',
    ),
    _SongItem(
      rank: '08',
      title: 'Helping a local business grow',
      plays: '29.8M plays',
      image: 'assets/image/Overlay+Shadow.png',
    ),
    _SongItem(
      rank: '09',
      title: 'The unseen of spectacular',
      plays: '29.8M plays',
      image: 'assets/image/Overlay+Shadow (1).png',
    ),
    _SongItem(
      rank: '10',
      title: 'How to choose the best beat',
      plays: '29.8M plays',
      image: 'assets/image/Overlay+Shadow (2).png',
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
                  _buildHeader(context),
                  const SizedBox(height: 20),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      itemCount: _songs.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: 10),
                      itemBuilder: (_, index) =>
                          _SongTile(song: _songs[index]),
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

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          _PurpleBackButton(),
          const SizedBox(width: 16),
          const Text(
            'Best',
            style: TextStyle(
              color: _teal,
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
          const Spacer(),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.tune_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Song tile ─────────────────────────────────────────────────────────────────

class _SongTile extends StatelessWidget {
  const _SongTile({required this.song});

  final _SongItem song;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: ArtistBestScreen._surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text(
              song.rank,
              style: const TextStyle(
                color: ArtistBestScreen._rankColor,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(width: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset(
              song.image,
              width: 56,
              height: 56,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                width: 56,
                height: 56,
                color: const Color(0xFF2A2A2D),
                child: const Icon(
                  Icons.music_note_rounded,
                  color: ArtistBestScreen._teal,
                  size: 24,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  song.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  song.plays,
                  style: const TextStyle(
                    color: ArtistBestScreen._dimText,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(
            Icons.favorite_border_rounded,
            color: Colors.white70,
            size: 22,
          ),
          const SizedBox(width: 14),
          const Icon(
            Icons.more_vert_rounded,
            color: Colors.white70,
            size: 22,
          ),
        ],
      ),
    );
  }
}

// ── Back button ───────────────────────────────────────────────────────────────

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
            ArtistBestScreen._bg,
          ],
          stops: const [0, 0.15, 0.42, 0.72],
        ),
      ),
    );
  }
}

// ── Data class ────────────────────────────────────────────────────────────────

class _SongItem {
  const _SongItem({
    required this.rank,
    required this.title,
    required this.plays,
    required this.image,
  });

  final String rank;
  final String title;
  final String plays;
  final String image;
}
