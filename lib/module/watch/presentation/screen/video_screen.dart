import 'dart:async';

import 'package:beatx_flutter/module/watch/controller/music_player_controller.dart';
import 'package:beatx_flutter/module/watch/model/get_stream_url_model.dart';
import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/theme/responsive.dart';

String _formatDuration(int durationMs) {
  final totalSeconds = (durationMs / 1000).round();
  final minutes = totalSeconds ~/ 60;
  final seconds = totalSeconds % 60;
  return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
}

class MusicPlayerScreen extends StatefulWidget {
  const MusicPlayerScreen({super.key, required this.videoId});

  final String videoId;

  @override
  State<MusicPlayerScreen> createState() => _MusicPlayerScreenState();
}

class _MusicPlayerScreenState extends State<MusicPlayerScreen> {
  final MusicPlayerController controller = Get.put(MusicPlayerController());

  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  Worker? _streamUrlWorker;
  final _scrollController = ScrollController();

  /// Guards the end-of-video handler: the player keeps ticking once it has
  /// stopped at the end, and auto-play must only advance once.
  bool _reachedEnd = false;

  @override
  void initState() {
    super.initState();
    controller.loadVideo(widget.videoId);
    _streamUrlWorker = ever<VideoStreamUrlModel?>(
      controller.streamUrlData,
      (streamUrlData) {
        if (streamUrlData != null && streamUrlData.streamUrl.isNotEmpty) {
          _initializePlayer(streamUrlData.streamUrl);
        }
      },
    );
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
    await controller.loadVideo(videoId);
  }

  Future<void> _teardownPlayer() async {
    _videoController?.removeListener(_onVideoTick);
    final chewie = _chewieController;
    final video = _videoController;
    _chewieController = null;
    _videoController = null;
    _reachedEnd = false;
    chewie?.dispose();
    await video?.dispose();
  }

  void _onVideoTick() {
    final video = _videoController?.value;
    if (video == null || !video.isInitialized || _reachedEnd) return;

    if (video.duration > Duration.zero &&
        !video.isPlaying &&
        video.position >= video.duration) {
      _reachedEnd = true;
      _advanceIfAutoPlaying();
    }
  }

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

  void _initializePlayer(String streamUrl) {
    if (_videoController != null) return;
    _videoController = VideoPlayerController.networkUrl(Uri.parse(streamUrl))
      ..addListener(_onVideoTick)
      ..initialize().then((_) {
        if (!mounted) return;
        setState(() {
          _chewieController = ChewieController(
            videoPlayerController: _videoController!,
            autoPlay: true,
            looping: false,
            aspectRatio: _videoController!.value.aspectRatio,
            allowFullScreen: true,
            allowMuting: true,
            deviceOrientationsOnEnterFullScreen: const [
              DeviceOrientation.landscapeLeft,
              DeviceOrientation.landscapeRight,
            ],
            deviceOrientationsAfterFullScreen: const [
              DeviceOrientation.portraitUp,
            ],
            systemOverlaysAfterFullScreen: SystemUiOverlay.values,
            materialProgressColors: ChewieProgressColors(
              playedColor: Colors.cyanAccent,
              handleColor: Colors.cyanAccent,
              bufferedColor: Colors.white38,
              backgroundColor: Colors.white24,
            ),
          );
        });
      });
  }

  @override
  void dispose() {
    _streamUrlWorker?.dispose();
    _scrollController.dispose();
    _videoController?.removeListener(_onVideoTick);
    _chewieController?.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      // The way out sits above the video rather than on top of it, so nothing
      // covers the picture and the button is always where it was last time.
      appBar: AppBar(
        backgroundColor: Colors.black,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: Get.back<void>,
          tooltip: 'Back',
        ),
      ),
      body: SafeArea(
        top: false,
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
                            const ActionCard(
                              icon: Icons.download,
                              title: 'GET',
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
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: controller.upNextList.length,
                          itemBuilder: (_, index) {
                            final relatedVideo = controller.upNextList[index];

                            return ListTile(
                              onTap: () => _playVideo(relatedVideo.id),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: context.responsive(
                                  phone: 16.0,
                                  tablet: 20.0,
                                ),
                                vertical: context.responsive(
                                  phone: 0.0,
                                  tablet: 6.0,
                                ),
                              ),
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  relatedVideo.coverUrl,
                                  // A 90pt thumbnail beside a tablet-width
                                  // title reads as a placeholder.
                                  width: context.responsive(
                                    phone: 90.0,
                                    tablet: 132.0,
                                  ),
                                  height: context.responsive(
                                    phone: 70.0,
                                    tablet: 84.0,
                                  ),
                                  fit: BoxFit.cover,
                                ),
                              ),
                              title: Text(
                                relatedVideo.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                '${relatedVideo.ownerId.name} • ${_formatDuration(relatedVideo.durationMs)}',
                              ),
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
    );
  }
}

/// The video itself, at a fixed 16:9.
///
/// Nothing is laid over the picture: the back button lives in the app bar
/// above the player, so the frame stays clear whether or not Chewie happens
/// to be showing its own controls.
class _PlayerSurface extends StatelessWidget {
  const _PlayerSurface({
    required this.chewieController,
    required this.errorMessage,
  });

  final ChewieController? chewieController;
  final RxString errorMessage;

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

        return ColoredBox(
          color: Colors.black,
          child: Center(
            child: message.isNotEmpty
                ? Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  )
                : const CircularProgressIndicator(color: Colors.cyanAccent),
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
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: active
                  ? Colors.redAccent
                  : Colors.cyanAccent,
            ),
            // const SizedBox(height: 8),
            // Text(title),
          ],
        ),
      ),
    );
  }
}
