import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/common/widget/app_header.dart';
import '../../../../core/common/background_image.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../controller/watch_controller.dart';
import '../../model/watch_model.dart';
import 'video_screen.dart';
import 'video_search_screen.dart';

String _formatDuration(int durationMs) {
  final totalSeconds = (durationMs / 1000).round();
  final minutes = totalSeconds ~/ 60;
  final seconds = totalSeconds % 60;
  return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
}

class WatchScreen extends StatelessWidget {
  const WatchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(WatchController());

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackgroundImage(
        child: SafeArea(
          child: Column(
            children: [
              AppHeader(
                title: 'Watch',
                notificationBadge: '3',
                onSearchTap: () => Get.to(
                  () => VideoSearchScreen(),
                  transition: Transition.rightToLeft,
                  preventDuplicates: true,
                ),
              ),
              Expanded(
                child: Obx(() {
                  if (controller.isLoading.value && controller.home.value == null) {
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    );
                  }

                  if (controller.errorMessage.value.isNotEmpty &&
                      controller.home.value == null) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          controller.errorMessage.value,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ),
                    );
                  }

                  return CustomScrollView(
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSizes.screenHorizontalPadding,
                          16,
                          AppSizes.screenHorizontalPadding,
                          26,
                        ),
                        sliver: SliverList.list(
                          children: [
                            const SizedBox(height: 22),
                            if (controller.featuredVideo != null)
                              _HeroVideo(video: controller.featuredVideo!),
                            const SizedBox(height: 24),
                            const _TrendingHeader(),
                            const SizedBox(height: 8),
                            Column(
                              children: [
                                for (final entry
                                    in controller.trendingVideos.indexed) ...[
                                  _VideoTile(
                                    video: entry.$2,
                                    onTap: () => Get.to(
                                      () => MusicPlayerScreen(
                                        videoId: entry.$2.id,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                ],
                              ],
                            ),
                            const SizedBox(height: 74),
                          ],
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroVideo extends StatelessWidget {
  const _HeroVideo({required this.video});

  final VideoModel video;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 5,
                height: 5,
                decoration: const BoxDecoration(
                  color: Color(0xFFBD89FF),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                video.genre.name.toUpperCase(),
                style: const TextStyle(
                  color: Color(0xFFBD89FF),
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(
          video.title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 30,
            height: 0.98,
            fontWeight: FontWeight.w500,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          video.description,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Color(0xFFB7B2BC),
            fontSize: 11,
            height: 1.35,
            fontWeight: FontWeight.w500,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            SizedBox(
              height: 43,
              child: FilledButton.icon(
                onPressed: () => Get.to(
                  () => MusicPlayerScreen(videoId: video.id),
                ),
                icon: const Icon(Icons.play_arrow_rounded, size: 23),
                label: const Text('WATCH NOW'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF40DDEB),
                  foregroundColor: const Color(0xFF111315),
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  textStyle: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              height: 43,
              child: OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add_rounded, size: 20),
                label: const Text('MY LIST'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.48)),
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  textStyle: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _TrendingHeader extends StatelessWidget {
  const _TrendingHeader();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Trending Music',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                ),
              ),
            ),
            Text(
              'View All',
              style: TextStyle(
                color: Color(0xFF9BFF4D),
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
        SizedBox(height: 3),
        Text(
          'The most watched visuals across the prism this week.',
          style: TextStyle(
            color: Color(0xFF9C98A1),
            fontSize: 9,
            fontWeight: FontWeight.w600,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}

class _VideoTile extends StatelessWidget {
  const _VideoTile({required this.video, this.onTap});

  final VideoModel video;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1.83,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    video.coverUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const ColoredBox(
                          color: Color(0xFF202020),
                          child: Icon(
                            Icons.play_circle_fill_rounded,
                            color: Colors.white38,
                            size: 50,
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
                          Colors.black.withValues(alpha: 0.45),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    right: 6,
                    bottom: 5,
                    child: Text(
                      _formatDuration(video.durationMs),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            video.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${video.ownerId.name} - ${video.playCount} plays',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF9C98A1),
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}
