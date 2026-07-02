import 'package:beatx_flutter/module/watch/controller/music_player_controller.dart';
import 'package:beatx_flutter/module/watch/model/music_video_model.dart';
import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';

class MusicPlayerScreen extends StatefulWidget {
  const MusicPlayerScreen({super.key, required this.video});

  final MusicVideoModel video;

  @override
  State<MusicPlayerScreen> createState() => _MusicPlayerScreenState();
}

class _MusicPlayerScreenState extends State<MusicPlayerScreen> {
  final MusicPlayerController controller = Get.put(MusicPlayerController());

  late final VideoPlayerController _videoController;
  ChewieController? _chewieController;

  @override
  void initState() {
    super.initState();
    _videoController = VideoPlayerController.asset(widget.video.videoAsset)
      ..initialize().then((_) {
        if (!mounted) return;
        setState(() {
          _chewieController = ChewieController(
            videoPlayerController: _videoController,
            autoPlay: true,
            looping: false,
            aspectRatio: _videoController.value.aspectRatio,
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
    _chewieController?.dispose();
    _videoController.dispose();
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
                          const EdgeInsets.all(16),
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
                      aspectRatio: _videoController.value.isInitialized
                          ? _videoController.value.aspectRatio
                          : 16 / 9,
                      child: _chewieController != null
                          ? Chewie(controller: _chewieController!)
                          : const ColoredBox(
                              color: Colors.black,
                              child: Center(
                                child: CircularProgressIndicator(
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
                            widget.video.title,
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
                            '${widget.video.artist} • ${widget.video.meta}',
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
                        children: const [
                          ActionCard(
                            icon:
                                Icons.favorite_border,
                            title: 'LIKE',
                          ),
                          ActionCard(
                            icon: Icons.share,
                            title: 'SHARE',
                          ),
                          ActionCard(
                            icon: Icons.download,
                            title: 'GET',
                          ),
                          ActionCard(
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

                    ListView.builder(
                      shrinkWrap: true,
                      physics:
                          const NeverScrollableScrollPhysics(),
                      itemCount: controller
                          .upNextList.length,
                      itemBuilder: (_, index) {

                        MusicModel music =
                            controller
                                .upNextList[index];

                        return ListTile(
                          leading: ClipRRect(
                            borderRadius:
                                BorderRadius
                                    .circular(12),
                            child: Image.network(
                              music.image,
                              width: 90,
                              height: 70,
                              fit: BoxFit.cover,
                            ),
                          ),
                          title: Text(
                            music.title,
                            maxLines: 2,
                            overflow:
                                TextOverflow
                                    .ellipsis,
                          ),
                          subtitle: Text(
                            music.artist,
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

  const ActionCard({
    super.key,
    required this.icon,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
            color: Colors.cyanAccent,
          ),
          const SizedBox(height: 8),
          Text(title),
        ],
      ),
    );
  }
}
