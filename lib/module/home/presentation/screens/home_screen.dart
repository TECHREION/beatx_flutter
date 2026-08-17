import 'dart:ui';

import 'package:beatx_flutter/core/player/player_controller.dart';
import 'package:beatx_flutter/module/artist_profile/presentation/screens/artist_profile_screen.dart';
import 'package:beatx_flutter/module/home/controller/home_controller.dart';
import 'package:beatx_flutter/module/home/controller/liked_songs_controller.dart';
import 'package:beatx_flutter/module/home/presentation/screens/audio_play_screen.dart';
import 'package:beatx_flutter/module/home/presentation/screens/daily_discover_screen.dart';
import 'package:beatx_flutter/module/home/presentation/screens/liked_songs_screen.dart';
import 'package:beatx_flutter/module/home/presentation/screens/song_search_screen.dart';
import 'package:beatx_flutter/module/home/presentation/screens/on_repeat_screen.dart';
import 'package:beatx_flutter/module/home/presentation/screens/recently_played_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/common/background_image.dart';
import '../../../../core/common/widget/app_header.dart';
import '../../../../core/theme/app_sizes.dart';

class HomeScreen extends StatelessWidget {
  HomeScreen({super.key});

  final HomeController controller = Get.put(HomeController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0B0C),
      body: AppBackgroundImage(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              AppHeader(
                showLogo: true,
                onSearchTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SongSearchScreen()),
                ),
                notificationBadge: '3',
              ),
              Expanded(
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
                          const _SectionTitle(
                            title: 'Trending Now',
                            action: 'See all',
                          ),
                          const SizedBox(height: 16),
                          Obx(() {
                            final item = controller.trending.isNotEmpty
                                ? controller.trending.first
                                : null;
                            final title = item?.title ?? 'Tumi Acho Bole';
                            final artist = item?.artist ?? 'Imran Mahmudul';

                            return _TrendingCard(
                              title: title,
                              artist: artist,
                              coverUrl: item?.coverUrl,
                              onPlay: () {
                                if (item != null) {
                                  controller.playSong(item.id);
                                  return;
                                }
                                Get.find<PlayerController>().play(
                                  title: title,
                                  artist: artist,
                                  imageAsset: 'assets/image/a4.png',
                                  audioAsset: 'audio/music1.m4a',
                                );
                                Get.to(
                                  () => const PlayerScreen(),
                                  transition: Transition.downToUp,
                                  preventDuplicates: true,
                                );
                              },
                            );
                          }),
                          const SizedBox(height: 36),
                          const _SectionTitle(title: 'Your Mix'),
                          const SizedBox(height: 16),
                          const _DailyDiscoverCard(),
                          const SizedBox(height: 16),
                          const _MixGrid(),
                          const SizedBox(height: 16),
                          const _SectionTitle(title: 'Explore More'),
                          const SizedBox(height: 16),
                          const _ExploreRow(),
                          const SizedBox(height: 32),
                          const _NewReleaseHeader(),
                          const SizedBox(height: 16),
                          Obx(() {
                            final releases = controller.newReleases;
                            final items = releases.isEmpty
                                ? _defaultNewReleases
                                : [
                                    for (
                                      var i = 0;
                                      i < releases.length;
                                      i++
                                    )
                                      _ReleaseData(
                                        title: releases[i].title,
                                        subtitle:
                                            '${releases[i].artist} - Single',
                                        artist: releases[i].artist,
                                        meta: _formatDurationMs(
                                          releases[i].durationMs,
                                        ),
                                        asset: 'assets/image/Container.png',
                                        audioAsset: _placeholderAudioAssets[i %
                                            _placeholderAudioAssets.length],
                                        coverUrl: releases[i].coverUrl,
                                        listenId: releases[i].id,
                                      ),
                                  ];

                            return _NewReleaseList(items: items);
                          }),
                          const SizedBox(height: 28),
                          const _SectionTitle(title: 'Artists to Watch'),
                          const SizedBox(height: 14),
                          const _ArtistWatchList(),
                          Obx(() {
                            final hasActiveTrack = Get.find<PlayerController>()
                                .title
                                .value
                                .isNotEmpty;
                            return SizedBox(height: hasActiveTrack ? 196 : 104);
                          }),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.action});

  final String title;
  final String? action;

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
            letterSpacing: 0,
          ),
        ),
        const Spacer(),
        if (action != null)
          Text(
            action!,
            style: const TextStyle(
              color: Color(0xFF64FF8F),
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
          ),
      ],
    );
  }
}

class _TrendingCard extends StatelessWidget {
  const _TrendingCard({
    this.title = 'Tumi Acho Bole',
    this.artist = 'Imran Mahmudul',
    this.coverUrl,
    this.onPlay,
  });

  final String title;
  final String artist;
  final String? coverUrl;
  final VoidCallback? onPlay;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.03,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.14),
            width: 1.2,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(29),
          child: Stack(
            fit: StackFit.expand,
            children: [
              _ArtworkBackground(
                asset: 'assets/image/a4.png',
                imageUrl: coverUrl,
                colors: const [Color(0xFFE7E7E7), Color(0xFF8C8C8C)],
              ),
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(50),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(20, 14, 14, 14),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.40),
                        borderRadius: BorderRadius.circular(50),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.10),
                          width: 1,
                        ),
                      ),
                      child: GestureDetector(
                        onTap: onPlay,
                        behavior: HitTestBehavior.opaque,
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 19,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    artist,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.58,
                                      ),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      letterSpacing: 0,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: 54,
                              height: 54,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFF64FF8F),
                                    Color(0xFF40DDEB),
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFF64FF8F,
                                    ).withValues(alpha: 0.35),
                                    blurRadius: 14,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.play_arrow_rounded,
                                color: Colors.black,
                                size: 28,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DailyDiscoverCard extends StatelessWidget {
  const _DailyDiscoverCard();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Get.to(
        () => const DailyDiscoverScreen(),
        transition: Transition.rightToLeft,
        preventDuplicates: true,
      ),
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 220,
        padding: const EdgeInsets.all(26),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF19191C), Color(0xFF322846)],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.auto_awesome_rounded,
              color: Color(0xFFD38BFF),
              size: 33,
            ),
            const Spacer(),
            const Text(
              'Daily\nDiscover',
              style: TextStyle(
                color: Colors.white,
                fontSize: 31,
                height: 1.2,
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                const _StackedAvatars(),
                const SizedBox(width: 14),
                Text(
                  'New for you',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.62),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StackedAvatars extends StatelessWidget {
  const _StackedAvatars();

  @override
  Widget build(BuildContext context) {
    const colors = [Color(0xFF74D7FF), Color(0xFFFFB35E), Color(0xFFEDEDED)];
    return SizedBox(
      width: 64,
      height: 30,
      child: Stack(
        children: List.generate(colors.length, (index) {
          return Positioned(
            left: index * 18,
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: colors[index],
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF322846), width: 2),
              ),
              child: Icon(
                Icons.person,
                size: 18,
                color: index == 2 ? Colors.black : Colors.white,
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _MixGrid extends StatelessWidget {
  const _MixGrid();

  static const _tileAspectRatio = 1.23;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: AspectRatio(
                aspectRatio: _tileAspectRatio,
                child: Obx(() {
                  final liked = LikedSongsController.instance;
                  return _MixTile(
                    icon: Icons.favorite_rounded,
                    title: 'Liked Songs',
                    subtitle: _likedSubtitle(liked),
                    iconColor: const Color(0xFF4DEBFF),
                    onTap: () => Get.to(
                      () => const LikedSongsScreen(),
                      transition: Transition.rightToLeft,
                      preventDuplicates: true,
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: AspectRatio(
                aspectRatio: _tileAspectRatio,
                child: _MixTile(
                  icon: Icons.bolt_rounded,
                  title: 'On Repeat',
                  subtitle: 'Top played',
                  iconColor: const Color(0xFF6CFF8B),
                  onTap: () => Get.to(
                    () => const OnRepeatScreen(),
                    transition: Transition.rightToLeft,
                    preventDuplicates: true,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: AspectRatio(
                aspectRatio: _tileAspectRatio,
                child: _MixTile(
                  icon: Icons.access_time_filled_rounded,
                  title: 'Recent',
                  subtitle: 'History',
                  iconColor: const Color(0xFFC88BFF),
                  onTap: () => Get.to(
                    () => const RecentlyPlayedScreen(),
                    transition: Transition.rightToLeft,
                    preventDuplicates: true,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: AspectRatio(
                aspectRatio: _tileAspectRatio,
                child: _MixTile(
                  icon: Icons.add_rounded,
                  title: 'New Mix',
                  subtitle: 'Create',
                  iconColor: Color(0xFFAFAFAF),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Held back until the fetch lands, so the tile never reads "0 tracks"
  /// when it only means the count is not in yet.
  static String _likedSubtitle(LikedSongsController controller) {
    if (!controller.hasLoaded.value) return 'Your favourites';

    final count = controller.songs.length;
    return count == 1 ? '1 track' : '$count tracks';
  }
}

class _MixTile extends StatelessWidget {
  const _MixTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.iconColor,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color iconColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1F),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.13),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 25),
          ),
          const SizedBox(height: 13),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFFA7A3AA),
              fontSize: 12,
              fontWeight: FontWeight.w500,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
      ),
    );
  }
}

class _ExploreRow extends StatelessWidget {
  const _ExploreRow();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(
          child: _ExploreTile(
            icon: Icons.storefront_rounded,
            label: 'SHOP',
            color: Color(0xFFC777FF),
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: _ExploreTile(
            icon: Icons.mic_rounded,
            label: 'PODCASTS',
            color: Color(0xFF64FF8F),
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: _ExploreTile(
            icon: Icons.menu_book_rounded,
            label: 'AUDIOBOOKS',
            color: Color(0xFF45E6F1),
          ),
        ),
      ],
    );
  }
}

class _ExploreTile extends StatelessWidget {
  const _ExploreTile({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 104,
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1F),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 23),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _NewReleaseHeader extends StatelessWidget {
  const _NewReleaseHeader();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(child: _SectionTitle(title: 'New Releases')),
        _PagerLine(active: true),
        SizedBox(width: 8),
        _PagerLine(active: false),
        SizedBox(width: 8),
        _PagerLine(active: false),
      ],
    );
  }
}

class _PagerLine extends StatelessWidget {
  const _PagerLine({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: active ? 31 : 17,
      height: 2,
      decoration: BoxDecoration(
        color: active ? const Color(0xFF40DDEB) : Colors.white54,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

const _defaultNewReleases = [
  _ReleaseData(
    title: 'Tumi Onek Dami',
    subtitle: 'Fahim Islam - Single',
    artist: 'Fahim Islam',
    meta: 'NEW',
    asset: 'assets/image/Container.png',
    audioAsset: 'audio/music2.mp3',
  ),
  _ReleaseData(
    title: 'Amar Hote Hote Mokhlesul Islam Nilu',
    subtitle: 'Amar Hote Hote - Single',
    artist: 'Mokhlesul Islam Nilu',
    meta: '4:20',
    asset: 'assets/image/Album Art.png',
    audioAsset: 'audio/music3.m4a',
  ),
  _ReleaseData(
    title: 'Emon Ekta Golpo',
    subtitle: 'Nabila - Single',
    artist: 'Nabila',
    meta: '3:15',
    asset: 'assets/image/Album Art (1).png',
    audioAsset: 'audio/music4.mp3',
  ),
];

/// Local demo audio bundled with the app — the `songs/home` API has no
/// audio stream url yet, so playback still cycles through these assets.
const _placeholderAudioAssets = [
  'audio/music1.m4a',
  'audio/music2.mp3',
  'audio/music3.m4a',
  'audio/music4.mp3',
];

String _formatDurationMs(int durationMs) {
  if (durationMs <= 0) return 'NEW';
  final totalSeconds = durationMs ~/ 1000;
  final minutes = totalSeconds ~/ 60;
  final seconds = totalSeconds % 60;
  return '$minutes:${seconds.toString().padLeft(2, '0')}';
}

class _NewReleaseList extends StatelessWidget {
  const _NewReleaseList({required this.items});

  final List<_ReleaseData> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final item in items) ...[
          _ReleaseTile(item: item),
          const SizedBox(height: 14),
        ],
      ],
    );
  }
}

class _ReleaseTile extends StatelessWidget {
  const _ReleaseTile({required this.item});

  final _ReleaseData item;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (item.listenId != null) {
          Get.find<HomeController>().playSong(item.listenId!);
          return;
        }
        Get.find<PlayerController>().play(
          title: item.title,
          artist: item.artist,
          imageAsset: item.asset,
          audioAsset: item.audioAsset,
        );
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PlayerScreen()),
        );
      },
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: SizedBox(
              width: 72,
              height: 72,
              child: _ArtworkBackground(
                asset: item.asset,
                imageUrl: item.coverUrl,
                colors: const [Color(0xFF5AE6D0), Color(0xFF473E96)],
              ),
            ),
          ),
          const SizedBox(width: 22),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  item.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFA7A3AA),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                item.meta,
                style: TextStyle(
                  color: item.meta == 'NEW'
                      ? const Color(0xFF64FF8F)
                      : const Color(0xFF40DDEB),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 10),
              const Icon(
                Icons.more_vert_rounded,
                color: Colors.white70,
                size: 22,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ArtistWatchList extends StatelessWidget {
  const _ArtistWatchList();

  @override
  Widget build(BuildContext context) {
    const artists = [
      _ArtistData(
        name: 'Fahim Islam',
        asset: 'assets/image/Overlay+Shadow.png',
      ),
      _ArtistData(
        name: 'Kazi Shuvo',
        asset: 'assets/image/Overlay+Shadow (1).png',
      ),
      _ArtistData(
        name: 'Tashrif Khan',
        asset: 'assets/image/Overlay+Shadow (2).png',
      ),
      _ArtistData(name: 'Nabila', asset: 'assets/image/Album Art (1).png'),
    ];

    return SizedBox(
      height: 116,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: artists.length,
        separatorBuilder: (_, index) => const SizedBox(width: 26),
        itemBuilder: (context, index) {
          final artist = artists[index];
          return GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ArtistProfileScreen()),
            ),
            child: SizedBox(
              width: 86,
              child: Column(
                children: [
                  Container(
                    width: 74,
                    height: 74,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFFFC400),
                        width: 2,
                      ),
                    ),
                    padding: const EdgeInsets.all(2),
                    child: CircleAvatar(
                      backgroundColor: const Color(0xFF1A1A1D),
                      backgroundImage: AssetImage(artist.asset),
                    ),
                  ),
                  const SizedBox(height: 9),
                  Text(
                    artist.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ArtworkBackground extends StatelessWidget {
  const _ArtworkBackground({
    required this.asset,
    required this.colors,
    this.imageUrl,
  });

  final String asset;
  final List<Color> colors;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: colors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        if (imageUrl != null && imageUrl!.isNotEmpty)
          Image.network(
            imageUrl!,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Image.asset(
              asset,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.music_note_rounded,
                color: Colors.white,
                size: 42,
              ),
            ),
          )
        else
          Image.asset(
            asset,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => const Icon(
              Icons.music_note_rounded,
              color: Colors.white,
              size: 42,
            ),
          ),
      ],
    );
  }
}

class _ReleaseData {
  const _ReleaseData({
    required this.title,
    required this.subtitle,
    required this.artist,
    required this.meta,
    required this.asset,
    required this.audioAsset,
    this.coverUrl,
    this.listenId,
  });

  final String title;
  final String subtitle;
  final String artist;
  final String meta;
  final String asset;
  final String audioAsset;
  final String? coverUrl;
  final String? listenId;
}

class _ArtistData {
  const _ArtistData({required this.name, required this.asset});

  final String name;
  final String asset;
}
