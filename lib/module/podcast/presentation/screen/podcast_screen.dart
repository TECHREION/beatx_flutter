import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../controller/podcast_controller.dart';
import '../widget/category_card.dart';
import '../widget/episode_tile.dart';
import '../widget/featured_podcast_card.dart';
import '../widget/podcaster_card.dart';

class PodcastScreen extends StatelessWidget {
  const PodcastScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(PodcastController());

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: const Color(0xFF202020),
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFF080909),
        body: Stack(
          children: [
            const _PodcastGlow(),
            SafeArea(
              bottom: false,
              child: CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
                    sliver: SliverList.list(
                      children: [
                        const _PodcastHeader(),
                        const SizedBox(height: 28),
                        const Text(
                          'CURATION',
                          style: TextStyle(
                            color: Color(0xFF9BFF4D),
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Featured Voices',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0,
                                ),
                              ),
                            ),
                            _RoundArrowButton(
                              icon: Icons.chevron_left_rounded,
                              onTap: controller.showPreviousFeatured,
                            ),
                            const SizedBox(width: 12),
                            _RoundArrowButton(
                              icon: Icons.chevron_right_rounded,
                              onTap: controller.showNextFeatured,
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Obx(
                          () => FeaturedPodcastCard(
                            podcast: controller.featuredPodcast,
                          ),
                        ),
                        const SizedBox(height: 26),
                        const _SectionTitle(title: 'Top Categories'),
                        const SizedBox(height: 14),
                        for (final category in controller.categories) ...[
                          CategoryCard(category: category),
                          const SizedBox(height: 15),
                        ],
                        const SizedBox(height: 8),
                        const _SectionTitle(title: 'Top Podcasters'),
                        const SizedBox(height: 16),
                        PodcasterCard(podcasters: controller.podcasters),
                        const SizedBox(height: 28),
                        const _RecentHeader(),
                        const SizedBox(height: 14),
                        for (final episode in controller.episodes) ...[
                          EpisodeTile(episode: episode),
                          const SizedBox(height: 12),
                        ],
                        const SizedBox(height: 28),
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

class _PodcastGlow extends StatelessWidget {
  const _PodcastGlow();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: -74,
      left: 52,
      right: -40,
      child: Container(
        height: 310,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(160),
          gradient: RadialGradient(
            colors: [
              const Color(0xFFB334D7).withValues(alpha: 0.96),
              const Color(0xFF5125B8).withValues(alpha: 0.64),
              const Color(0xFF0C1515).withValues(alpha: 0.12),
              Colors.transparent,
            ],
            stops: const [0, 0.38, 0.74, 1],
          ),
        ),
      ),
    );
  }
}

class _PodcastHeader extends StatelessWidget {
  const _PodcastHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ClipOval(
          child: Image.asset(
            'assets/image/a1.png',
            width: 42,
            height: 42,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(width: 12),
        const Text(
          'Podcasts',
          style: TextStyle(
            color: Color(0xFF40DDEB),
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
        ),
        const Spacer(),
        const _HeaderIcon(icon: Icons.search_rounded),
        SizedBox(width: 12),
        _HeaderIcon(icon: Icons.notifications_rounded, badge: '3'),
      ],
    );
  }
}

class _HeaderIcon extends StatelessWidget {
  const _HeaderIcon({required this.icon, this.badge});

  final IconData icon;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.13),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 23),
        ),
        if (badge != null)
          Positioned(
            right: 1,
            top: -3,
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
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _RoundArrowButton extends StatelessWidget {
  const _RoundArrowButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.14),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, color: Colors.white, size: 25),
        ),
      ),
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

class _RecentHeader extends StatelessWidget {
  const _RecentHeader();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(child: _SectionTitle(title: 'Recent Episodes')),
        Text(
          'See all activity',
          style: TextStyle(
            color: Color(0xFFBD89FF),
            fontSize: 13,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}
