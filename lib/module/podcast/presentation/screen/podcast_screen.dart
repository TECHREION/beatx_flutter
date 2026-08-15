import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../../../core/common/widget/app_header.dart';
import '../../../../../core/notifiers/snackbar_notifier.dart';
import '../../../../../core/theme/app_sizes.dart';
import '../../controller/podcast_controller.dart';
import '../../model/podcast_home_model.dart';
import '../widget/category_card.dart';
import '../widget/episode_tile.dart';
import '../widget/featured_podcast_card.dart';
import '../widget/podcaster_card.dart';
import 'episode_details_screen.dart';
import 'podcast_category_screen.dart';

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
              child: Column(
                children: [
                  const AppHeader(title: 'Podcasts', notificationBadge: '3'),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: controller.fetchHome,
                      backgroundColor: const Color(0xFF202020),
                      color: const Color(0xFF40DDEB),
                      child: Obx(
                        () => CustomScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          slivers: [_buildBody(context, controller)],
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
    );
  }
}

Widget _buildBody(BuildContext context, PodcastController controller) {
  if (controller.isLoading.value) {
    return const SliverFillRemaining(
      hasScrollBody: false,
      child: Center(child: CircularProgressIndicator(color: Color(0xFF40DDEB))),
    );
  }

  if (controller.errorMessage.isNotEmpty && controller.home.value == null) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: _PodcastMessage(
        message: controller.errorMessage.value,
        onRetry: controller.fetchHome,
      ),
    );
  }

  if (controller.home.value == null) {
    return const SliverFillRemaining(
      hasScrollBody: false,
      child: _PodcastMessage(message: 'No podcasts available yet.'),
    );
  }

  return _buildContent(context, controller);
}

Widget _buildContent(BuildContext context, PodcastController controller) {
  final featuredPodcast = controller.featuredPodcast;
  final categories = controller.categories;
  final podcasters = controller.podcasters;
  final episodes = controller.episodes;

  return SliverPadding(
    padding: const EdgeInsets.fromLTRB(
      AppSizes.screenHorizontalPadding,
      18,
      AppSizes.screenHorizontalPadding,
      0,
    ),
    sliver: SliverList.list(
      children: [
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
            if (controller.featured.length > 1) ...[
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
          ],
        ),
        const SizedBox(height: 24),
        if (featuredPodcast == null)
          const _EmptySection(message: 'No featured podcasts yet.')
        else
          FeaturedPodcastCard(
            podcast: featuredPodcast,
            isLoading: controller.isStreamLoading,
            onListenNow: () =>
                _playFeatured(context, controller, featuredPodcast),
          ),
        const SizedBox(height: 26),
        const _SectionTitle(title: 'Top Categories'),
        const SizedBox(height: 14),
        if (categories.isEmpty)
          const _EmptySection(message: 'No categories yet.')
        else
          for (final category in categories) ...[
            CategoryCard(
              category: category,
              onTap: () => Get.to(
                () => PodcastCategoryScreen(
                  categoryId: category.genreId,
                  categoryName: category.name,
                ),
              ),
            ),
            const SizedBox(height: 15),
          ],
        const SizedBox(height: 8),
        const _SectionTitle(title: 'Top Podcasters'),
        const SizedBox(height: 16),
        if (podcasters.isEmpty)
          const _EmptySection(message: 'No podcasters yet.')
        else
          PodcasterCard(podcasters: podcasters),
        const SizedBox(height: 28),
        const _RecentHeader(),
        const SizedBox(height: 14),
        if (episodes.isEmpty)
          const _EmptySection(message: 'No recent episodes yet.')
        else
          for (final episode in episodes) ...[
            EpisodeTile(
              episode: episode,
              onTap: () => Get.to(() => EpisodeDetailsScreen(episode: episode)),
            ),
            const SizedBox(height: 12),
          ],
        const SizedBox(height: 28),
      ],
    ),
  );
}

Future<void> _playFeatured(
  BuildContext context,
  PodcastController controller,
  FeaturedPodcast podcast,
) async {
  await controller.playFeatured(podcast);
  if (context.mounted && controller.errorMessage.value.isNotEmpty) {
    SnackbarNotifier(
      context: context,
    ).notifyError(message: controller.errorMessage.value);
  }
}

class _PodcastMessage extends StatelessWidget {
  const _PodcastMessage({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFFAAA5AD),
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: 0,
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 18),
            FilledButton(
              onPressed: onRetry,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF40DDEB),
                foregroundColor: const Color(0xFF111315),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(26),
                ),
              ),
              child: const Text('Retry'),
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptySection extends StatelessWidget {
  const _EmptySection({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Text(
        message,
        style: const TextStyle(
          color: Color(0xFF77727A),
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
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
