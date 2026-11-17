import 'package:flutter/material.dart';
import 'package:beatx_flutter/core/common/widget/mini_player_host.dart';
import 'package:get/get.dart';

import '../../../../core/common/widget/liked_collection.dart';
import '../../controller/liked_videos_controller.dart';
import '../../model/watch_model.dart';
import 'video_screen.dart';

/// Every video the user has liked, over `GET /videos/liked`.
///
/// Same layout as the other liked screens — built from the shared chrome in
/// `liked_collection.dart` — with the Watch tab's accent.
class LikedVideosScreen extends StatefulWidget {
  const LikedVideosScreen({super.key});

  static const accent = Color(0xFF40DDEB);

  static const _artGradient = [Color(0xFF7B3BFF), Color(0xFF40DDEB)];

  @override
  State<LikedVideosScreen> createState() => _LikedVideosScreenState();
}

class _LikedVideosScreenState extends State<LikedVideosScreen> {
  final ctrl = LikedVideosController.instance;

  static const accent = LikedVideosScreen.accent;

  @override
  void initState() {
    super.initState();
    // Asked for on every open, so a first fetch that failed is retried here.
    // A fetch already running is joined.
    ctrl.fetch();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LikedPalette.background,
      body: SafeArea(
        child: Column(
          children: [
            const LikedHeader(
              title: 'Liked Videos',
              subtitle: 'Your favorite videos, all in one place',
            ),
            const SizedBox(height: 18),
            Obx(
              () => LikedSummaryStrip(
                icon: Icons.smart_display_rounded,
                accent: accent,
                count: ctrl.hasLoaded.value ? ctrl.videos.length : null,
                noun: 'Liked Video',
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: RefreshIndicator(
                onRefresh: ctrl.fetch,
                color: accent,
                backgroundColor: LikedPalette.card,
                child: CustomScrollView(
                  // Keeps pull-to-refresh reachable while the list is short.
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    Obx(() {
                      if (ctrl.isLoading.value && ctrl.videos.isEmpty) {
                        return const SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(
                            child: CircularProgressIndicator(color: accent),
                          ),
                        );
                      }

                      if (ctrl.videos.isEmpty) {
                        return SliverFillRemaining(
                          hasScrollBody: false,
                          child: LikedEmptyState(
                            message: ctrl.errorMessage.value,
                            emptyTitle: 'No liked videos yet',
                            emptyBody:
                                'Tap the heart under a video and it will show '
                                'up here.',
                            accent: accent,
                            emptyIcon: Icons.video_library_outlined,
                            onRetry: ctrl.fetch,
                          ),
                        );
                      }

                      return SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                        sliver: SliverList.separated(
                          itemCount: ctrl.videos.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 12),
                          itemBuilder: (_, index) => _VideoRow(
                            video: ctrl.videos[index],
                            position: index + 1,
                            controller: ctrl,
                          ),
                        ),
                      );
                    }),
                    // Room to scroll the last items clear of the mini player.
                    const SliverMiniPlayerSpacer(),
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

class _VideoRow extends StatelessWidget {
  const _VideoRow({
    required this.video,
    required this.position,
    required this.controller,
  });

  final VideoModel video;
  final int position;
  final LikedVideosController controller;

  static String _duration(int ms) {
    if (ms <= 0) return '';
    final d = Duration(milliseconds: ms);
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (d.inHours > 0) {
      final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
      return '${d.inHours}:$m:$s';
    }
    return '${d.inMinutes}:$s';
  }

  void _watch() => MusicPlayerScreen.open(video.id);

  @override
  Widget build(BuildContext context) {
    final duration = _duration(video.durationMs);
    final channel = video.ownerId.name;

    return Obx(() {
      final busy = controller.unliking.contains(video.id);

      return LikedRowCard(
        position: position,
        playing: false,
        accent: LikedVideosScreen.accent,
        coverUrl: video.coverUrl,
        fallbackIcon: Icons.smart_display_rounded,
        gradient: LikedVideosScreen._artGradient,
        title: video.title,
        subtitle: [
          if (channel.isNotEmpty) channel,
          if (duration.isNotEmpty) duration,
        ].join('  •  '),
        tag: video.genre.name,
        busy: busy,
        onTap: _watch,
        onUnlike: () => controller.unlike(video),
        onMore: () => LikedActionsSheet.show(
          context,
          title: video.title,
          actions: [
            LikedAction(
              icon: Icons.play_arrow_rounded,
              label: 'Watch',
              onTap: _watch,
            ),
            LikedAction(
              icon: Icons.heart_broken_rounded,
              label: 'Remove from Liked',
              onTap: () => controller.unlike(video),
            ),
          ],
        ),
      );
    });
  }
}
