import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';

import '../../controller/video_mini_player_controller.dart';
import '../screen/video_screen.dart';
import 'video_player_controls.dart';

/// The minimized video: a small floating picture in the bottom-right corner,
/// shown above every screen (see MiniPlayerOverlay).
///
/// Tap to open the full player again, the play button to pause/resume, the
/// cross (or a swipe sideways) to stop it.
///
/// No tooltips anywhere in here: this sits above the navigator, outside any
/// Overlay, and a Tooltip needs one.
class VideoMiniPlayer extends StatelessWidget {
  const VideoMiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final mini = VideoMiniPlayerController.instance;
    return Obx(() {
      final session = mini.session.value;
      if (session == null) return const SizedBox.shrink();
      final screenWidth = MediaQuery.sizeOf(context).width;
      return Align(
        alignment: Alignment.centerRight,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
          child: Dismissible(
            key: ValueKey(session.video),
            onDismissed: (_) => mini.close(),
            child: SizedBox(
              width: (screenWidth * 0.48).clamp(170.0, 280.0),
              child: _MiniCard(
                session: session,
                onClose: mini.close,
                onTogglePlay: mini.togglePlay,
              ),
            ),
          ),
        ),
      );
    });
  }
}

class _MiniCard extends StatelessWidget {
  const _MiniCard({
    required this.session,
    required this.onClose,
    required this.onTogglePlay,
  });

  final MiniVideoSession session;
  final VoidCallback onClose;
  final VoidCallback onTogglePlay;

  void _restore() => MusicPlayerScreen.open(session.videoId);

  @override
  Widget build(BuildContext context) {
    final video = session.video;
    return Material(
      color: Colors.black,
      elevation: 10,
      shadowColor: Colors.black,
      borderRadius: BorderRadius.circular(8),
      clipBehavior: Clip.antiAlias,
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: ValueListenableBuilder<VideoPlayerValue>(
          valueListenable: video,
          builder: (context, value, _) => Stack(
            fit: StackFit.expand,
            children: [
              if (value.isInitialized)
                FittedBox(
                  fit: BoxFit.cover,
                  clipBehavior: Clip.hardEdge,
                  child: SizedBox(
                    width: value.size.width,
                    height: value.size.height,
                    child: VideoPlayer(video),
                  ),
                ),
              // Tap anywhere else to open the full player.
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _restore,
                child: const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x66000000), Color(0x00000000)],
                      stops: [0, 0.5],
                    ),
                  ),
                ),
              ),
              // Centered; the buffering spinner takes its place.
              if (!(value.isBuffering && !value.isPlaying))
                Center(
                  child: _button(
                    icon: value.isPlaying
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    label: value.isPlaying ? 'Pause' : 'Play',
                    size: 34,
                    onTap: onTogglePlay,
                  ),
                ),
              Align(
                alignment: Alignment.topRight,
                child: _button(
                  icon: Icons.close_rounded,
                  label: 'Close',
                  size: 24,
                  onTap: onClose,
                ),
              ),
              if (value.isBuffering && !value.isPlaying)
                const Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
                ),
              Align(
                alignment: Alignment.bottomCenter,
                child: SizedBox(
                  height: 2,
                  child: VideoProgressIndicator(
                    video,
                    allowScrubbing: false,
                    padding: EdgeInsets.zero,
                    colors: const VideoProgressColors(
                      playedColor: kVideoAccent,
                      bufferedColor: Colors.white38,
                      backgroundColor: Colors.white12,
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

  Widget _button({
    required IconData icon,
    required String label,
    required double size,
    required VoidCallback onTap,
  }) {
    return InkResponse(
      onTap: onTap,
      radius: size,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Icon(
          icon,
          color: Colors.white,
          size: size,
          semanticLabel: label,
          shadows: const [Shadow(color: Colors.black54, blurRadius: 6)],
        ),
      ),
    );
  }
}
