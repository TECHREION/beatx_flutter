import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controller/liked_podcasts_controller.dart';
import '../../controller/podcast_like_controller.dart';
import '../../model/podcast_details_model.dart';

/// Every podcast the user has liked, over `GET /podcasts/liked`.
class LikedPodcastsScreen extends StatelessWidget {
  const LikedPodcastsScreen({super.key});

  static const _background = Color(0xFF080909);
  static const _accent = Color(0xFFBD89FF);
  static const _muted = Color(0xFFAAA5AD);

  static const _artGradient = [Color(0xFF7B3BFF), Color(0xFF4D314F)];

  @override
  Widget build(BuildContext context) {
    final ctrl = LikedPodcastsController.instance;

    return Scaffold(
      backgroundColor: _background,
      body: RefreshIndicator(
        onRefresh: ctrl.fetch,
        color: _accent,
        backgroundColor: const Color(0xFF1B1B1D),
        child: CustomScrollView(
          // Keeps pull-to-refresh reachable while the grid is empty or short.
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            _Header(controller: ctrl),
            Obx(() {
              if (ctrl.isLoading.value && ctrl.podcasts.isEmpty) {
                return const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Padding(
                    padding: EdgeInsets.only(top: 60),
                    child: Center(
                      child: CircularProgressIndicator(color: _accent),
                    ),
                  ),
                );
              }

              if (ctrl.podcasts.isEmpty) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: _EmptyState(
                    message: ctrl.errorMessage.value,
                    onRetry: ctrl.fetch,
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
                sliver: SliverList.separated(
                  itemCount: ctrl.podcasts.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 6),
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
    );
  }
}

/// Collapsing header: cover mosaic over a wash of colour.
class _Header extends StatelessWidget {
  const _Header({required this.controller});

  final LikedPodcastsController controller;

  static const _expandedHeight = 380.0;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      expandedHeight: _expandedHeight,
      backgroundColor: LikedPodcastsScreen._background,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        onPressed: () => Navigator.maybePop(context),
        icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
      ),
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          final collapsedHeight =
              kToolbarHeight + MediaQuery.of(context).padding.top;
          // 1 while fully expanded, 0 once pinned — drives the crossfade
          // between the big header and the compact bar title.
          final expansion =
              ((constraints.maxHeight - collapsedHeight) /
                      (_expandedHeight - collapsedHeight))
                  .clamp(0.0, 1.0);

          return Stack(
            fit: StackFit.expand,
            children: [
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF2C1A4A),
                      LikedPodcastsScreen._background,
                    ],
                  ),
                ),
              ),
              // Laid out from the bottom and left unconstrained in height, so
              // a collapsing bar slides it out of frame instead of
              // overflowing it.
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: Opacity(
                  opacity: expansion,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Obx(
                        () => _CoverMosaic(covers: controller.mosaicCovers),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Liked Podcasts',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Obx(
                        () => Text(
                          _subtitle(controller),
                          style: const TextStyle(
                            color: LikedPodcastsScreen._muted,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: MediaQuery.of(context).padding.top,
                left: 0,
                right: 0,
                height: kToolbarHeight,
                child: Opacity(
                  opacity: 1 - expansion,
                  child: const Center(
                    child: Text(
                      'Liked Podcasts',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  static String _subtitle(LikedPodcastsController controller) {
    if (!controller.hasLoaded.value) return 'Your favourites';

    final count = controller.podcasts.length;
    return count == 1 ? '1 podcast' : '$count podcasts';
  }
}

/// Up to four covers in a square, falling back to a heart while there is
/// nothing to show.
class _CoverMosaic extends StatelessWidget {
  const _CoverMosaic({required this.covers});

  /// At most four, already stripped of podcasts that have no cover.
  final List<String> covers;

  static const _size = 160.0;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _size,
      height: _size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: LikedPodcastsScreen._artGradient,
        ),
        boxShadow: [
          BoxShadow(
            color: LikedPodcastsScreen._artGradient.first.withValues(
              alpha: 0.35,
            ),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: covers.length < 4
            ? _single()
            : GridView.count(
                crossAxisCount: 2,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  for (final url in covers) _Cover(url: url, size: _size / 2),
                ],
              ),
      ),
    );
  }

  Widget _single() {
    if (covers.isEmpty) {
      return const Center(
        child: Icon(Icons.favorite_rounded, color: Colors.white, size: 62),
      );
    }
    return _Cover(url: covers.first, size: _size);
  }
}

class _Cover extends StatelessWidget {
  const _Cover({required this.url, required this.size});

  final String url;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.network(
      url,
      width: size,
      height: size,
      fit: BoxFit.cover,
      // A missing cover should leave the gradient behind it showing rather
      // than punch a grey hole in the grid.
      errorBuilder: (_, _, _) => const SizedBox.shrink(),
      loadingBuilder: (context, child, progress) =>
          progress == null ? child : const SizedBox.shrink(),
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
    final cover = podcast.coverUrl ?? '';

    return Obx(() {
      // Reactive, so the row lights up when an episode of this podcast
      // starts playing and dims again when the player moves on.
      final playing =
          PodcastLikeController.instance.podcastId.value == podcast.id;

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: playing
              ? LikedPodcastsScreen._accent.withValues(alpha: 0.10)
              : Colors.transparent,
        ),
        child: Row(
          children: [
            SizedBox(
              width: 22,
              child: playing
                  ? const Icon(
                      Icons.equalizer_rounded,
                      color: LikedPodcastsScreen._accent,
                      size: 18,
                    )
                  : Text(
                      '$position',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: LikedPodcastsScreen._muted,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
            const SizedBox(width: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 52,
                height: 52,
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: LikedPodcastsScreen._artGradient,
                    ),
                  ),
                  child: cover.isEmpty
                      ? const Icon(
                          Icons.podcasts_rounded,
                          color: Colors.white,
                          size: 24,
                        )
                      : _Cover(url: cover, size: 52),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    podcast.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: playing
                          ? LikedPodcastsScreen._accent
                          : Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    _caption(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: LikedPodcastsScreen._muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _UnlikeButton(podcast: podcast, controller: controller),
          ],
        ),
      );
    });
  }

  /// Episode count, plus the owner when the payload carried one.
  String _caption() {
    final episodes = podcast.totalEpisodes;
    final parts = [
      episodes == 1 ? '1 episode' : '$episodes episodes',
      if (podcast.ownerId.name.isNotEmpty) podcast.ownerId.name,
    ];
    return parts.join('  •  ');
  }
}

class _UnlikeButton extends StatelessWidget {
  const _UnlikeButton({required this.podcast, required this.controller});

  final Podcast podcast;
  final LikedPodcastsController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final busy = controller.unliking.contains(podcast.id);

      return GestureDetector(
        onTap: busy ? null : () => controller.unlike(podcast),
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: 44,
          height: 44,
          child: busy
              ? const Center(
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: LikedPodcastsScreen._muted,
                    ),
                  ),
                )
              : const Icon(
                  Icons.favorite_rounded,
                  color: Color(0xFFFF4D6D),
                  size: 22,
                ),
        ),
      );
    });
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message, required this.onRetry});

  /// The failure that left the list empty, or empty when it is simply empty.
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final failed = message.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 50, 32, 32),
      child: Column(
        children: [
          Icon(
            failed ? Icons.cloud_off_rounded : Icons.favorite_border_rounded,
            color: Colors.white24,
            size: 58,
          ),
          const SizedBox(height: 18),
          Text(
            failed ? 'Could not load your likes' : 'No liked podcasts yet',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            failed
                ? message
                : 'Tap the heart while an episode is playing and its podcast '
                      'will show up here.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: LikedPodcastsScreen._muted,
              fontSize: 13,
              height: 1.45,
            ),
          ),
          if (failed) ...[
            const SizedBox(height: 22),
            GestureDetector(
              onTap: onRetry,
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 26,
                  vertical: 13,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  color: LikedPodcastsScreen._accent,
                ),
                child: const Text(
                  'Try again',
                  style: TextStyle(
                    color: Color(0xFF1B0B2E),
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
