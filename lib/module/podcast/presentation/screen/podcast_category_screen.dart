import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../../core/common/widget/floating_player.dart';
import '../../../../core/notifiers/snackbar_notifier.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../audiobook/presentation/widget/book_cover.dart';
import '../../controller/podcast_category_controller.dart';
import '../../model/podcast_home_model.dart';
import '../../model/search_category_model.dart';
import 'episode_details_screen.dart';

/// Every show published under one category, headlined by the first one the
/// search returns, with all of their episodes underneath. Reached by tapping a
/// card in the podcast home's Top Categories row.
class PodcastCategoryScreen extends StatelessWidget {
  const PodcastCategoryScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  final String categoryId;
  final String categoryName;

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(
      PodcastCategoryController(categoryId: categoryId),
      tag: categoryId,
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: const Color(0xFF080909),
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFF080909),
        bottomNavigationBar: const FloatingPlayer(),
        body: Stack(
          children: [
            const _CategoryGlow(),
            SafeArea(
              bottom: false,
              child: Column(
                children: [
                  _CategoryHeader(title: categoryName),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: controller.fetchCategory,
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

  Widget _buildBody(
    BuildContext context,
    PodcastCategoryController controller,
  ) {
    if (controller.isLoading.value) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: CircularProgressIndicator(color: Color(0xFF40DDEB)),
        ),
      );
    }

    if (controller.errorMessage.isNotEmpty && controller.podcasts.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: _CategoryMessage(
          message: controller.errorMessage.value,
          onRetry: controller.fetchCategory,
        ),
      );
    }

    final headline = controller.headline;
    if (headline == null) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: _CategoryMessage(message: 'No podcasts in this category yet.'),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.screenHorizontalPadding,
        6,
        AppSizes.screenHorizontalPadding,
        28,
      ),
      sliver: SliverList.list(
        children: [
          _HeadlineCard(
            podcast: headline,
            categoryName: categoryName,
            isLoading: controller.isStreamLoading,
            onListenNow: () => _play(context, controller, headline),
          ),
          const SizedBox(height: 26),
          if (controller.otherPodcasts.isNotEmpty) ...[
            _SectionHeader(
              title: 'More in $categoryName',
              actionLabel: controller.canExpandPodcasts
                  ? (controller.showAllPodcasts.value
                        ? 'Show less'
                        : 'View all')
                  : null,
              onAction: controller.toggleShowAllPodcasts,
            ),
            const SizedBox(height: 14),
            _PodcastGrid(podcasts: controller.visiblePodcasts),
            const SizedBox(height: 28),
          ],
          const _SectionHeader(title: 'Top Episodes'),
          const SizedBox(height: 14),
          if (controller.isLoadingEpisodes.value && controller.episodes.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: CircularProgressIndicator(color: Color(0xFF40DDEB)),
              ),
            )
          else if (controller.episodes.isEmpty)
            const _CategoryMessage(message: 'No episodes in this category yet.')
          else
            for (final episode in controller.episodes) ...[
              _CategoryEpisodeTile(
                episode: episode,
                isLoading: controller.loadingEpisodeId.value == episode.id,
                onTap: () =>
                    Get.to(() => EpisodeDetailsScreen(episode: episode)),
                onPlay: () => _playEpisode(context, controller, episode),
              ),
              const SizedBox(height: 12),
            ],
        ],
      ),
    );
  }

  Future<void> _play(
    BuildContext context,
    PodcastCategoryController controller,
    CategoryPodcast podcast,
  ) async {
    await controller.playPodcast(podcast);
    if (context.mounted && controller.errorMessage.value.isNotEmpty) {
      SnackbarNotifier(
        context: context,
      ).notifyError(message: controller.errorMessage.value);
    }
  }

  Future<void> _playEpisode(
    BuildContext context,
    PodcastCategoryController controller,
    RecentEpisode episode,
  ) async {
    await controller.playEpisode(episode);
    if (context.mounted && controller.errorMessage.value.isNotEmpty) {
      SnackbarNotifier(
        context: context,
      ).notifyError(message: controller.errorMessage.value);
    }
  }
}

// ─── Header ───────────────────────────────────────────────────────────────

class _CategoryHeader extends StatelessWidget {
  const _CategoryHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.screenHorizontalPadding,
        10,
        AppSizes.screenHorizontalPadding,
        6,
      ),
      child: Row(
        children: [
          _CircleIconButton(
            icon: Icons.arrow_back_rounded,
            onTap: () => Navigator.maybePop(context),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF40DDEB),
                fontSize: 19,
                fontWeight: FontWeight.w800,
                letterSpacing: 0,
              ),
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.icon, required this.onTap});

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
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}

class _CategoryGlow extends StatelessWidget {
  const _CategoryGlow();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: -120,
      left: -30,
      right: -30,
      child: Container(
        height: 320,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(200),
          gradient: RadialGradient(
            colors: [
              const Color(0xFF2C6BE0).withValues(alpha: 0.75),
              const Color(0xFF5125B8).withValues(alpha: 0.45),
              Colors.transparent,
            ],
            stops: const [0, 0.5, 1],
          ),
        ),
      ),
    );
  }
}

// ─── Headline card ────────────────────────────────────────────────────────

class _HeadlineCard extends StatelessWidget {
  const _HeadlineCard({
    required this.podcast,
    required this.categoryName,
    required this.isLoading,
    required this.onListenNow,
  });

  final CategoryPodcast podcast;
  final String categoryName;
  final bool isLoading;
  final VoidCallback onListenNow;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: SizedBox(
        height: 330,
        child: Stack(
          fit: StackFit.expand,
          children: [
            BookCover(
              url: podcast.coverUrl ?? '',
              placeholderIcon: Icons.mic_rounded,
              iconSize: 64,
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.15),
                    Colors.black.withValues(alpha: 0.62),
                    Colors.black.withValues(alpha: 0.92),
                  ],
                  stops: const [0, 0.5, 1],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _CategoryChip(label: categoryName),
                  const SizedBox(height: 12),
                  Text(
                    podcast.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 27,
                      height: 1.14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0,
                    ),
                  ),
                  if (podcast.description.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      podcast.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFFC7C3CC),
                        fontSize: 13,
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      SizedBox(
                        height: 48,
                        child: FilledButton.icon(
                          onPressed: isLoading ? null : onListenNow,
                          icon: isLoading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.2,
                                    color: Color(0xFF111315),
                                  ),
                                )
                              : const Icon(Icons.play_arrow_rounded, size: 24),
                          label: const Text('LISTEN NOW'),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF40DDEB),
                            foregroundColor: const Color(0xFF111315),
                            disabledBackgroundColor: const Color(
                              0xFF40DDEB,
                            ).withValues(alpha: 0.6),
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            textStyle: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.4,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(26),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const _OutlineIconButton(icon: Icons.add_rounded),
                    ],
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

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    if (label.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF40DDEB).withValues(alpha: 0.5),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF40DDEB),
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class _OutlineIconButton extends StatelessWidget {
  const _OutlineIconButton({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.35),
      shape: const CircleBorder(side: BorderSide(color: Colors.white24)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () {},
        child: SizedBox(
          width: 48,
          height: 48,
          child: Icon(icon, color: Colors.white, size: 24),
        ),
      ),
    );
  }
}

// ─── Show cards ───────────────────────────────────────────────────────────

class _PodcastGrid extends StatelessWidget {
  const _PodcastGrid({required this.podcasts});

  final List<CategoryPodcast> podcasts;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 14.0;
        final cardWidth = (constraints.maxWidth - spacing) / 2;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final podcast in podcasts)
              SizedBox(
                width: cardWidth,
                child: _PodcastCard(podcast: podcast),
              ),
          ],
        );
      },
    );
  }
}

class _PodcastCard extends StatelessWidget {
  const _PodcastCard({required this.podcast});

  final CategoryPodcast podcast;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF111112),
        borderRadius: BorderRadius.circular(18),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1.35,
            child: BookCover(
              url: podcast.coverUrl ?? '',
              placeholderIcon: Icons.mic_rounded,
              iconSize: 34,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  podcast.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  podcast.episodeCountLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF9C98A1),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Episodes ─────────────────────────────────────────────────────────────

class _CategoryEpisodeTile extends StatelessWidget {
  const _CategoryEpisodeTile({
    required this.episode,
    required this.isLoading,
    required this.onTap,
    required this.onPlay,
  });

  final RecentEpisode episode;
  final bool isLoading;
  final VoidCallback onTap;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    final meta = [
      episode.formattedDuration,
      episode.podcastId.title,
    ].where((e) => e.isNotEmpty).join(' • ');

    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        height: 84,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFF111112),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 64,
                height: 64,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    BookCover(
                      url: episode.coverUrl ?? episode.podcastId.coverUrl ?? '',
                      placeholderIcon: Icons.mic_rounded,
                      iconSize: 26,
                    ),
                    Material(
                      color: Colors.black.withValues(alpha: 0.3),
                      child: InkWell(
                        onTap: isLoading ? null : onPlay,
                        child: Center(
                          child: isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Color(0xFF40DDEB),
                                  ),
                                )
                              : const Icon(
                                  Icons.play_arrow_rounded,
                                  color: Color(0xFF40DDEB),
                                  size: 28,
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    episode.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    meta,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF9C98A1),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () {},
              icon: const Icon(
                Icons.more_horiz_rounded,
                color: Color(0xFF6E6A72),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Shared bits ──────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.actionLabel, this.onAction});

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
        ),
        if (actionLabel != null)
          GestureDetector(
            onTap: onAction,
            child: Text(
              actionLabel!,
              style: const TextStyle(
                color: Color(0xFF40DDEB),
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
              ),
            ),
          ),
      ],
    );
  }
}

class _CategoryMessage extends StatelessWidget {
  const _CategoryMessage({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF77727A),
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 0,
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 14),
            TextButton(
              onPressed: onRetry,
              child: const Text(
                'Try again',
                style: TextStyle(
                  color: Color(0xFF40DDEB),
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
