import 'package:beatx_flutter/core/common/widget/mini_player_host.dart';
import 'dart:async';
import 'dart:io';

import 'package:beatx_flutter/module/watch/controller/music_player_controller.dart';
import 'package:beatx_flutter/module/watch/model/get_stream_url_model.dart';
import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/theme/responsive.dart';
import '../../controller/video_download_controller.dart';
import '../../controller/video_mini_player_controller.dart';
import '../../model/watch_model.dart';
import '../widgets/video_download_button.dart';
import '../widgets/video_player_controls.dart';

String _formatDuration(int durationMs) {
  final totalSeconds = (durationMs / 1000).round();
  final minutes = totalSeconds ~/ 60;
  final seconds = totalSeconds % 60;
  return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
}

class MusicPlayerScreen extends StatefulWidget {
  const MusicPlayerScreen({super.key, required this.videoId});

  final String videoId;

  /// Opens the player sliding up from the bottom, the way the audio player
  /// opens (see FloatingPlayer). GetX plays a route's transition in reverse
  /// when it is popped, so minimizing (the down arrow, back, swipe down)
  /// slides the screen back down.
  static Future<void>? open(String videoId) => Get.to<void>(
    () => MusicPlayerScreen(videoId: videoId),
    transition: Transition.downToUp,
    preventDuplicates: false,
  );

  @override
  State<MusicPlayerScreen> createState() => _MusicPlayerScreenState();
}

class _MusicPlayerScreenState extends State<MusicPlayerScreen> {
  late final MusicPlayerController controller;

  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  Worker? _streamUrlWorker;
  final _scrollController = ScrollController();

  /// Guards the end-of-video handler: the player keeps ticking once it has
  /// stopped at the end, and auto-play must only advance once.
  bool _reachedEnd = false;

  /// Set once the player has been handed to the mini player, so leaving the
  /// screen does not stop it.
  bool _minimized = false;

  @override
  void initState() {
    super.initState();
    // Coming back from the mini player: carry on with the same player and
    // the details already loaded. Any other video playing there is stopped.
    final handoff = VideoMiniPlayerController.instance.takeOver(widget.videoId);
    if (handoff != null) {
      controller = handoff.details;
      Get.put(controller);
      _adoptPlayer(handoff.video);
    } else {
      controller = Get.put(MusicPlayerController());
      controller.loadVideo(widget.videoId);
      unawaited(_startPlayback(widget.videoId));
    }
    _streamUrlWorker = ever<VideoStreamUrlModel?>(controller.streamUrlData, (
      streamUrlData,
    ) {
      if (streamUrlData != null && streamUrlData.streamUrl.isNotEmpty) {
        unawaited(_startPlayback(controller.currentVideoId ?? ''));
      }
    });
  }

  /// Plays [videoId] from its downloaded file when there is one — which is
  /// also what lets it play with no connection — else from the stream url
  /// once that has arrived.
  Future<void> _startPlayback(String videoId) async {
    if (videoId.isEmpty) return;
    final local = await VideoDownloadController.instance.playablePath(videoId);
    if (!mounted || controller.currentVideoId != videoId) return;
    if (local != null) {
      _initializePlayer(local);
      return;
    }
    final url = controller.streamUrlData.value?.streamUrl ?? '';
    if (url.isNotEmpty) _initializePlayer(url);
  }

  /// Switches the player to [videoId] without leaving the screen.
  ///
  /// Replacing the route instead — which is what tapping Up Next used to do —
  /// re-registered the controller this screen is bound to while the outgoing
  /// screen was still being torn down, so the new video never started.
  Future<void> _playVideo(String videoId) async {
    if (videoId.isEmpty || videoId == controller.currentVideoId) return;

    await _teardownPlayer();
    if (!mounted) return;
    // Back to the player, which is off screen when the tap came from Up Next.
    if (_scrollController.hasClients) {
      unawaited(
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        ),
      );
    }
    setState(() {});
    final loading = controller.loadVideo(videoId);
    unawaited(_startPlayback(videoId));
    await loading;
  }

  Future<void> _teardownPlayer() async {
    _videoController?.removeListener(_onVideoTick);
    final chewie = _chewieController;
    final video = _videoController;
    final position = _playedPosition();
    _chewieController = null;
    _videoController = null;
    _reachedEnd = false;

    // Sent before the controller is pointed at another video, so it is saved
    // against the right one. Not awaited: swapping videos should not wait on
    // a network round trip.
    if (position != null) {
      unawaited(controller.flushProgress(position.$1, position.$2));
    }

    chewie?.dispose();
    await video?.dispose();
  }

  /// Where playback has reached and how long the video is, or null while
  /// there is nothing initialized to read it off.
  (Duration, Duration)? _playedPosition() {
    final video = _videoController?.value;
    if (video == null || !video.isInitialized) return null;
    return (video.position, video.duration);
  }

  void _onVideoTick() {
    final video = _videoController?.value;
    if (video == null || !video.isInitialized || _reachedEnd) return;

    if (video.duration > Duration.zero &&
        !video.isPlaying &&
        video.position >= video.duration) {
      _reachedEnd = true;
      // Watched to the end, so next time it starts over rather than
      // resuming on the last frame.
      unawaited(controller.markCompleted(video.duration));
      _advanceIfAutoPlaying();
      return;
    }

    // Throttled controller side — this runs several times a second.
    if (video.isPlaying) {
      controller.reportProgress(video.position, video.duration);
    } else if (_wasPlaying) {
      // Just paused (by the user, or the app going to the background): save
      // now rather than up to 10 s behind.
      unawaited(controller.flushProgress(video.position, video.duration));
    }
    _wasPlaying = video.isPlaying;
  }

  bool _wasPlaying = false;

  /// Rolls on to the top of Up Next when the switch is on. Before this the
  /// toggle only stored a flag and nothing ever read it.
  void _advanceIfAutoPlaying() {
    if (!controller.autoPlay.value) return;
    final next = controller.nextUpNext;
    if (next == null) return;
    // Off the notification. This runs inside the player's own listener, and
    // swapping videos disposes that player — doing it here would tear it down
    // part-way through notifying.
    scheduleMicrotask(() => _playVideo(next.id));
  }

  /// Takes over a player that is already initialized and playing.
  void _adoptPlayer(VideoPlayerController video) {
    _videoController = video;
    video.addListener(_onVideoTick);
    _chewieController = _buildChewie(video, autoPlay: video.value.isPlaying);
  }

  /// YouTube's down arrow: the video keeps playing in the mini player and
  /// the screen goes away.
  void _minimize() {
    final video = _videoController;
    if (video == null || !video.value.isInitialized) {
      // Nothing playing yet worth keeping.
      Get.back<void>();
      return;
    }
    video.removeListener(_onVideoTick);
    final details = controller.details.value;
    VideoMiniPlayerController.instance.minimize(
      MiniVideoSession(
        videoId: controller.currentVideoId ?? widget.videoId,
        title: details?.title ?? '',
        channel: details?.ownerId.name ?? '',
        video: video,
        details: controller,
      ),
    );
    _minimized = true;
    Get.back<void>();
  }

  ChewieController _buildChewie(
    VideoPlayerController video, {
    bool autoPlay = true,
  }) {
    return ChewieController(
      videoPlayerController: video,
      autoPlay: autoPlay,
      looping: false,
      aspectRatio: video.value.aspectRatio,
      allowFullScreen: true,
      allowMuting: true,
      customControls: VideoPlayerControls(
        onMinimize: _minimize,
        onNext: () {
          final next = controller.nextUpNext;
          if (next != null) unawaited(_playVideo(next.id));
        },
        hasNext: () => controller.nextUpNext != null,
        autoPlay: controller.autoPlay,
      ),
      deviceOrientationsOnEnterFullScreen: const [
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ],
      deviceOrientationsAfterFullScreen: const [DeviceOrientation.portraitUp],
      systemOverlaysAfterFullScreen: SystemUiOverlay.values,
      materialProgressColors: ChewieProgressColors(
        playedColor: Colors.cyanAccent,
        handleColor: Colors.cyanAccent,
        bufferedColor: Colors.white38,
        backgroundColor: Colors.white24,
      ),
    );
  }

  /// [source] is a stream url, or the absolute path of a downloaded file.
  void _initializePlayer(String source) {
    if (_videoController != null) return;
    final video = source.startsWith('/')
        ? VideoPlayerController.file(File(source))
        : VideoPlayerController.networkUrl(Uri.parse(source));
    _videoController = video;
    video
      ..addListener(_onVideoTick)
      ..initialize().then((_) async {
        // A tap on Up Next while this was loading has already replaced the
        // player this call was setting up.
        if (!mounted || _videoController != video) return;

        // Picks up where this user left off. Seeking before Chewie is built
        // means playback starts there rather than jumping once it is under
        // way; the details carrying the resume point are loaded before the
        // stream url that triggers this.
        final resumeAt = controller.resumePosition;
        if (resumeAt > Duration.zero && resumeAt < video.value.duration) {
          await video.seekTo(resumeAt);
          if (!mounted || _videoController != video) return;
        }

        setState(() => _chewieController = _buildChewie(video));
      });
  }

  @override
  void dispose() {
    _streamUrlWorker?.dispose();
    _scrollController.dispose();

    if (_minimized) {
      // The mini player owns the video now and keeps it playing.
      _chewieController?.dispose();
      super.dispose();
      return;
    }

    // Leaving the screen is the last chance to record where playback got to.
    final position = _playedPosition();
    if (position != null) {
      unawaited(controller.flushProgress(position.$1, position.$2));
    }

    _videoController?.removeListener(_onVideoTick);
    _chewieController?.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScope(
    // Back minimizes into the mini player, as on YouTube; the cross on the
    // mini player is what stops the video. (Get.back pops regardless.)
    canPop: false,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) _minimize();
    },
    // No mini player here: a video is playing full screen.
    child: MiniPlayerHidden(child: _buildScreen(context)),
  );

  Widget _buildScreen(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      // The player sits right under the status bar; its controls (minimize,
      // auto-play, settings, full screen) are laid over the picture.
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // Pinned. The player holds the top of the screen and the detail
              // below scrolls under it, rather than the whole page scrolling
              // and carrying the video off screen with it.
              // A 16:9 player that keeps growing with the screen ends up
              // taller than the space left for anything else, so it is capped.
              ContentWidth.wide(
                padded: false,
                child: _PlayerSurface(
                  chewieController: _chewieController,
                  errorMessage: controller.errorMessage,
                  onClose: _minimize,
                ),
              ),

              /// Everything under the player scrolls.
              Expanded(
                child: Obx(
                  () => SingleChildScrollView(
                    controller: _scrollController,
                    padding: const EdgeInsets.only(bottom: 32),
                    child: ContentWidth(
                      padded: false,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          /// Title and stats
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  controller.details.value?.title ?? '',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  '${controller.details.value?.ownerId.name ?? ''} • ${controller.details.value?.playCount ?? 0} plays • ${controller.likeCount.value} likes',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          /// Action Buttons
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                ActionCard(
                                  icon: controller.isLiked.value
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  title: 'LIKE',
                                  active: controller.isLiked.value,
                                  onTap: controller.toggleLike,
                                ),
                                const ActionCard(
                                  icon: Icons.share,
                                  title: 'SHARE',
                                ),
                                VideoDownloadButton(
                                  videoId: controller.currentVideoId ?? '',
                                  details: controller.details.value,
                                ),
                                const ActionCard(
                                  icon: Icons.playlist_add,
                                  title: 'SAVE',
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          /// Up Next
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              children: [
                                const Text(
                                  "Up Next",
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Spacer(),
                                const Text("Auto-play"),
                                Switch(
                                  value: controller.autoPlay.value,
                                  onChanged: controller.toggleAutoPlay,
                                ),
                              ],
                            ),
                          ),

                          if (controller.isLoading.value &&
                              controller.upNextList.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 24),
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: Colors.cyanAccent,
                                ),
                              ),
                            )
                          else
                            ListView.builder(
                              padding: const EdgeInsets.only(top: 8),
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: controller.upNextList.length,
                              itemBuilder: (_, index) {
                                final relatedVideo =
                                    controller.upNextList[index];

                                return _UpNextCard(
                                  video: relatedVideo,
                                  onTap: () => _playVideo(relatedVideo.id),
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The video itself, at a fixed 16:9.
///
/// Its controls ([VideoPlayerControls]) are laid over the picture.
class _PlayerSurface extends StatelessWidget {
  const _PlayerSurface({
    required this.chewieController,
    required this.errorMessage,
    required this.onClose,
  });

  final ChewieController? chewieController;
  final RxString errorMessage;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Obx(() {
        // Read first, so this rebuilds on an error arriving even while a
        // player is on screen.
        final message = errorMessage.value;
        final chewie = chewieController;
        if (chewie != null) return Chewie(controller: chewie);

        // Still loading (or failed): the controls carrying the minimize
        // button are not there yet, so offer the way out here.
        return ColoredBox(
          color: Colors.black,
          child: Stack(
            children: [
              Positioned(
                top: 4,
                left: 4,
                child: IconButton(
                  onPressed: onClose,
                  icon: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: Colors.white,
                    size: 32,
                    semanticLabel: 'Close',
                  ),
                ),
              ),
              Center(
                child: message.isNotEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          message,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white70),
                        ),
                      )
                    : const CircularProgressIndicator(color: kVideoAccent),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool active;
  final VoidCallback? onTap;

  const ActionCard({
    super.key,
    required this.icon,
    required this.title,
    this.active = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        // width: 85,
        // height: 25,
        // decoration: BoxDecoration(
        //   color: Colors.white10,
        //   borderRadius:
        //       BorderRadius.circular(18),
        // ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: active ? Colors.redAccent : Colors.cyanAccent),
            // const SizedBox(height: 8),
            // Text(title),
          ],
        ),
      ),
    );
  }
}

/// An Up Next video as a YouTube feed card: the full-width thumbnail with its
/// length, then the channel initial, title and "channel · plays · age".
class _UpNextCard extends StatelessWidget {
  const _UpNextCard({required this.video, required this.onTap});

  final VideoModel video;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final channel = video.ownerId.name;
    final age = _timeAgo(video.publishedAt);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
      child: Material(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      video.coverUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) =>
                          const ColoredBox(color: Color(0xFF2A2A2A)),
                    ),
                    Positioned(
                      right: 8,
                      bottom: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _formatDuration(video.durationMs),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 0, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: const Color(0xFF3A3A3A),
                      child: Text(
                        channel.isEmpty ? '?' : channel[0].toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            video.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text.rich(
                            TextSpan(
                              children: [
                                if (channel.isNotEmpty)
                                  TextSpan(text: '$channel  '),
                                const WidgetSpan(
                                  alignment: PlaceholderAlignment.middle,
                                  child: Icon(
                                    Icons.play_arrow_outlined,
                                    size: 14,
                                    color: Colors.white60,
                                  ),
                                ),
                                TextSpan(text: _compact(video.playCount)),
                                if (age != null) TextSpan(text: '  $age'),
                              ],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Icon(Icons.more_vert, color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 394000 -> 394K, 1200000 -> 1.2M.
  static String _compact(int n) {
    String trim(double v) => v >= 10 || v == v.roundToDouble()
        ? v.toStringAsFixed(0)
        : v.toStringAsFixed(1);
    if (n >= 1000000) return '${trim(n / 1000000)}M';
    if (n >= 1000) return '${trim(n / 1000)}K';
    return '$n';
  }

  static String? _timeAgo(String? iso) {
    final date = iso == null ? null : DateTime.tryParse(iso);
    if (date == null) return null;
    final d = DateTime.now().difference(date);
    if (d.inDays >= 365) return '${d.inDays ~/ 365}y ago';
    if (d.inDays >= 30) return '${d.inDays ~/ 30}mo ago';
    if (d.inDays >= 1) return '${d.inDays}d ago';
    if (d.inHours >= 1) return '${d.inHours}h ago';
    return '${d.inMinutes}m ago';
  }
}
