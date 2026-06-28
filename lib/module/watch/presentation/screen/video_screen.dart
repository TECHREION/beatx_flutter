import 'package:beatx_flutter/module/watch/controller/music_player_controller.dart';
import 'package:beatx_flutter/module/watch/model/music_video_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MusicPlayerScreen extends StatelessWidget {
  MusicPlayerScreen({super.key});

  final MusicPlayerController controller =
      Get.put(MusicPlayerController());

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

                    /// Play Section
                    SizedBox(
                      height: 220,
                      child: Center(
                        child: GestureDetector(
                          onTap:
                              controller.togglePlay,
                          child: Container(
                            width: 90,
                            height: 90,
                            decoration:
                                BoxDecoration(
                              shape:
                                  BoxShape.circle,
                              color:
                                  Colors.black87,
                              border: Border.all(
                                color: Colors
                                    .purpleAccent,
                                width: 3,
                              ),
                            ),
                            child: Icon(
                              controller
                                      .isPlaying
                                      .value
                                  ? Icons.pause
                                  : Icons.play_arrow,
                              size: 50,
                            ),
                          ),
                        ),
                      ),
                    ),

                    /// Slider
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(
                              horizontal: 16),
                      child: Column(
                        children: [
                          Slider(
                            value: controller
                                .progress.value,
                            min: 0,
                            max: 223,
                            activeColor:
                                Colors.greenAccent,
                            onChanged: controller
                                .updateProgress,
                          ),

                          const Row(
                            mainAxisAlignment:
                                MainAxisAlignment
                                    .spaceBetween,
                            children: [
                              Text("01:42"),
                              Text("03:43"),
                            ],
                          ),
                        ],
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
                            controller
                                .currentMusic
                                .value
                                .title,
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
                            controller
                                .currentMusic
                                .value
                                .description,
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