import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../controller/artist_profile_controller.dart';
import '../../model/artist_profile_model.dart';
import '../widgets/artist_product_grid.dart';
import 'artist_best_screen.dart';
import 'artist_hits_screen.dart';

class ArtistProfileScreen extends StatelessWidget {
  const ArtistProfileScreen({super.key});

  static const Color _bg = Color(0xFF0B0B0C);
  static const Color _surface = Color(0xFF141417);
  static const Color _teal = Color(0xFF3BDDEB);
  static const Color _dimText = Color(0xFFA7A3AA);

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ArtistProfileController());

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: const Color(0xFF202020),
      ),
      child: Scaffold(
        backgroundColor: _bg,
        body: Stack(
          children: [
            CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: _HeroSection(controller: controller),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                  sliver: SliverList.list(
                    children: [
                      _ArtistInfo(controller: controller),
                      const SizedBox(height: 20),
                      _ActionRow(controller: controller),
                      const SizedBox(height: 20),
                      _TabBar(controller: controller),
                      const SizedBox(height: 28),
                      _TabContent(controller: controller),
                      const SizedBox(height: 110),
                    ],
                  ),
                ),
              ],
            ),
            const Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _MiniPlayer(),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Hero ──────────────────────────────────────────────────────────────────────

class _HeroSection extends StatelessWidget {
  const _HeroSection({required this.controller});

  final ArtistProfileController controller;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 360,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            controller.artist.heroImage,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => Container(
              color: const Color(0xFF1A1A2E),
              child: const Icon(Icons.person, color: Colors.white54, size: 80),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.transparent,
                  ArtistProfileScreen._bg.withValues(alpha: 0.6),
                  ArtistProfileScreen._bg,
                ],
                stops: const [0, 0.45, 0.78, 1],
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _CircleButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onTap: () => Navigator.of(context).maybePop(),
                  ),
                  const Spacer(),
                  Text(
                    controller.artist.rank,
                    style: const TextStyle(
                      color: ArtistProfileScreen._teal,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.35),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}

// ── Artist Info ───────────────────────────────────────────────────────────────

class _ArtistInfo extends StatelessWidget {
  const _ArtistInfo({required this.controller});

  final ArtistProfileController controller;

  @override
  Widget build(BuildContext context) {
    final a = controller.artist;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          a.name,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 34,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          a.monthlyListeners,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          a.bio,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 13,
            fontWeight: FontWeight.w400,
            height: 1.5,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}

// ── Action Row ────────────────────────────────────────────────────────────────

class _ActionRow extends StatelessWidget {
  const _ActionRow({required this.controller});

  final ArtistProfileController controller;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _OutlineCircleButton(
          child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 26),
          onTap: () {},
        ),
        const SizedBox(width: 14),
        GestureDetector(
          onTap: () {},
          child: const Icon(
            Icons.more_vert_rounded,
            color: Colors.white,
            size: 26,
          ),
        ),
        const Spacer(),
        Obx(
          () => GestureDetector(
            onTap: controller.toggleFollow,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
              decoration: BoxDecoration(
                color: controller.isFollowing.value
                    ? Colors.transparent
                    : ArtistProfileScreen._teal,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: ArtistProfileScreen._teal,
                  width: 1.5,
                ),
              ),
              child: Text(
                controller.isFollowing.value ? 'Following' : 'Follow',
                style: TextStyle(
                  color: controller.isFollowing.value
                      ? ArtistProfileScreen._teal
                      : Colors.black,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFF0F1B40),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.15),
              width: 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset(
              'assets/logo/logo.png',
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => const Icon(
                Icons.music_note_rounded,
                color: ArtistProfileScreen._teal,
                size: 22,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _OutlineCircleButton extends StatelessWidget {
  const _OutlineCircleButton({required this.child, required this.onTap});

  final Widget child;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 1.5),
        ),
        child: child,
      ),
    );
  }
}

// ── Tabs ──────────────────────────────────────────────────────────────────────

class _TabBar extends StatelessWidget {
  const _TabBar({required this.controller});

  final ArtistProfileController controller;

  static const _tabs = ['Artist Songs', 'Artist Products'];

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Row(
        children: [
          for (int i = 0; i < _tabs.length; i++) ...[
            GestureDetector(
              onTap: () => controller.selectTab(i),
              child: Column(
                children: [
                  Text(
                    _tabs[i],
                    style: TextStyle(
                      color: controller.selectedTab.value == i
                          ? Colors.white
                          : ArtistProfileScreen._dimText,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 8),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 2,
                    width: controller.selectedTab.value == i ? 90 : 0,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ),
            ),
            if (i < _tabs.length - 1) const SizedBox(width: 28),
          ],
        ],
      ),
    );
  }
}

// ── Tab Content ───────────────────────────────────────────────────────────────

class _TabContent extends StatelessWidget {
  const _TabContent({required this.controller});

  final ArtistProfileController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.selectedTab.value == 1) {
        return ArtistProductGrid(products: controller.artist.products);
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _HitSongsSection(controller: controller),
          const SizedBox(height: 32),
          _BestPlaylistSection(controller: controller),
          const SizedBox(height: 32),
          _HotAlbumsSection(controller: controller),
          const SizedBox(height: 32),
          _TourDatesSection(controller: controller),
          const SizedBox(height: 32),
          _PeopleAlsoLikeSection(controller: controller),
        ],
      );
    });
  }
}

// ── Hit Songs ─────────────────────────────────────────────────────────────────

class _HitSongsSection extends StatelessWidget {
  const _HitSongsSection({required this.controller});

  final ArtistProfileController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: 'Hit Songs',
          action: 'See More',
          onAction: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ArtistBestScreen()),
          ),
        ),
        const SizedBox(height: 16),
        for (final song in controller.artist.songs) ...[
          _SongTile(song: song),
          const SizedBox(height: 14),
        ],
      ],
    );
  }
}

class _SongTile extends StatelessWidget {
  const _SongTile({required this.song});

  final ArtistSongModel song;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E22),
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            song.rank,
            style: const TextStyle(
              color: ArtistProfileScreen._dimText,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.asset(
            song.cover,
            width: 48,
            height: 48,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => Container(
              width: 48,
              height: 48,
              color: const Color(0xFF1E1E22),
              child: const Icon(Icons.music_note_rounded,
                  color: ArtistProfileScreen._teal, size: 22),
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
                  color: ArtistProfileScreen._dimText,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const Icon(Icons.favorite_border_rounded, color: Colors.white70, size: 22),
        const SizedBox(width: 14),
        const Icon(Icons.more_vert_rounded, color: Colors.white70, size: 22),
      ],
    );
  }
}

// ── Best Playlist ─────────────────────────────────────────────────────────────

class _BestPlaylistSection extends StatelessWidget {
  const _BestPlaylistSection({required this.controller});

  final ArtistProfileController controller;

  @override
  Widget build(BuildContext context) {
    final a = controller.artist;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Artist Best Playlist',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 16),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              SizedBox(
                height: 240,
                width: double.infinity,
                child: Image.asset(
                  a.playlistCover,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    color: const Color(0xFF1A1A2E),
                    child: const Icon(Icons.music_note_rounded,
                        color: Colors.white30, size: 60),
                  ),
                ),
              ),
              Container(
                height: 240,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.1),
                      Colors.black.withValues(alpha: 0.7),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 16,
                left: 16,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2), width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 10,
                        backgroundImage:
                            AssetImage(a.heroImage),
                        onBackgroundImageError: (_, _) {},
                        backgroundColor: ArtistProfileScreen._teal,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Listen to ${a.name}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: 16,
                left: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'BEST OF',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.5,
                      ),
                    ),
                    Text(
                      a.name.split(' ').first,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        height: 1.0,
                        letterSpacing: -1,
                      ),
                    ),
                    Text(
                      a.name.split(' ').last,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        height: 1.0,
                        letterSpacing: -1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 1),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: ArtistProfileScreen._surface,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(16),
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundImage: AssetImage(a.heroImage),
                onBackgroundImageError: (_, _) {},
                backgroundColor: ArtistProfileScreen._teal,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    a.playlistTitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Text(
                    'Playlist',
                    style: TextStyle(
                      color: ArtistProfileScreen._dimText,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Hot Albums ────────────────────────────────────────────────────────────────

class _HotAlbumsSection extends StatelessWidget {
  const _HotAlbumsSection({required this.controller});

  final ArtistProfileController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: 'Hot Albums',
          action: 'View All',
          onAction: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ArtistHitsScreen()),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 168,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: controller.artist.albums.length,
            separatorBuilder: (_, _) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final album = controller.artist.albums[index];
              return _AlbumCard(album: album);
            },
          ),
        ),
      ],
    );
  }
}

class _AlbumCard extends StatelessWidget {
  const _AlbumCard({required this.album});

  final AlbumModel album;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 130,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.asset(
              album.cover,
              width: 130,
              height: 130,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                width: 130,
                height: 130,
                color: const Color(0xFF1E1E22),
                child: const Icon(Icons.album_rounded,
                    color: ArtistProfileScreen._teal, size: 40),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            album.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            '${album.type} · ${album.year}',
            style: const TextStyle(
              color: ArtistProfileScreen._dimText,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Tour Dates ────────────────────────────────────────────────────────────────

class _TourDatesSection extends StatelessWidget {
  const _TourDatesSection({required this.controller});

  final ArtistProfileController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tour Dates',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 16),
        for (final tour in controller.artist.tourDates) ...[
          _TourDateTile(tour: tour),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _TourDateTile extends StatelessWidget {
  const _TourDateTile({required this.tour});

  final TourDateModel tour;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: ArtistProfileScreen._surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Column(
            children: [
              Text(
                tour.month,
                style: const TextStyle(
                  color: ArtistProfileScreen._dimText,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
              Text(
                tour.day,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  height: 1.1,
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Container(width: 1, height: 40, color: Colors.white12),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tour.venue,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  tour.location,
                  style: const TextStyle(
                    color: ArtistProfileScreen._dimText,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: tour.isSoldOut ? null : () {},
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: tour.isSoldOut
                      ? Colors.white24
                      : ArtistProfileScreen._teal,
                  width: 1.5,
                ),
              ),
              child: Text(
                tour.isSoldOut ? 'Sold Out' : 'Get Tickets',
                style: TextStyle(
                  color: tour.isSoldOut
                      ? Colors.white38
                      : ArtistProfileScreen._teal,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── People Also Like ──────────────────────────────────────────────────────────

class _PeopleAlsoLikeSection extends StatelessWidget {
  const _PeopleAlsoLikeSection({required this.controller});

  final ArtistProfileController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'People also like',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 100,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: controller.artist.similarArtists.length,
            separatorBuilder: (_, _) => const SizedBox(width: 20),
            itemBuilder: (context, index) {
              final artist = controller.artist.similarArtists[index];
              return _SimilarArtistTile(artist: artist);
            },
          ),
        ),
      ],
    );
  }
}

class _SimilarArtistTile extends StatelessWidget {
  const _SimilarArtistTile({required this.artist});

  final SimilarArtistModel artist;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 70,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: const BoxDecoration(shape: BoxShape.circle),
            child: ClipOval(
              child: Image.asset(
                artist.image,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  color: const Color(0xFF1E1E22),
                  child: const Icon(Icons.person,
                      color: Colors.white54, size: 30),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            artist.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Text(
            'Artist',
            style: TextStyle(
              color: ArtistProfileScreen._dimText,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Mini Player ───────────────────────────────────────────────────────────────

class _MiniPlayer extends StatelessWidget {
  const _MiniPlayer();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset(
              'assets/image/Overlay+Shadow.png',
              width: 44,
              height: 44,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                width: 44,
                height: 44,
                color: const Color(0xFF2A2A2D),
                child: const Icon(Icons.music_note_rounded,
                    color: ArtistProfileScreen._teal, size: 22),
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bhalo Thake Mon',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Fahim Islam',
                  style: TextStyle(
                    color: ArtistProfileScreen._dimText,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: ArtistProfileScreen._teal,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.pause_rounded, color: Colors.black, size: 22),
          ),
        ],
      ),
    );
  }
}

// ── Shared ────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.action,
    required this.onAction,
  });

  final String title;
  final String action;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const Spacer(),
        GestureDetector(
          onTap: onAction,
          child: Text(
            action,
            style: const TextStyle(
              color: ArtistProfileScreen._teal,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
