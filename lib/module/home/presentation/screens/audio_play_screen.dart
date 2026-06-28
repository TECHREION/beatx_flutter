import 'package:beatx_flutter/core/player/player_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../watch/presentation/screen/equelizer_screen.dart';

class PlayerScreen extends StatelessWidget {
  const PlayerScreen({super.key});

  static const LinearGradient _beatxGradient = LinearGradient(
    colors: [Color(0xFF9BFF4D), Color(0xFF40DDEB)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const _waveHeights = [
    24.0, 40.0, 58.0, 42.0, 20.0, 52.0, 64.0, 68.0, 56.0, 46.0,
    32.0, 38.0, 24.0, 44.0, 28.0, 54.0, 22.0, 36.0, 48.0, 30.0,
  ];

  @override
  Widget build(BuildContext context) {
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
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'PLAYING FROM PLAYLIST',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'New Releases',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Get.to(
                          () => const EqualizerScreen(),
                          transition: Transition.downToUp,
                        ),
                        child: const Icon(Icons.more_vert, color: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 25),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          // Album art card
                          Obx(
                            () => Container(
                              height: 250,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(42),
                                color: const Color(0xFF1A1A1D),
                                image: ctrl.imageAsset.value.isNotEmpty
                                    ? DecorationImage(
                                        image: AssetImage(
                                            ctrl.imageAsset.value),
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
                                padding:
                                    const EdgeInsets.only(bottom: 20),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Text(
                                      ctrl.title.value,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      ctrl.artist.value,
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
                          const SizedBox(height: 24),

                          // Live waveform — bars light up as song progresses
                          Obx(() {
                            final progress =
                                ctrl.duration.value.inMilliseconds > 0
                                    ? ctrl.position.value.inMilliseconds /
                                        ctrl.duration.value.inMilliseconds
                                    : 0.0;
                            final activeCount = (progress * 20).round();
                            return SizedBox(
                              height: 70,
                              child: Row(
                                crossAxisAlignment:
                                    CrossAxisAlignment.end,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: List.generate(20, (i) {
                                  return Container(
                                    width: 3,
                                    height: _waveHeights[i],
                                    decoration: BoxDecoration(
                                      borderRadius:
                                          BorderRadius.circular(20),
                                      color: i < activeCount
                                          ? const Color(0xFF9BFF4D)
                                          : Colors.white24,
                                    ),
                                  );
                                }),
                              ),
                            );
                          }),
                          const SizedBox(height: 14),

                          // Progress bar
                          Obx(() {
                            final progress =
                                ctrl.duration.value.inMilliseconds > 0
                                    ? (ctrl.position.value.inMilliseconds /
                                            ctrl.duration.value
                                                .inMilliseconds)
                                        .clamp(0.0, 1.0)
                                    : 0.0;
                            return Stack(
                              children: [
                                Container(
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: Colors.white24,
                                    borderRadius:
                                        BorderRadius.circular(100),
                                  ),
                                ),
                                FractionallySizedBox(
                                  widthFactor: progress,
                                  child: Container(
                                    height: 8,
                                    decoration: BoxDecoration(
                                      gradient: _beatxGradient,
                                      borderRadius:
                                          BorderRadius.circular(100),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }),
                          const SizedBox(height: 10),

                          // Time labels
                          Obx(
                            () => Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _fmt(ctrl.position.value),
                                  style: const TextStyle(
                                      color: Colors.white70),
                                ),
                                Text(
                                  _fmt(ctrl.duration.value),
                                  style: const TextStyle(
                                      color: Colors.white70),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 30),

                          // Playback controls
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              const Icon(Icons.open_in_full,
                                  color: Colors.white70, size: 30),
                              const Icon(Icons.skip_previous,
                                  color: Colors.white, size: 46),
                              Obx(
                                () => GestureDetector(
                                  onTap: () => ctrl.isPlaying.value
                                      ? ctrl.pause()
                                      : ctrl.resume(),
                                  child: Container(
                                    width: 100,
                                    height: 100,
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
                                        size: 54,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const Icon(Icons.skip_next,
                                  color: Colors.white, size: 46),
                              const Icon(Icons.repeat,
                                  color: Colors.white70, size: 30),
                            ],
                          ),
                          const SizedBox(height: 28),

                          // Bottom actions
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 18,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF151515),
                              borderRadius: BorderRadius.circular(35),
                            ),
                            child: Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceAround,
                              children: [
                                const _BottomAction(
                                    icon: Icons.lyrics, title: 'LYRICS'),
                                _divider(),
                                const _BottomAction(
                                    icon: Icons.queue_music,
                                    title: 'QUEUE'),
                                _divider(),
                                const _BottomAction(
                                    icon: Icons.share, title: 'SHARE'),
                                _divider(),
                                const _BottomAction(
                                    icon: Icons.favorite_border,
                                    title: 'LIKE'),
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

  static String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  static Widget _divider() =>
      Container(width: 1, height: 35, color: Colors.white10);
}

class _BottomAction extends StatelessWidget {
  const _BottomAction({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 22),
        const SizedBox(height: 8),
        Text(
          title,
          style: const TextStyle(color: Colors.white70, fontSize: 11),
        ),
      ],
    );
  }
}
