import 'package:flutter/material.dart';

class PlayerScreen extends StatelessWidget {
  const PlayerScreen({super.key});

  static const LinearGradient beatxGradient = LinearGradient(
    colors: [
      Color(0xFF9BFF4D),
      Color(0xFF40DDEB),
    ],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  @override
  Widget build(BuildContext context) {
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
                    Colors.blue.withOpacity(.4),
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
                    Colors.purple.withOpacity(.6),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      const Icon(
                        Icons.keyboard_arrow_down,
                        color: Colors.white,
                        size: 30,
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: const [
                            Text(
                              "PLAYING FROM PLAYLIST",
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              "Cyber-Neon Dreams",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight:
                                    FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),

                      Image.asset(
                        "assets/images/logo.png",
                        height: 30,
                      ),

                      const SizedBox(width: 12),

                      const Icon(
                        Icons.more_vert,
                        color: Colors.white,
                      ),
                    ],
                  ),

                  const SizedBox(height: 25),

                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          Container(
                            height: 390,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius:
                                  BorderRadius.circular(
                                      42),
                              image: const DecorationImage(
                                image: AssetImage(
                                  "assets/images/song_cover.jpg",
                                ),
                                fit: BoxFit.cover,
                              ),
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius:
                                    BorderRadius.circular(
                                        42),
                                gradient: LinearGradient(
                                  begin:
                                      Alignment.topCenter,
                                  end:
                                      Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black
                                        .withOpacity(.75),
                                  ],
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.end,
                                children: const [
                                  Text(
                                    "Ami Tor Mayay",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 28,
                                      fontWeight:
                                          FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    "Mahtim Sakib",
                                    style: TextStyle(
                                      color: Color(
                                          0xFF40DDEB),
                                      fontSize: 18,
                                    ),
                                  ),
                                  SizedBox(height: 18),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          SizedBox(
                            height: 70,
                            child: Row(
                              crossAxisAlignment:
                                  CrossAxisAlignment.end,
                              mainAxisAlignment:
                                  MainAxisAlignment
                                      .spaceEvenly,
                              children: List.generate(
                                20,
                                (index) {
                                  final heights = [
                                    24.0,
                                    40.0,
                                    58.0,
                                    42.0,
                                    20.0,
                                    52.0,
                                    64.0,
                                    68.0,
                                    56.0,
                                    46.0,
                                    32.0,
                                    38.0,
                                    24.0,
                                    44.0,
                                    28.0,
                                    54.0,
                                    22.0,
                                    36.0,
                                    48.0,
                                    30.0,
                                  ];

                                  return Container(
                                    width: 3,
                                    height:
                                        heights[index],
                                    decoration:
                                        BoxDecoration(
                                      borderRadius:
                                          BorderRadius
                                              .circular(
                                                  20),
                                      color: index < 11
                                          ? const Color(
                                              0xFF9BFF4D)
                                          : Colors.white54,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),

                          const SizedBox(height: 14),

                          Stack(
                            children: [
                              Container(
                                height: 8,
                                decoration:
                                    BoxDecoration(
                                  color:
                                      Colors.white24,
                                  borderRadius:
                                      BorderRadius
                                          .circular(
                                              100),
                                ),
                              ),
                              Container(
                                height: 8,
                                width: MediaQuery.of(
                                            context)
                                        .size
                                        .width *
                                    .45,
                                decoration:
                                    BoxDecoration(
                                  gradient:
                                      beatxGradient,
                                  borderRadius:
                                      BorderRadius
                                          .circular(
                                              100),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 10),

                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment
                                    .spaceBetween,
                            children: const [
                              Text(
                                "01:42",
                                style: TextStyle(
                                  color:
                                      Colors.white70,
                                ),
                              ),
                              Text(
                                "03:58",
                                style: TextStyle(
                                  color:
                                      Colors.white70,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 30),

                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment
                                    .spaceBetween,
                            children: [
                              const Icon(
                                Icons.open_in_full,
                                color:
                                    Colors.white70,
                                size: 30,
                              ),

                              const Icon(
                                Icons.skip_previous,
                                color: Colors.white,
                                size: 46,
                              ),

                              Container(
                                width: 100,
                                height: 100,
                                decoration:
                                    const BoxDecoration(
                                  shape:
                                      BoxShape.circle,
                                  gradient:
                                      beatxGradient,
                                ),
                                child: Container(
                                  margin:
                                      const EdgeInsets
                                          .all(4),
                                  decoration:
                                      const BoxDecoration(
                                    shape: BoxShape
                                        .circle,
                                    color: Color(
                                        0xFF050608),
                                  ),
                                  child: const Icon(
                                    Icons.play_arrow,
                                    color:
                                        Colors.white,
                                    size: 54,
                                  ),
                                ),
                              ),

                              const Icon(
                                Icons.skip_next,
                                color: Colors.white,
                                size: 46,
                              ),

                              const Icon(
                                Icons.repeat,
                                color:
                                    Colors.white70,
                                size: 30,
                              ),
                            ],
                          ),

                          const SizedBox(height: 28),

                          Container(
                            padding:
                                const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 18,
                            ),
                            decoration:
                                BoxDecoration(
                              color: const Color(
                                  0xFF151515),
                              borderRadius:
                                  BorderRadius
                                      .circular(35),
                            ),
                            child: Row(
                              mainAxisAlignment:
                                  MainAxisAlignment
                                      .spaceAround,
                              children: [
                                _BottomAction(
                                  icon: Icons.lyrics,
                                  title: "LYRICS",
                                ),
                                _divider(),
                                _BottomAction(
                                  icon:
                                      Icons.queue_music,
                                  title: "QUEUE",
                                ),
                                _divider(),
                                _BottomAction(
                                  icon: Icons.share,
                                  title: "SHARE",
                                ),
                                _divider(),
                                _BottomAction(
                                  icon:
                                      Icons.favorite_border,
                                  title: "LIKE",
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 30),
                        ],
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

  Widget _divider() {
    return Container(
      width: 1,
      height: 35,
      color: Colors.white10,
    );
  }
}

class _BottomAction extends StatelessWidget {
  final IconData icon;
  final String title;

  const _BottomAction({
    required this.icon,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          icon,
          color: Colors.white70,
          size: 22,
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}
