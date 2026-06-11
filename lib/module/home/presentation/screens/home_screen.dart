import 'package:beatx_flutter/module/artist_profile/presentation/screens/artist_profile_screen.dart';
import 'package:beatx_flutter/module/home/presentation/screens/explore_screen.dart';
import 'package:beatx_flutter/module/profile/presentation/screens/my_profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../module/onbording/common/app_logo.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const LinearGradient _pageGlow = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF121833),
      Color(0xFF32185F),
      Color(0xFF071916),
      Color(0xFF0B0B0C),
    ],
    stops: [0, 0.18, 0.34, 0.58],
  );

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: const Color(0xFF202020),
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFF0B0B0C),
        body: Container(
          decoration: const BoxDecoration(gradient: _pageGlow),
          child: SafeArea(
            bottom: false,
            child: CustomScrollView(
              slivers: [
                const SliverToBoxAdapter(child: _HomeHeader()),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                  sliver: SliverList.list(
                    children: const [
                      _SectionTitle(title: 'Trending Now', action: 'See all'),
                      SizedBox(height: 16),
                      _TrendingCard(),
                      SizedBox(height: 36),
                      _SectionTitle(title: 'Your Mix'),
                      SizedBox(height: 16),
                      _DailyDiscoverCard(),
                      SizedBox(height: 16),
                      _MixGrid(),
                      SizedBox(height: 32),
                      _SectionTitle(title: 'Explore More'),
                      SizedBox(height: 16),
                      _ExploreRow(),
                      SizedBox(height: 32),
                      _NewReleaseHeader(),
                      SizedBox(height: 16),
                      _NewReleaseList(),
                      SizedBox(height: 28),
                      _SectionTitle(title: 'Artists to Watch'),
                      SizedBox(height: 14),
                      _ArtistWatchList(),
                      SizedBox(height: 104),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
      child: Row(
        children: [
          const _ProfileAvatar(),
          const SizedBox(width: 12),
          const AppLogo(height: 42, width: 128),
          const Spacer(),
          _CircleAction(
            icon: Icons.search_rounded,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ExploreScreen()),
              );
            },
          ),
          const SizedBox(width: 12),
          _CircleAction(
            icon: Icons.notifications_rounded,
            badge: '3',
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ProfileScreen()),
          );
        },
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
            gradient: const LinearGradient(
              colors: [Color(0xFFD8E9FF), Color(0xFF1B3147)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: const Icon(Icons.person, color: Color(0xFF0F1B28), size: 25),
        ),
      ),
    );
  }
}

class _CircleAction extends StatelessWidget {
  const _CircleAction({required this.icon, required this.onTap, this.badge});

  final IconData icon;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: Colors.white.withValues(alpha: 0.12),
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: SizedBox(
              width: 42,
              height: 42,
              child: Icon(icon, color: Colors.white, size: 24),
            ),
          ),
        ),
        if (badge != null)
          Positioned(
            right: 1,
            top: -2,
            child: Container(
              width: 17,
              height: 17,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: Color(0xFFE93657),
                shape: BoxShape.circle,
              ),
              child: Text(
                badge!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                ),
              ),
            ),
          ),
      ],
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
  const _TrendingCard();

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.03,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Image.asset(
          'assets/image/home_trending.png',
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              const _ArtworkBackground(
                asset: 'assets/image/Container.png',
                colors: [Color(0xFFE7E7E7), Color(0xFF8C8C8C)],
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
    return Container(
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

  @override
  Widget build(BuildContext context) {
    return GridView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 1.23,
      ),
      children: const [
        _MixTile(
          icon: Icons.favorite_rounded,
          title: 'Liked Songs',
          subtitle: '128 tracks',
          iconColor: Color(0xFF4DEBFF),
        ),
        _MixTile(
          icon: Icons.bolt_rounded,
          title: 'On Repeat',
          subtitle: 'Top played',
          iconColor: Color(0xFF6CFF8B),
        ),
        _MixTile(
          icon: Icons.access_time_filled_rounded,
          title: 'Recent',
          subtitle: 'History',
          iconColor: Color(0xFFC88BFF),
        ),
        _MixTile(
          icon: Icons.add_rounded,
          title: 'New Mix',
          subtitle: 'Create',
          iconColor: Color(0xFFAFAFAF),
        ),
      ],
    );
  }
}

class _MixTile extends StatelessWidget {
  const _MixTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.iconColor,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
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

class _NewReleaseList extends StatelessWidget {
  const _NewReleaseList();

  @override
  Widget build(BuildContext context) {
    const items = [
      _ReleaseData(
        title: 'Tumi Onek Dami',
        subtitle: 'Fahim Islam - Single',
        meta: 'NEW',
        asset: 'assets/image/Container.png',
      ),
      _ReleaseData(
        title: 'Amar Hote Hote Mokhlesul Islam Nilu',
        subtitle: 'Amar Hote Hote - Single',
        meta: '4:20',
        asset: 'assets/image/Album Art.png',
      ),
      _ReleaseData(
        title: 'Emon Ekta Golpo',
        subtitle: 'Nabila - Single',
        meta: '3:15',
        asset: 'assets/image/Album Art (1).png',
      ),
    ];

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
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: SizedBox(
            width: 72,
            height: 72,
            child: _ArtworkBackground(
              asset: item.asset,
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
              MaterialPageRoute(
                builder: (_) => const ArtistProfileScreen(),
              ),
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
  const _ArtworkBackground({required this.asset, required this.colors});

  final String asset;
  final List<Color> colors;

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
    required this.meta,
    required this.asset,
  });

  final String title;
  final String subtitle;
  final String meta;
  final String asset;
}

class _ArtistData {
  const _ArtistData({required this.name, required this.asset});

  final String name;
  final String asset;
}
