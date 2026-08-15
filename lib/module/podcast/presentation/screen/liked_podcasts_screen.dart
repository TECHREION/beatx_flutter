import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/common/widget/liked_collection.dart';
import '../../controller/liked_podcasts_controller.dart';
import '../../controller/podcast_like_controller.dart';
import '../../model/podcast_details_model.dart';

/// Every podcast the user has liked, over `GET /podcasts/liked`.
///
/// Same layout as the liked songs screen — both are built from the shared
/// chrome in `liked_collection.dart` — with the podcast tab's accent.
class LikedPodcastsScreen extends StatelessWidget {
  const LikedPodcastsScreen({super.key});

  static const accent = Color(0xFFBD89FF);

  static const _artGradient = [Color(0xFF7B3BFF), Color(0xFF4D314F)];

  @override
  Widget build(BuildContext context) {
    final ctrl = LikedPodcastsController.instance;

    return Scaffold(
      backgroundColor: LikedPalette.background,
      body: SafeArea(
        child: Column(
          children: [
            const LikedHeader(
              title: 'Liked Podcasts',
              subtitle: 'Your favorite podcasts, all in one place',
            ),
            const SizedBox(height: 18),
            Obx(
              () => LikedSummaryStrip(
                icon: Icons.headphones_rounded,
                accent: accent,
                count: ctrl.hasLoaded.value ? ctrl.podcasts.length : null,
                noun: 'Liked Podcast',
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: RefreshIndicator(
                onRefresh: ctrl.fetch,
                color: accent,
                backgroundColor: LikedPalette.card,
                child: CustomScrollView(
                  // Keeps pull-to-refresh reachable while the list is empty
                  // or short.
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    Obx(() {
                      if (ctrl.isLoading.value && ctrl.podcasts.isEmpty) {
                        return const SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(
                            child: CircularProgressIndicator(color: accent),
                          ),
                        );
                      }

                      if (ctrl.podcasts.isEmpty) {
                        return SliverFillRemaining(
                          hasScrollBody: false,
                          child: LikedEmptyState(
                            message: ctrl.errorMessage.value,
                            emptyTitle: 'No liked podcasts yet',
                            emptyBody:
                                'Tap the heart while an episode is playing '
                                'and its podcast will show up here.',
                            accent: accent,
                            onRetry: ctrl.fetch,
                          ),
                        );
                      }

                      return SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                        sliver: SliverList.separated(
                          itemCount: ctrl.podcasts.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 12),
                          itemBuilder: (_, index) => _PodcastRow(
                            podcast: ctrl.podcasts[index],
                            position: index + 1,
                            controller: ctrl,
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PodcastRow extends StatelessWidget {
  const _PodcastRow({
    required this.podcast,
    required this.position,
    required this.controller,
  });

  final Podcast podcast;
  final int position;
  final LikedPodcastsController controller;

  @override
  Widget build(BuildContext context) {
    final episodes = podcast.totalEpisodes;

    return Obx(() {
      // Both reads are reactive, so the row lights up when an episode of this
      // podcast starts playing and while its unlike is in flight.
      final playing =
          PodcastLikeController.instance.podcastId.value == podcast.id;
      final busy = controller.unliking.contains(podcast.id);

      return LikedRowCard(
        position: position,
        playing: playing,
        accent: LikedPodcastsScreen.accent,
        coverUrl: podcast.coverUrl ?? '',
        fallbackIcon: Icons.podcasts_rounded,
        gradient: LikedPodcastsScreen._artGradient,
        title: podcast.title,
        subtitle: episodes == 1 ? '1 episode' : '$episodes episodes',
        tag: podcast.genre.name,
        busy: busy,
        onUnlike: () => controller.unlike(podcast),
        onMore: () => LikedActionsSheet.show(
          context,
          title: podcast.title,
          actions: [
            LikedAction(
              icon: Icons.heart_broken_rounded,
              label: 'Remove from Liked',
              onTap: () => controller.unlike(podcast),
            ),
          ],
        ),
      );
    });
  }
}
