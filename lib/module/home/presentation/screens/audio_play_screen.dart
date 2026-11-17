import 'package:beatx_flutter/core/common/widget/mini_player_host.dart';
import 'package:beatx_flutter/core/services/image_cache/cached_image.dart';
import 'dart:io';

import 'package:beatx_flutter/core/common/widget/now_playing_sheet.dart';
import 'package:beatx_flutter/core/notifiers/snackbar_notifier.dart';
import 'package:beatx_flutter/core/player/now_playing.dart';
import 'package:beatx_flutter/core/player/player_controller.dart';
import 'package:beatx_flutter/core/player/player_like_target.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../audiobook/controller/audiobook_like_controller.dart';
import '../../../podcast/controller/podcast_like_controller.dart';
import '../../controller/download_controller.dart';
import '../widgets/download_actions.dart';
import '../widgets/live_waveform.dart';
import 'equalizer_screen.dart';
import '../../controller/song_like_controller.dart';
import '../../../../core/theme/responsive.dart';

class PlayerScreen extends StatelessWidget {
  const PlayerScreen({super.key});

  static const LinearGradient _beatxGradient = LinearGradient(
    colors: [Color(0xFF9BFF4D), Color(0xFF40DDEB)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  @override
  Widget build(BuildContext context) =>
      // No mini player here: the full player is open.
      MiniPlayerHidden(child: _buildScreen(context));

  Widget _buildScreen(BuildContext context) {
    final ctrl = Get.find<PlayerController>();

    return Scaffold(
      backgroundColor: const Color(0xFF050608),
      body: Stack(
        children: [
          Positioned(
            top: -120,
            left: 40,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.blue.withValues(alpha: 0.4),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 80,
            left: 80,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.purple.withValues(alpha: 0.6),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Icon(
                          Icons.keyboard_arrow_down,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                      const SizedBox(width: 12),
                      // What this is playing from: the book, the show or
                      // the song list. Tap for its chapters/episodes.
                      Expanded(
                        child: Obx(() {
                          final playing = ctrl.nowPlaying.value;
                          final source = playing?.collectionTitle ?? '';
                          return GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: _hasSheet(playing)
                                ? () => showNowPlayingSheet(context)
                                : null,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  source.isEmpty
                                      ? 'NOW PLAYING'
                                      : playing!.heading,
                                  style: const TextStyle(
                                    color: Colors.white54,
                                    fontSize: 12,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        source.isEmpty
                                            ? ctrl.artist.value
                                            : source,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 20,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    if (_hasSheet(playing))
                                      const Icon(
                                        Icons.keyboard_arrow_right_rounded,
                                        color: Colors.white54,
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }),
                      ),
                      // Always reachable. Where the platform has no real
                      // equalizer the screen says so plainly — it never shows
                      // controls that cannot change the audio.
                      GestureDetector(
                        onTap: () => Get.to(
                          () => const EqualizerScreen(),
                          transition: Transition.downToUp,
                        ),
                        child: const Icon(
                          Icons.graphic_eq,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    // The art, scrubber and transport are a single column of
                    // controls; spread across a tablet they drift so far apart
                    // they stop reading as one player.
                    child: ContentWidth(
                      maxWidth: 560,
                      padded: false,
                      // Everything fits the screen without scrolling: the
                      // controls keep their size (a little tighter on short
                      // phones) and the cover takes whatever height is left.
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final s = _PlayerSpacing.forHeight(
                            constraints.maxHeight,
                          );
                          final controls = Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(height: s.gap),
                              Obx(() {
                                final progress =
                                    ctrl.duration.value.inMilliseconds > 0
                                    ? ctrl.position.value.inMilliseconds /
                                          ctrl.duration.value.inMilliseconds
                                    : 0.0;
                                return LiveWaveform(
                                  height: s.waveform,
                                  isPlaying: ctrl.isPlaying.value,
                                  progress: progress,
                                );
                              }),
                              SizedBox(height: s.gap / 2),
                              Obx(() {
                                final durationMs =
                                    ctrl.duration.value.inMilliseconds;
                                final progress = durationMs > 0
                                    ? (ctrl.position.value.inMilliseconds /
                                              durationMs)
                                          .clamp(0.0, 1.0)
                                    : 0.0;
                                return SliderTheme(
                                  data: SliderTheme.of(context).copyWith(
                                    trackHeight: 8,
                                    activeTrackColor: const Color(0xFF9BFF4D),
                                    inactiveTrackColor: Colors.white24,
                                    thumbColor: Colors.white,
                                    thumbShape: const RoundSliderThumbShape(
                                      enabledThumbRadius: 8,
                                    ),
                                    overlayShape: const RoundSliderOverlayShape(
                                      overlayRadius: 16,
                                    ),
                                    overlayColor: const Color(
                                      0xFF9BFF4D,
                                    ).withValues(alpha: 0.2),
                                  ),
                                  child: Slider(
                                    value: progress,
                                    min: 0.0,
                                    max: 1.0,
                                    onChanged: durationMs > 0
                                        ? (value) {
                                            ctrl.position.value = Duration(
                                              milliseconds: (value * durationMs)
                                                  .round(),
                                            );
                                          }
                                        : null,
                                    onChangeEnd: durationMs > 0
                                        ? (value) {
                                            ctrl.seek(
                                              Duration(
                                                milliseconds:
                                                    (value * durationMs)
                                                        .round(),
                                              ),
                                            );
                                          }
                                        : null,
                                  ),
                                );
                              }),
                              Obx(
                                () => Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _fmt(ctrl.position.value),
                                      style: const TextStyle(
                                        color: Colors.white70,
                                      ),
                                    ),
                                    Text(
                                      _fmt(ctrl.duration.value),
                                      style: const TextStyle(
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: s.gap),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Obx(
                                    () => _TransportButton(
                                      icon: Icons.shuffle_rounded,
                                      size: s.sideIcon,
                                      tooltip: ctrl.shuffle.value
                                          ? 'Shuffle on'
                                          : 'Shuffle off',
                                      active: ctrl.shuffle.value,
                                      onTap: ctrl.toggleShuffle,
                                    ),
                                  ),
                                  // Always usable: with nothing before it,
                                  // it restarts the track.
                                  _TransportButton(
                                    icon: Icons.skip_previous,
                                    size: s.skipIcon,
                                    tooltip: 'Previous',
                                    color: Colors.white,
                                    onTap: ctrl.previous,
                                  ),
                                  Obx(
                                    () => GestureDetector(
                                      onTap: () => ctrl.isPlaying.value
                                          ? ctrl.pause()
                                          : ctrl.resume(),
                                      child: Container(
                                        width: s.playButton,
                                        height: s.playButton,
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: _beatxGradient,
                                        ),
                                        child: Container(
                                          margin: const EdgeInsets.all(4),
                                          decoration: const BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Color(0xFF050608),
                                          ),
                                          child: Icon(
                                            ctrl.isPlaying.value
                                                ? Icons.pause
                                                : Icons.play_arrow,
                                            color: Colors.white,
                                            size: s.playButton * 0.55,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Obx(() {
                                    // Read so the button follows the track,
                                    // the queue and the repeat mode.
                                    ctrl.trackId.value;
                                    ctrl.queue.length;
                                    ctrl.repeatMode.value;
                                    ctrl.shuffle.value;
                                    return _TransportButton(
                                      icon: Icons.skip_next,
                                      size: s.skipIcon,
                                      tooltip: 'Next',
                                      color: Colors.white,
                                      onTap: ctrl.hasNext ? ctrl.next : null,
                                    );
                                  }),
                                  Obx(() {
                                    final mode = ctrl.repeatMode.value;
                                    return _TransportButton(
                                      icon: mode == PlayerRepeat.one
                                          ? Icons.repeat_one_rounded
                                          : Icons.repeat_rounded,
                                      size: s.sideIcon,
                                      tooltip: switch (mode) {
                                        PlayerRepeat.off => 'Repeat off',
                                        PlayerRepeat.all => 'Repeat all',
                                        PlayerRepeat.one => 'Repeat one',
                                      },
                                      active: mode != PlayerRepeat.off,
                                      onTap: ctrl.cycleRepeat,
                                    );
                                  }),
                                ],
                              ),
                              SizedBox(height: s.gap),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: s.actionsPadding,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF151515),
                                  borderRadius: BorderRadius.circular(35),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: [
                                    const Expanded(
                                      child: _BottomAction(
                                        icon: Icons.lyrics,
                                        title: 'LYRICS',
                                      ),
                                    ),
                                    _divider(),
                                    Expanded(
                                      child: Obx(() {
                                        final playing = ctrl.nowPlaying.value;
                                        final chapters =
                                            playing?.kind ==
                                            NowPlayingKind.chapter;
                                        return _BottomAction(
                                          icon: chapters
                                              ? Icons.menu_book_rounded
                                              : Icons.queue_music,
                                          title:
                                              playing == null ||
                                                  playing.kind ==
                                                      NowPlayingKind.song
                                              ? 'QUEUE'
                                              : playing.listName.toUpperCase(),
                                          onTap: _hasSheet(playing)
                                              ? () =>
                                                    showNowPlayingSheet(context)
                                              : null,
                                        );
                                      }),
                                    ),
                                    _divider(),
                                    const Expanded(
                                      child: _BottomAction(
                                        icon: Icons.share,
                                        title: 'SHARE',
                                      ),
                                    ),
                                    _divider(),
                                    Expanded(
                                      child: Obx(() {
                                        // Whichever of the song and podcast
                                        // bindings owns the current play session,
                                        // or neither for an audiobook.
                                        final target = _activeLikeTarget();
                                        final liked =
                                            target?.isLiked.value ?? false;

                                        return _BottomAction(
                                          icon: liked
                                              ? Icons.favorite
                                              : Icons.favorite_border,
                                          title: 'LIKE',
                                          active: liked,
                                          onTap: target == null
                                              ? null
                                              : () => _toggleLike(
                                                  context,
                                                  target,
                                                ),
                                        );
                                      }),
                                    ),
                                    _divider(),
                                    const Expanded(child: _DownloadAction()),
                                  ],
                                ),
                              ),
                              SizedBox(height: s.bottom),
                            ],
                          );
                          final cover = Obx(
                            () => ConstrainedBox(
                              constraints: const BoxConstraints(maxHeight: 350),
                              child: Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(42),
                                  color: const Color(0xFF1A1A1D),
                                  image: ctrl.imageAsset.value.isNotEmpty
                                      ? DecorationImage(
                                          image:
                                              ctrl.imageAsset.value.startsWith(
                                                'http',
                                              )
                                              ? CachedNetworkImageProvider(
                                                  ctrl.imageAsset.value,
                                                )
                                              // A downloaded song's saved cover.
                                              : PlayerController.isLocalFilePath(
                                                  ctrl.imageAsset.value,
                                                )
                                              ? FileImage(
                                                  File(ctrl.imageAsset.value),
                                                )
                                              : AssetImage(
                                                      ctrl.imageAsset.value,
                                                    )
                                                    as ImageProvider,
                                          fit: BoxFit.cover,
                                        )
                                      : null,
                                ),
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(42),
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.transparent,
                                        Colors.black.withValues(alpha: 0.75),
                                      ],
                                    ),
                                  ),
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    0,
                                    16,
                                    20,
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      // Which chapter (or episode) this is,
                                      // so a chapter title alone never
                                      // leaves the user guessing.
                                      _PositionBadge(ctrl: ctrl),
                                      Text(
                                        ctrl.title.value,
                                        textAlign: TextAlign.center,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 28,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        ctrl.artist.value,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Color(0xFF40DDEB),
                                          fontSize: 18,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );

                          // A screen too short for even a small cover beside
                          // the controls (landscape, split view) scrolls.
                          if (!s.fits) {
                            return SingleChildScrollView(
                              child: Column(
                                children: [
                                  SizedBox(height: 220, child: cover),
                                  controls,
                                ],
                              ),
                            );
                          }
                          return Column(
                            children: [
                              Expanded(
                                child: Align(
                                  alignment: Alignment.topCenter,
                                  child: cover,
                                ),
                              ),
                              controls,
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// The like binding for whatever the shared player is on, or null when what
  /// is playing has none — one of the bundled demo tracks.
  ///
  /// Each candidate is asked in turn, and asking reads the observables that
  /// [PlayerLikeTarget.canLike] is built from, so the caller's `Obx` stays
  /// subscribed even when the answer is null.
  static PlayerLikeTarget? _activeLikeTarget() {
    final candidates = <PlayerLikeTarget>[
      SongLikeController.instance,
      PodcastLikeController.instance,
      AudiobookLikeController.instance,
    ];

    for (final candidate in candidates) {
      if (candidate.canLike) return candidate;
    }
    return null;
  }

  static Future<void> _toggleLike(
    BuildContext context,
    PlayerLikeTarget target,
  ) async {
    await target.toggleLike();

    final error = target.errorMessage.value;
    if (error.isEmpty || !context.mounted) return;
    SnackbarNotifier(context: context).notifyError(message: error);
  }

  /// Whether there is a list of chapters/episodes (or a series) to show.
  static bool _hasSheet(NowPlayingContext? playing) =>
      playing != null &&
      playing.kind != NowPlayingKind.song &&
      (playing.entries.isNotEmpty || playing.series.isNotEmpty);

  static String _fmt(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    // Podcast episodes run past an hour — without this an 2:05:55 episode
    // reads as "05:55".
    if (hours > 0) return '$hours:$minutes:$seconds';
    return '$minutes:$seconds';
  }

  static Widget _divider() =>
      Container(width: 1, height: 35, color: Colors.white10);
}

/// "CHAPTER 3 OF 12" / "S2 · E5" over the title on the cover, or nothing
/// for a song.
class _PositionBadge extends StatelessWidget {
  const _PositionBadge({required this.ctrl});

  final PlayerController ctrl;

  @override
  Widget build(BuildContext context) {
    final playing = ctrl.nowPlaying.value;
    final label = playing == null || playing.kind == NowPlayingKind.song
        ? ''
        : playing.position(ctrl.trackId.value);
    if (label.isEmpty) return const SizedBox.shrink();
    const accent = Color(0xFF9BFF4D);
    // A button, not just a label: the quickest way to the other chapters.
    final badge = Semantics(
      button: true,
      label: '$label. Show ${playing!.listName.toLowerCase()}',
      child: Material(
        color: Colors.black.withValues(alpha: 0.45),
        shape: StadiumBorder(
          side: BorderSide(color: accent.withValues(alpha: 0.6)),
        ),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: () => showNowPlayingSheet(context),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 8, 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label.toUpperCase(),
                  style: const TextStyle(
                    color: accent,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(
                  Icons.format_list_bulleted_rounded,
                  color: accent,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
    return Padding(padding: const EdgeInsets.only(bottom: 10), child: badge);
  }
}

/// One of the transport's icon buttons. [active] shows a mode that is on
/// (shuffle, repeat) in the accent green; a null [onTap] dims it.
class _TransportButton extends StatelessWidget {
  const _TransportButton({
    required this.icon,
    required this.size,
    required this.tooltip,
    required this.onTap,
    this.active = false,
    this.color = Colors.white70,
  });

  final IconData icon;
  final double size;
  final String tooltip;
  final VoidCallback? onTap;
  final bool active;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final tint = onTap == null
        ? Colors.white24
        : active
        ? const Color(0xFF9BFF4D)
        : color;
    return Semantics(
      button: true,
      selected: active,
      label: tooltip,
      child: InkResponse(
        onTap: onTap,
        radius: size * 0.9,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, color: tint, size: size),
        ),
      ),
    );
  }
}

class _BottomAction extends StatelessWidget {
  const _BottomAction({
    required this.icon,
    required this.title,
    this.active = false,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? const Color(0xFF9BFF4D) : Colors.white70;

    return GestureDetector(
      onTap: onTap,
      // The label and the gap between it and the icon are part of the target.
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          // Shrinks rather than overflows when five labels share a narrow
          // phone's width.
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              title,
              maxLines: 1,
              style: TextStyle(color: color, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}

/// Saves the song that is playing for offline listening, and shows how far
/// that has got. Only a song can be downloaded; for an episode or an
/// audiobook the action is shown inert, like the others in the row.
class _DownloadAction extends StatelessWidget {
  const _DownloadAction();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // Reading canLike subscribes to the play session, so the action moves
      // on with the player when it switches to another track.
      final song = SongLikeController.instance;
      if (!song.canLike || song.songId.value.isEmpty) {
        return const _BottomAction(icon: Icons.download, title: 'DOWNLOAD');
      }

      final songId = song.songId.value;
      final state = DownloadController.instance.stateFor(songId);

      switch (state.status.value) {
        case DownloadStatus.downloading:
          final percent = state.percent;
          return GestureDetector(
            onTap: () => DownloadActions.confirmCancel(
              context,
              songId: songId,
              title: Get.find<PlayerController>().title.value,
            ),
            behavior: HitTestBehavior.opaque,
            child: Column(
              children: [
                SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    // Spins when the size is unknown rather than showing a
                    // made-up fraction.
                    value: state.progress.value,
                    strokeWidth: 2.4,
                    color: const Color(0xFF9BFF4D),
                    backgroundColor: Colors.white12,
                  ),
                ),
                const SizedBox(height: 8),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    percent == null ? 'SAVING' : '$percent%',
                    maxLines: 1,
                    style: const TextStyle(
                      color: Color(0xFF9BFF4D),
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          );
        case DownloadStatus.downloaded:
          return _BottomAction(
            icon: Icons.download_done_rounded,
            title: 'DOWNLOADED',
            active: true,
            onTap: () => DownloadActions.confirmRemove(
              context,
              songId: songId,
              title: Get.find<PlayerController>().title.value,
            ),
          );
        case DownloadStatus.failed:
          return _BottomAction(
            icon: Icons.refresh_rounded,
            title: 'RETRY',
            onTap: () => DownloadActions.retry(context, songId),
          );
        case DownloadStatus.notDownloaded:
          return _BottomAction(
            icon: Icons.download,
            title: 'DOWNLOAD',
            onTap: () {
              final player = Get.find<PlayerController>();
              DownloadActions.start(
                context,
                DownloadRequest(
                  songId: songId,
                  title: player.title.value,
                  artist: player.artist.value,
                  coverUrl: player.imageAsset.value,
                  durationMs: player.duration.value.inMilliseconds,
                ),
              );
            },
          );
      }
    });
  }
}

/// Sizes for the player's controls, chosen by how tall the screen is, so the
/// whole player fits without scrolling. The cover gets the height left over.
class _PlayerSpacing {
  const _PlayerSpacing({
    required this.gap,
    required this.waveform,
    required this.playButton,
    required this.skipIcon,
    required this.sideIcon,
    required this.actionsPadding,
    required this.bottom,
    this.minCover = 0,
    this.fits = true,
  });

  final double gap;
  final double waveform;
  final double playButton;
  final double skipIcon;
  final double sideIcon;
  final double actionsPadding;
  final double bottom;

  /// The shortest cover worth showing at these sizes; a roomier tier is only
  /// used when it leaves the cover at least this tall.
  final double minCover;

  /// False when even the tightest sizes leave no room for a cover; the
  /// player then scrolls.
  final bool fits;

  static const _tiers = [
    // Tall phones: the original look.
    _PlayerSpacing(
      gap: 24,
      waveform: 70,
      playButton: 100,
      skipIcon: 46,
      sideIcon: 30,
      actionsPadding: 18,
      bottom: 24,
      minCover: 280,
    ),
    _PlayerSpacing(
      gap: 18,
      waveform: 56,
      playButton: 88,
      skipIcon: 42,
      sideIcon: 28,
      actionsPadding: 15,
      bottom: 14,
      minCover: 220,
    ),
    // Small phones (iPhone SE, mini…).
    _PlayerSpacing(
      gap: 12,
      waveform: 44,
      playButton: 76,
      skipIcon: 38,
      sideIcon: 26,
      actionsPadding: 12,
      bottom: 8,
      minCover: 140,
    ),
  ];

  /// Height of everything under the cover. The slider row is 48 tall
  /// (Material's minimum tap height), the time labels about 20, and an
  /// action is its 22 icon, 8 gap and a line of text.
  double get controlsHeight =>
      gap +
      waveform +
      gap / 2 +
      48 +
      20 +
      gap +
      playButton +
      gap +
      actionsPadding * 2 +
      22 +
      8 +
      20 +
      bottom;

  static _PlayerSpacing forHeight(double height) {
    for (final tier in _tiers) {
      if (height - tier.controlsHeight >= tier.minCover) return tier;
    }
    final tightest = _tiers.last;
    return _PlayerSpacing(
      gap: tightest.gap,
      waveform: tightest.waveform,
      playButton: tightest.playButton,
      skipIcon: tightest.skipIcon,
      sideIcon: tightest.sideIcon,
      actionsPadding: tightest.actionsPadding,
      bottom: tightest.bottom,
      fits: false,
    );
  }
}
