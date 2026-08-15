import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../../core/notifiers/snackbar_notifier.dart';
import '../../../audiobook/presentation/widget/book_cover.dart';
import '../../controller/episode_details_controller.dart';
import '../../model/episodes_model.dart' as episodes_model;
import '../../model/podcast_home_model.dart';

/// Full episode details — cover, progress, description, transcript link and
/// the rest of the show's episodes. Reached by tapping an episode anywhere
/// in the podcast module; lets the user start/resume playback from here.
class EpisodeDetailsScreen extends StatelessWidget {
  const EpisodeDetailsScreen({super.key, required this.episode});

  final RecentEpisode episode;

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(EpisodeDetailsController(), tag: episode.id)
      // The list this screen was opened from may carry a length the details
      // payload does not.
      ..fallbackDurationMs = episode.durationMs;
    controller.loadDetails(episode.id);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: const Color(0xFF080909),
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFF080909),
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: MediaQuery.sizeOf(context).width / 1.05,
              pinned: true,
              backgroundColor: const Color(0xFF080909),
              elevation: 0,
              automaticallyImplyLeading: false,
              leadingWidth: 66,
              leading: Padding(
                padding: const EdgeInsets.only(left: 14),
                child: _CircleIconButton(
                  icon: Icons.arrow_back_rounded,
                  onTap: () => Navigator.maybePop(context),
                ),
              ),
              actions: [
                _CircleIconButton(
                  icon: Icons.favorite_border_rounded,
                  onTap: () {},
                ),
                const SizedBox(width: 10),
                _CircleIconButton(icon: Icons.more_vert_rounded, onTap: () {}),
                const SizedBox(width: 14),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: _CoverHeader(episode: episode),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
              sliver: SliverList.list(
                children: [
                  Obx(
                    () => _ProgressRow(
                      durationMs: controller.durationMs,
                      positionMs: controller.listenedMs,
                      fraction: controller.listenedFraction,
                      isCompleted: controller.isCompleted,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Obx(
                    () => _MetaRow(
                      showTitle: episode.podcastId.title,
                      durationMs: controller.durationMs,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'S${episode.seasonNumber.toString().padLeft(2, '0')} '
                    'E${episode.episodeNumber.toString().padLeft(2, '0')}: '
                    '${episode.title}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 23,
                      height: 1.18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Obx(
                    () => _PlayActionRow(
                      resumePosition: controller.resumePosition,
                      isCompleted: controller.isCompleted,
                      isLoading: controller.isStreamLoading,
                      onPlay: () => _play(context, controller),
                    ),
                  ),
                  const SizedBox(height: 26),
                  Obx(
                    () => _AboutSection(
                      description:
                          controller.details.value?.episode.description ?? '',
                      isLoading: controller.isLoading.value,
                      transcript: controller.details.value?.episode.transcript,
                    ),
                  ),
                  const SizedBox(height: 22),
                  Obx(() {
                    final genre =
                        controller.details.value?.episode.podcastId.genre ?? '';
                    if (genre.isEmpty) return const SizedBox.shrink();
                    return _TagsRow(tags: [genre]);
                  }),
                  const SizedBox(height: 28),
                  const _SectionHeader(title: 'More from Show'),
                  const SizedBox(height: 14),
                  Obx(() {
                    final related = controller.relatedEpisodes;
                    if (related.isEmpty) {
                      return const _EmptyState(
                        message: 'No other episodes yet.',
                      );
                    }
                    return Column(
                      children: [
                        for (final relatedEpisode in related) ...[
                          _RelatedEpisodeTile(
                            episode: relatedEpisode,
                            podcastTitle: episode.podcastId.title,
                            podcastCoverUrl: episode.podcastId.coverUrl,
                            isLoading:
                                controller.loadingEpisodeId.value ==
                                relatedEpisode.id,
                            onTap: () => _openRelated(context, relatedEpisode),
                          ),
                          const SizedBox(height: 12),
                        ],
                      ],
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _play(
    BuildContext context,
    EpisodeDetailsController controller,
  ) async {
    await controller.playEpisode(
      episodeId: episode.id,
      podcastId: episode.podcastId.id,
      title: episode.title,
      artist: episode.podcastId.title,
      coverUrl: episode.coverUrl ?? episode.podcastId.coverUrl,
    );
    if (context.mounted && controller.errorMessage.value.isNotEmpty) {
      SnackbarNotifier(
        context: context,
      ).notifyError(message: controller.errorMessage.value);
    }
  }

  void _openRelated(
    BuildContext context,
    episodes_model.PodcastEpisode relatedEpisode,
  ) {
    Get.to(
      () => EpisodeDetailsScreen(
        episode: RecentEpisode(
          id: relatedEpisode.id,
          podcastId: episode.podcastId,
          episodeNumber: relatedEpisode.episodeNumber,
          seasonNumber: relatedEpisode.seasonNumber,
          title: relatedEpisode.title,
          coverUrl: relatedEpisode.coverUrl,
          durationMs: relatedEpisode.durationMs,
          publishedAt: relatedEpisode.publishedAt ?? DateTime.now(),
        ),
      ),
    );
  }
}

// ─── Cover header ─────────────────────────────────────────────────────────

class _CoverHeader extends StatelessWidget {
  const _CoverHeader({required this.episode});

  final RecentEpisode episode;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(28),
        bottomRight: Radius.circular(28),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          BookCover(
            url: episode.coverUrl ?? episode.podcastId.coverUrl ?? '',
            placeholderIcon: Icons.mic_rounded,
            iconSize: 64,
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.45),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.55),
                  ],
                  stops: const [0, 0.35, 1],
                ),
              ),
            ),
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
      color: Colors.black.withValues(alpha: 0.38),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}

// ─── Progress ─────────────────────────────────────────────────────────────

class _ProgressRow extends StatelessWidget {
  const _ProgressRow({
    required this.durationMs,
    required this.positionMs,
    required this.fraction,
    required this.isCompleted,
  });

  final int durationMs;
  final int positionMs;
  final double fraction;
  final bool isCompleted;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: isCompleted ? 1 : fraction,
            minHeight: 6,
            backgroundColor: Colors.white24,
            valueColor: AlwaysStoppedAnimation(
              isCompleted ? const Color(0xFF9BFF4D) : const Color(0xFF40DDEB),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(_formatClock(positionMs), style: _clockStyle),
            _StatusLabel(fraction: fraction, isCompleted: isCompleted),
            // An unmeasured episode has no length to show — "0:00" would
            // read as an empty episode rather than a missing figure.
            Text(
              durationMs > 0 ? _formatClock(durationMs) : '--:--',
              style: _clockStyle,
            ),
          ],
        ),
      ],
    );
  }

  static const _clockStyle = TextStyle(
    color: Color(0xFF9C98A1),
    fontSize: 12,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
  );
}

/// "Completed", "62% completed", or nothing at all before the first listen.
class _StatusLabel extends StatelessWidget {
  const _StatusLabel({required this.fraction, required this.isCompleted});

  final double fraction;
  final bool isCompleted;

  @override
  Widget build(BuildContext context) {
    if (!isCompleted && fraction <= 0) return const SizedBox.shrink();

    final percent = (fraction * 100).round();
    return Text(
      isCompleted ? 'Completed' : '$percent% completed',
      style: TextStyle(
        color: isCompleted ? const Color(0xFF9BFF4D) : const Color(0xFF40DDEB),
        fontSize: 12,
        fontWeight: FontWeight.w800,
        letterSpacing: 0,
      ),
    );
  }
}

String _formatClock(int milliseconds) {
  if (milliseconds <= 0) return '0:00';
  final duration = Duration(milliseconds: milliseconds);
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  final seconds = duration.inSeconds.remainder(60);
  final paddedSeconds = seconds.toString().padLeft(2, '0');
  if (hours > 0) {
    final paddedMinutes = minutes.toString().padLeft(2, '0');
    return '$hours:$paddedMinutes:$paddedSeconds';
  }
  return '$minutes:$paddedSeconds';
}

// ─── Meta row ─────────────────────────────────────────────────────────────

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.showTitle, required this.durationMs});

  final String showTitle;
  final int durationMs;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (showTitle.isNotEmpty)
          Text(
            showTitle.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF9BFF4D),
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
            ),
          ),
        if (showTitle.isNotEmpty && durationMs > 0) ...[
          const SizedBox(width: 10),
          const _Dot(),
          const SizedBox(width: 10),
        ],
        if (durationMs > 0)
          Text(
            '+${formatPodcastDuration(durationMs)}',
            style: const TextStyle(
              color: Color(0xFF9C98A1),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0,
            ),
          ),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 3,
      height: 3,
      decoration: const BoxDecoration(
        color: Color(0xFF6E6A72),
        shape: BoxShape.circle,
      ),
    );
  }
}

// ─── Play action row ────────────────────────────────────────────────────

class _PlayActionRow extends StatelessWidget {
  const _PlayActionRow({
    required this.resumePosition,
    required this.isCompleted,
    required this.isLoading,
    required this.onPlay,
  });

  final Duration resumePosition;
  final bool isCompleted;
  final bool isLoading;
  final VoidCallback onPlay;

  String get _label {
    if (isCompleted) return 'Play Again';
    if (resumePosition > Duration.zero) return 'Resume Episode';
    return 'Play Episode';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 54,
            child: FilledButton.icon(
              onPressed: isLoading ? null : onPlay,
              icon: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: Color(0xFF111315),
                      ),
                    )
                  : const Icon(Icons.play_arrow_rounded, size: 26),
              label: Text(_label),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF40DDEB),
                foregroundColor: const Color(0xFF111315),
                disabledBackgroundColor: const Color(
                  0xFF40DDEB,
                ).withValues(alpha: 0.6),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        _OutlineIconButton(icon: Icons.download_rounded, onTap: () {}),
        const SizedBox(width: 10),
        _OutlineIconButton(icon: Icons.share_rounded, onTap: () {}),
      ],
    );
  }
}

class _OutlineIconButton extends StatelessWidget {
  const _OutlineIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(side: BorderSide(color: Colors.white24)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 54,
          height: 54,
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}

// ─── About section ────────────────────────────────────────────────────────

class _AboutSection extends StatelessWidget {
  const _AboutSection({
    required this.description,
    required this.isLoading,
    this.transcript,
  });

  final String description;
  final bool isLoading;
  final String? transcript;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(title: 'About this Episode'),
        const SizedBox(height: 10),
        Text(
          isLoading
              ? 'Loading…'
              : (description.isNotEmpty
                    ? description
                    : 'No description available.'),
          style: const TextStyle(
            color: Color(0xFFB9B5BE),
            fontSize: 13.5,
            height: 1.4,
            fontWeight: FontWeight.w600,
            letterSpacing: 0,
          ),
        ),
        if (transcript != null && transcript!.trim().isNotEmpty) ...[
          const SizedBox(height: 12),
          InkWell(
            onTap: () => _showTranscript(context, transcript!),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Read Transcript',
                  style: TextStyle(
                    color: Color(0xFF40DDEB),
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                ),
                SizedBox(width: 6),
                Icon(
                  Icons.arrow_forward_rounded,
                  color: Color(0xFF40DDEB),
                  size: 16,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  void _showTranscript(BuildContext context, String transcript) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF151617),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.92,
          expand: false,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Transcript',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      child: Text(
                        transcript,
                        style: const TextStyle(
                          color: Color(0xFFB9B5BE),
                          fontSize: 14,
                          height: 1.5,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

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

// ─── Tags ─────────────────────────────────────────────────────────────────

class _TagsRow extends StatelessWidget {
  const _TagsRow({required this.tags});

  final List<String> tags;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final tag in tags)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF151617),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white12),
            ),
            child: Text(
              '#$tag',
              style: const TextStyle(
                color: Color(0xFFBD89FF),
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
              ),
            ),
          ),
      ],
    );
  }
}

// ─── Related episodes ───────────────────────────────────────────────────

class _RelatedEpisodeTile extends StatelessWidget {
  const _RelatedEpisodeTile({
    required this.episode,
    required this.podcastTitle,
    required this.podcastCoverUrl,
    required this.isLoading,
    required this.onTap,
  });

  final episodes_model.PodcastEpisode episode;
  final String podcastTitle;
  final String? podcastCoverUrl;
  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final meta = [
      formatPodcastDuration(episode.durationMs),
      podcastTitle,
    ].where((e) => e.isNotEmpty).join(' - ');

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
                child: BookCover(
                  url: episode.coverUrl ?? podcastCoverUrl ?? '',
                  placeholderIcon: Icons.mic_rounded,
                  iconSize: 26,
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
                    meta,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF9C98A1),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    episode.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14.5,
                      height: 1.1,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ),
            ),
            if (isLoading)
              const Padding(
                padding: EdgeInsets.only(left: 8),
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF40DDEB),
                  ),
                ),
              )
            else
              const Icon(Icons.chevron_right_rounded, color: Color(0xFF6E6A72)),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
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
