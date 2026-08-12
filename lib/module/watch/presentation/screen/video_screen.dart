import 'package:beatx_flutter/module/watch/controller/music_player_controller.dart';
import 'package:beatx_flutter/module/watch/model/get_stream_url_model.dart';
import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';

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

  void _initializePlayer(String streamUrl) {
    if (_videoController != null) return;
    _videoController = VideoPlayerController.networkUrl(Uri.parse(streamUrl))
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
    _chewieController?.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            child: Obx(
              () => SingleChildScrollView(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [

                    /// AppBar
                    Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor:
                                Colors.white24,
                            child: IconButton(
                              icon: const Icon(
                                  Icons.arrow_back),
                              onPressed: () =>
                                  Get.back(),
                            ),
                          ),

                          const SizedBox(width: 10),

                          const Text(
                            "Now Playing",
                            style: TextStyle(
                              color:
                                  Colors.cyanAccent,
                              fontSize: 20,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),

                          const Spacer(),

                          const Icon(
                              Icons.more_vert),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    /// Video Player
                    AspectRatio(
                      aspectRatio: 16 / 9,
                      child: _chewieController != null
                          ? Chewie(controller: _chewieController!)
                          : ColoredBox(
                              color: Colors.black,
                              child: Center(
                                child: controller.errorMessage.value.isNotEmpty
                                    ? Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Text(
                                          controller.errorMessage.value,
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                              color: Colors.white70),
                                        ),
                                      )
                                    : const CircularProgressIndicator(
                                        color: Colors.cyanAccent,
                                      ),
                              ),
                            ),
                    ),

                    /// Song Info
                    Padding(
                      padding:
                          const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,
                        children: [
                          Text(
                            controller.details.value?.title ?? '',
                            style:
                                const TextStyle(
                              fontSize: 20,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),

                          const SizedBox(
                              height: 10),

                          Text(
                            '${controller.details.value?.ownerId.name ?? ''} • ${controller.details.value?.playCount ?? 0} plays • ${controller.likeCount.value} likes',
                            style:
                                const TextStyle(
                              color:
                                  Colors.white70,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),

                    /// Action Buttons
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(
                              horizontal: 16),
                      child: Row(
                        mainAxisAlignment:
                            MainAxisAlignment
                                .spaceEvenly,
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
                            icon:
                                Icons.playlist_add,
                            title: 'SAVE',
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    /// Up Next
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(
                              horizontal: 16),
                      child: Row(
                        children: [
                          const Text(
                            "Up Next",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),

                          const Spacer(),

                          const Text(
                              "Auto-play"),

                          Switch(
                            value: controller
                                .autoPlay.value,
                            onChanged: controller
                                .toggleAutoPlay,
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
                        physics:
                            const NeverScrollableScrollPhysics(),
                        itemCount: controller
                            .upNextList.length,
                        itemBuilder: (_, index) {

                          final relatedVideo =
                              controller
                                  .upNextList[index];

                          return ListTile(
                            onTap: () => Get.off(
                              () => MusicPlayerScreen(
                                videoId: relatedVideo.id,
                              ),
                            ),
                            leading: ClipRRect(
                              borderRadius:
                                  BorderRadius
                                      .circular(12),
                              child: Image.network(
                                relatedVideo.coverUrl,
                                width: 90,
                                height: 70,
                                fit: BoxFit.cover,
                              ),
                            ),
                            title: Text(
                              relatedVideo.title,
                              maxLines: 2,
                              overflow:
                                  TextOverflow
                                      .ellipsis,
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
        ],
      ),
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
        width: 75,
        height: 85,
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius:
              BorderRadius.circular(18),
        ),
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
            const SizedBox(height: 8),
            Text(title),
          ],
        ),
      ),
    );
  }
}
