import 'package:flutter/material.dart';
import 'package:beatx_flutter/core/common/widget/mini_player_host.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../../core/common/background_image.dart';
import '../../../../core/common/widget/app_header.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/responsive.dart';

import '../../controller/artist_profile_controller.dart';
import '../../model/artist_profile_model.dart';
import '../../../shop/presentation/widgets/get_tickets_screen.dart';
import 'artist_image.dart';
import 'artist_product_grid.dart';

/// A public artist page (`GET /artists/:id` plus the artist's songs,
/// albums, upcoming events, related artists and products).
class ArtistProfileScreen extends StatefulWidget {
  const ArtistProfileScreen({super.key, required this.artistId});

  final String artistId;

  static const Color _bg = Color(0xFF0B0B0C);
  static const Color _surface = Color(0xFF141417);
  static const Color _teal = Color(0xFF3BDDEB);
  static const Color _dimText = Color(0xFFA7A3AA);
  static const Color _green = Color(0xFF56E768);

  /// Opens [artistId]'s page.
  static void open(BuildContext context, String artistId) {
    if (artistId.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ArtistProfileScreen(artistId: artistId),
      ),
    );
  }

  @override
  State<ArtistProfileScreen> createState() => _ArtistProfileScreenState();
}

class _ArtistProfileScreenState extends State<ArtistProfileScreen> {
  // Owned by this page (not registered globally), so opening a related
  // artist's page on top keeps each page's own data.
  late final ArtistProfileController controller = ArtistProfileController(
    widget.artistId,
  )..onInit();

  @override
  void dispose() {
    controller.onClose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Same frame as the Home and Watch tabs: the app background, a fixed
    // header row, and the content scrolling beneath it.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: ArtistProfileScreen._bg,
        body: AppBackgroundImage(
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                Obx(
                  () => AppHeader(
                    title: controller.profile.value == null
                        ? 'Artist'
                        : controller.artist.name,
                    onBack: () => Navigator.of(context).maybePop(),
                    showActions: false,
                    titleTrailing:
                        controller.profile.value != null &&
                            controller.artist.isVerified
                        ? const Icon(
                            Icons.verified_rounded,
                            color: ArtistProfileScreen._green,
                            size: 18,
                          )
                        : null,
                  ),
                ),
                Expanded(
                  child: Obx(() {
                    if (controller.profile.value == null) {
                      return _LoadState(controller: controller);
                    }
                    return ContentWidth.wide(
                      padded: false,
                      child: RefreshIndicator(
                        color: ArtistProfileScreen._teal,
                        onRefresh: controller.load,
                        child: CustomScrollView(
                          slivers: [
                            SliverPadding(
                              padding: const EdgeInsets.fromLTRB(
                                AppSizes.screenHorizontalPadding,
                                20,
                                AppSizes.screenHorizontalPadding,
                                0,
                              ),
                              sliver: SliverList.list(
                                children: [
                                  _HeroSection(controller: controller),
                                  const SizedBox(height: 20),
                                  _ArtistInfo(controller: controller),
                                  const SizedBox(height: 20),
                                  _ActionRow(controller: controller),
                                  const SizedBox(height: 20),
                                  _TabBar(controller: controller),
                                  const SizedBox(height: 28),
                                  _TabContent(controller: controller),
                                  // Clears the floating player.
                                  const SizedBox(height: 110),
                                ],
                              ),
                            ),
                            // Room to scroll the last items clear of the mini player.
                            const SliverMiniPlayerSpacer(),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Loading spinner, or the error with a retry, before the profile arrives.
class _LoadState extends StatelessWidget {
  const _LoadState({required this.controller});

  final ArtistProfileController controller;

  @override
  Widget build(BuildContext context) {
    final loading = controller.isLoading.value;
    final message = controller.errorMessage.value;
    return Center(
      child: loading
          ? const CircularProgressIndicator(color: ArtistProfileScreen._teal)
          : Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.person_off_rounded,
                    color: Colors.white38,
                    size: 48,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    message.isEmpty ? 'This artist is not available.' : message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: ArtistProfileScreen._dimText),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: controller.load,
                    child: const Text(
                      'Try again',
                      style: TextStyle(color: ArtistProfileScreen._teal),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

// ── Hero ──────────────────────────────────────────────────────────────────────

/// The artist's picture as a rounded card, like the Home and Watch heroes.
class _HeroSection extends StatelessWidget {
  const _HeroSection({required this.controller});

  final ArtistProfileController controller;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: AspectRatio(
        aspectRatio: 1.1,
        child: Stack(
          fit: StackFit.expand,
          children: [
            artistImage(
              controller.artist.heroImage,
              fallback: Container(
                color: const Color(0xFF1A1A2E),
                child: const Icon(
                  Icons.person,
                  color: Colors.white54,
                  size: 80,
                ),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.55),
                  ],
                  stops: const [0.55, 1],
                ),
              ),
            ),
          ],
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
        Text.rich(
          TextSpan(
            text: a.name,
            children: [
              if (a.isVerified)
                const WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: Icon(
                      Icons.verified_rounded,
                      color: ArtistProfileScreen._green,
                      size: 26,
                    ),
                  ),
                ),
            ],
          ),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 34,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
            height: 1.1,
          ),
        ),
        if (a.isVerified) ...[
          const SizedBox(height: 6),
          const Text(
            'Verified Artist',
            style: TextStyle(
              color: ArtistProfileScreen._green,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
          ),
        ],
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
          onTap: controller.playTop,
          child: const Icon(
            Icons.play_arrow_rounded,
            color: Colors.white,
            size: 26,
          ),
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
      final a = controller.artist;
      if (controller.selectedTab.value == 1) {
        if (a.products.isEmpty) {
          return const _EmptySection('No products from this artist yet.');
        }
        return ArtistProductGrid(products: a.products);
      }
      // Sections with nothing in them are left out.
      final sections = <Widget>[
        if (a.songs.isNotEmpty) _HitSongsSection(controller: controller),
        if (a.songs.isNotEmpty) _BestPlaylistSection(controller: controller),
        if (a.albums.isNotEmpty) _HotAlbumsSection(controller: controller),
        if (a.tourDates.isNotEmpty) _TourDatesSection(controller: controller),
        if (a.similarArtists.isNotEmpty)
          _PeopleAlsoLikeSection(controller: controller),
      ];
      if (sections.isEmpty) {
        return const _EmptySection('No songs from this artist yet.');
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < sections.length; i++) ...[
            if (i > 0) const SizedBox(height: 32),
            sections[i],
          ],
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
        const _SectionHeader(title: 'Hit Songs'),
        const SizedBox(height: 16),
        for (final song in controller.artist.songs) ...[
          _SongTile(song: song, onTap: () => controller.playSong(song.id)),
          const SizedBox(height: 14),
        ],
      ],
    );
  }
}

class _SongTile extends StatelessWidget {
  const _SongTile({required this.song, required this.onTap});

  final ArtistSongModel song;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Row(
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
            child: artistImage(
              song.cover,
              width: 48,
              height: 48,
              fallback: Container(
                width: 48,
                height: 48,
                color: const Color(0xFF1E1E22),
                child: const Icon(
                  Icons.music_note_rounded,
                  color: ArtistProfileScreen._teal,
                  size: 22,
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
          const Icon(
            Icons.play_circle_outline_rounded,
            color: Colors.white70,
            size: 26,
          ),
        ],
      ),
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
        GestureDetector(
          onTap: controller.playTop,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                SizedBox(
                  height: 240,
                  width: double.infinity,
                  child: artistImage(
                    a.playlistCover,
                    fallback: Container(
                      color: const Color(0xFF1A1A2E),
                      child: const Icon(
                        Icons.music_note_rounded,
                        color: Colors.white30,
                        size: 60,
                      ),
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          radius: 10,
                          backgroundImage: artistImageProvider(a.avatar),
                          onBackgroundImageError: a.avatar.isEmpty
                              ? null
                              : (_, _) {},
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
                      if (a.name.trim().contains(' '))
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
                backgroundImage: artistImageProvider(a.avatar),
                onBackgroundImageError: a.avatar.isEmpty ? null : (_, _) {},
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
        const _SectionHeader(title: 'Hot Albums'),
        const SizedBox(height: 16),
        SizedBox(
          height: 180,
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
            child: artistImage(
              album.cover,
              width: 130,
              height: 130,
              fallback: Container(
                width: 130,
                height: 130,
                color: const Color(0xFF1E1E22),
                child: const Icon(
                  Icons.album_rounded,
                  color: ArtistProfileScreen._teal,
                  size: 40,
                ),
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
            album.year.isEmpty ? album.type : '${album.type} · ${album.year}',
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
            onTap: tour.isSoldOut || tour.event == null
                ? null
                : () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => GetTicketScreen(event: tour.event!),
                    ),
                  ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
    return GestureDetector(
      onTap: () => ArtistProfileScreen.open(context, artist.id),
      child: SizedBox(
        width: 70,
        child: Column(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: const BoxDecoration(shape: BoxShape.circle),
              child: ClipOval(
                child: artistImage(
                  artist.image,
                  fallback: Container(
                    color: const Color(0xFF1E1E22),
                    child: const Icon(
                      Icons.person,
                      color: Colors.white54,
                      size: 30,
                    ),
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
      ),
    );
  }
}

// ── Shared ────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

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
      ],
    );
  }
}

class _EmptySection extends StatelessWidget {
  const _EmptySection(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Text(
          message,
          style: const TextStyle(
            color: ArtistProfileScreen._dimText,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
