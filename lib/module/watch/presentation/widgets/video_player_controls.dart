import 'dart:async';

import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/common/widget/mini_player_host.dart';

/// The played part of the progress bar and its handle.
const kVideoAccent = Color(0xFFFF0033);

/// YouTube-style controls for the video player, passed to Chewie as
/// `customControls` so they are used in full screen too.
///
/// * tap shows/hides the controls; they hide again on their own while playing;
/// * double tap the left/right half to go back/forward [step];
/// * swipe down (or the chevron) minimizes into the mini player;
/// * the progress bar stays along the bottom edge even while hidden, and
///   can be dragged or tapped to seek.
class VideoPlayerControls extends StatefulWidget {
  const VideoPlayerControls({
    super.key,
    this.onMinimize,
    this.onNext,
    this.hasNext,
    this.autoPlay,
    this.step = const Duration(seconds: 10),
  });

  final VoidCallback? onMinimize;
  final VoidCallback? onNext;

  /// Read inside an Obx, so it may depend on observables (Up Next loading).
  final bool Function()? hasNext;

  /// The Up Next auto-play switch in the top bar; hidden when null.
  final RxBool? autoPlay;

  final Duration step;

  @override
  State<VideoPlayerControls> createState() => _VideoPlayerControlsState();
}

class _VideoPlayerControlsState extends State<VideoPlayerControls> {
  static const _autoHide = Duration(seconds: 3);

  ChewieController? _chewie;
  VideoPlayerController? _video;
  bool _wasPlaying = false;

  bool _visible = true;
  Timer? _hideTimer;

  /// Where the finger is while scrubbing (0..1), null otherwise.
  double? _dragFraction;

  /// Double-tap seek badge: -1 back, 1 forward, 0 nothing showing.
  int _seekDirection = 0;
  int _seekSeconds = 0;
  Timer? _seekBadgeTimer;
  Offset? _doubleTapAt;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final chewie = ChewieController.of(context);
    if (chewie == _chewie) return;
    _video?.removeListener(_onVideo);
    _chewie = chewie;
    _video = chewie.videoPlayerController..addListener(_onVideo);
    _wasPlaying = _video!.value.isPlaying;
    _scheduleHide();
  }

  @override
  void dispose() {
    _video?.removeListener(_onVideo);
    _hideTimer?.cancel();
    _seekBadgeTimer?.cancel();
    super.dispose();
  }

  void _onVideo() {
    if (!mounted) return;
    final playing = _video!.value.isPlaying;
    if (playing != _wasPlaying) {
      _wasPlaying = playing;
      // Paused (or ended): keep the controls up, as YouTube does.
      if (playing) {
        _scheduleHide();
      } else {
        _show(autoHide: false);
      }
    }
    setState(() {});
  }

  // ---- visibility ---------------------------------------------------------

  void _show({bool autoHide = true}) {
    _hideTimer?.cancel();
    if (!_visible) setState(() => _visible = true);
    if (autoHide) _scheduleHide();
  }

  void _scheduleHide() {
    _hideTimer?.cancel();
    if (!(_video?.value.isPlaying ?? false)) return;
    _hideTimer = Timer(_autoHide, () {
      if (mounted && _dragFraction == null) setState(() => _visible = false);
    });
  }

  void _toggleVisible() {
    if (_visible) {
      _hideTimer?.cancel();
      setState(() => _visible = false);
    } else {
      _show();
    }
  }

  // ---- actions ------------------------------------------------------------

  void _togglePlay() {
    final video = _video!;
    final value = video.value;
    if (!value.isInitialized) return;
    if (value.isPlaying) {
      video.pause();
    } else {
      if (value.position >= value.duration) video.seekTo(Duration.zero);
      video.play();
    }
    _show();
  }

  void _restart() {
    _video?.seekTo(Duration.zero);
    _show();
  }

  void _next() {
    final chewie = _chewie!;
    if (chewie.isFullScreen) chewie.exitFullScreen();
    widget.onNext?.call();
  }

  void _minimize() {
    final chewie = _chewie!;
    if (chewie.isFullScreen) {
      chewie.exitFullScreen();
    } else {
      widget.onMinimize?.call();
    }
  }

  void _seekBy(int direction) {
    final video = _video!;
    final value = video.value;
    if (!value.isInitialized) return;
    final target = value.position + widget.step * direction;
    video.seekTo(
      target < Duration.zero
          ? Duration.zero
          : (target > value.duration ? value.duration : target),
    );

    _seekBadgeTimer?.cancel();
    _seekBadgeTimer = Timer(const Duration(milliseconds: 700), () {
      if (mounted) setState(() => _seekDirection = 0);
    });
    setState(() {
      _seekSeconds = _seekDirection == direction
          ? _seekSeconds + widget.step.inSeconds
          : widget.step.inSeconds;
      _seekDirection = direction;
    });
  }

  Future<void> _openSettings() async {
    _hideTimer?.cancel();
    final chewie = _chewie!;
    final video = _video!;
    final current = video.value.playbackSpeed;
    final speed = await showModalBottomSheet<double>(
      context: context,
      backgroundColor: const Color(0xFF212121),
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(
                'Playback speed',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            for (final s in chewie.playbackSpeeds)
              ListTile(
                dense: true,
                leading: Icon(
                  Icons.check,
                  color: s == current ? Colors.white : Colors.transparent,
                ),
                title: Text(
                  s == 1 ? 'Normal' : '${_trim(s)}x',
                  style: const TextStyle(color: Colors.white),
                ),
                onTap: () => Navigator.of(context).pop(s),
              ),
          ],
        ),
      ),
    );
    if (speed != null) await video.setPlaybackSpeed(speed);
    if (mounted) _scheduleHide();
  }

  static String _trim(double s) =>
      s == s.roundToDouble() ? s.toInt().toString() : s.toString();

  // ---- scrubbing ----------------------------------------------------------

  double _fractionAt(Offset local, double width) =>
      (local.dx / width).clamp(0.0, 1.0);

  void _seekToFraction(double fraction) {
    final value = _video!.value;
    if (!value.isInitialized) return;
    _video!.seekTo(value.duration * fraction);
  }

  // ---- build --------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final chewie = _chewie!;
    final value = _video!.value;
    final fullScreen = chewie.isFullScreen;

    final controls = Stack(
      fit: StackFit.expand,
      clipBehavior: Clip.none,
      children: [
        // Taps, double taps and the swipe down to minimize.
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _toggleVisible,
          onDoubleTapDown: (d) => _doubleTapAt = d.localPosition,
          onDoubleTap: () {
            final at = _doubleTapAt;
            final width = context.size?.width ?? 0;
            if (at == null || width == 0) return;
            _seekBy(at.dx < width / 2 ? -1 : 1);
          },
          onVerticalDragEnd: (d) {
            if ((d.primaryVelocity ?? 0) > 300) _minimize();
          },
        ),

        // Dim the picture under the controls.
        IgnorePointer(
          child: AnimatedOpacity(
            opacity: _visible ? 1 : 0,
            duration: const Duration(milliseconds: 200),
            child: const ColoredBox(color: Color(0x66000000)),
          ),
        ),

        IgnorePointer(
          child: Row(
            children: [
              Expanded(child: _seekBadge(-1)),
              Expanded(child: _seekBadge(1)),
            ],
          ),
        ),

        IgnorePointer(
          ignoring: !_visible,
          child: AnimatedOpacity(
            opacity: _visible ? 1 : 0,
            duration: const Duration(milliseconds: 200),
            child: SafeArea(
              top: fullScreen,
              bottom: fullScreen,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Align(
                    alignment: Alignment.topCenter,
                    child: _topBar(fullScreen),
                  ),
                  Center(child: _centerControls(value)),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: _bottomBar(value, fullScreen),
                  ),
                ],
              ),
            ),
          ),
        ),

        Positioned(
          left: fullScreen ? 16 : 0,
          right: fullScreen ? 16 : 0,
          bottom: fullScreen ? 24 : 0,
          child: _progressBar(value),
        ),
      ],
    );

    // Chewie's full screen is a route of its own, where the audio mini
    // player would otherwise float over the video.
    return fullScreen ? MiniPlayerHidden(child: controls) : controls;
  }

  Widget _topBar(bool fullScreen) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
      child: Row(
        children: [
          _iconButton(
            icon: Icons.keyboard_arrow_down_rounded,
            size: 32,
            label: fullScreen ? 'Exit full screen' : 'Minimize',
            onPressed: _minimize,
          ),
          const Spacer(),
          if (widget.autoPlay != null)
            Obx(
              () => _AutoPlaySwitch(
                value: widget.autoPlay!.value,
                onChanged: (v) {
                  widget.autoPlay!.value = v;
                  _show();
                },
              ),
            ),
          _iconButton(
            icon: Icons.settings_outlined,
            label: 'Settings',
            onPressed: _openSettings,
          ),
        ],
      ),
    );
  }

  Widget _centerControls(VideoPlayerValue value) {
    final ended =
        value.isInitialized &&
        value.duration > Duration.zero &&
        !value.isPlaying &&
        value.position >= value.duration;
    final buffering = value.isBuffering && !value.isPlaying && !ended;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _roundButton(
          icon: Icons.skip_previous_rounded,
          size: 30,
          label: 'Restart',
          onPressed: _restart,
        ),
        const SizedBox(width: 40),
        SizedBox(
          width: 68,
          height: 68,
          child: buffering
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 3,
                  ),
                )
              : _roundButton(
                  icon: ended
                      ? Icons.replay_rounded
                      : (value.isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded),
                  size: 44,
                  label: value.isPlaying ? 'Pause' : 'Play',
                  onPressed: _togglePlay,
                ),
        ),
        const SizedBox(width: 40),
        Obx(() {
          final enabled =
              widget.onNext != null && (widget.hasNext?.call() ?? true);
          return _roundButton(
            icon: Icons.skip_next_rounded,
            size: 30,
            label: 'Next',
            onPressed: enabled ? _next : null,
          );
        }),
      ],
    );
  }

  Widget _bottomBar(VideoPlayerValue value, bool fullScreen) {
    final position = _dragFraction != null
        ? value.duration * _dragFraction!
        : value.position;
    return Padding(
      // Leaves room for the progress bar along the bottom edge.
      padding: EdgeInsets.fromLTRB(12, 0, 4, fullScreen ? 36 : 8),
      child: Row(
        children: [
          Text.rich(
            TextSpan(
              children: [
                TextSpan(text: _format(position)),
                TextSpan(
                  text: ' / ${_format(value.duration)}',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          _iconButton(
            icon: fullScreen
                ? Icons.fullscreen_exit_rounded
                : Icons.fullscreen_rounded,
            label: fullScreen ? 'Exit full screen' : 'Full screen',
            onPressed: () {
              _chewie!.toggleFullScreen();
              _show();
            },
          ),
        ],
      ),
    );
  }

  Widget _progressBar(VideoPlayerValue value) {
    final duration = value.duration.inMilliseconds;
    double fraction(Duration d) =>
        duration <= 0 ? 0 : (d.inMilliseconds / duration).clamp(0.0, 1.0);
    final played = _dragFraction ?? fraction(value.position);
    final buffered = value.buffered.isEmpty
        ? 0.0
        : fraction(value.buffered.last.end);
    final dragging = _dragFraction != null;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTapUp: (d) {
            _seekToFraction(_fractionAt(d.localPosition, width));
            _show();
          },
          onHorizontalDragStart: (d) {
            _hideTimer?.cancel();
            setState(() {
              _visible = true;
              _dragFraction = _fractionAt(d.localPosition, width);
            });
          },
          onHorizontalDragUpdate: (d) => setState(
            () => _dragFraction = _fractionAt(d.localPosition, width),
          ),
          onHorizontalDragEnd: (_) {
            final f = _dragFraction;
            setState(() => _dragFraction = null);
            if (f != null) _seekToFraction(f);
            _scheduleHide();
          },
          child: SizedBox(
            height: 20,
            child: CustomPaint(
              painter: _ProgressPainter(
                played: played,
                buffered: buffered,
                // The handle only shows with the controls, like YouTube.
                handleRadius: dragging ? 8 : (_visible ? 6 : 0),
                trackHeight: dragging ? 4 : 3,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _seekBadge(int direction) {
    final showing = _seekDirection == direction;
    return AnimatedOpacity(
      opacity: showing ? 1 : 0,
      duration: const Duration(milliseconds: 150),
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: direction < 0
              ? const BorderRadius.horizontal(right: Radius.circular(200))
              : const BorderRadius.horizontal(left: Radius.circular(200)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              direction < 0
                  ? Icons.fast_rewind_rounded
                  : Icons.fast_forward_rounded,
              color: Colors.white,
              size: 32,
            ),
            const SizedBox(height: 4),
            Text(
              '$_seekSeconds seconds',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _iconButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    double size = 26,
  }) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon, color: Colors.white, size: size, semanticLabel: label),
    );
  }

  Widget _roundButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    required double size,
  }) {
    return Material(
      color: Colors.black.withValues(alpha: 0.35),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: Padding(
          padding: EdgeInsets.all(size * 0.3),
          child: Icon(
            icon,
            size: size,
            semanticLabel: label,
            color: onPressed == null ? Colors.white38 : Colors.white,
          ),
        ),
      ),
    );
  }

  static String _format(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:${m.toString().padLeft(2, '0')}:$s' : '$m:$s';
  }
}

/// YouTube's auto-play toggle: a small pill whose thumb shows play/pause.
class _AutoPlaySwitch extends StatelessWidget {
  const _AutoPlaySwitch({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      toggled: value,
      label: 'Auto-play',
      button: true,
      child: GestureDetector(
        onTap: () => onChanged(!value),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 40,
            height: 16,
            decoration: BoxDecoration(
              color: value ? Colors.white54 : Colors.white24,
              borderRadius: BorderRadius.circular(8),
            ),
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 150),
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
              child: OverflowBox(
                maxHeight: 24,
                maxWidth: 24,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: value ? Colors.white : const Color(0xFF909090),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    value ? Icons.play_arrow_rounded : Icons.pause_rounded,
                    size: 16,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProgressPainter extends CustomPainter {
  _ProgressPainter({
    required this.played,
    required this.buffered,
    required this.handleRadius,
    required this.trackHeight,
  });

  final double played;
  final double buffered;
  final double handleRadius;
  final double trackHeight;

  @override
  void paint(Canvas canvas, Size size) {
    // The track hugs the bottom edge of the hit area.
    final y = size.height - trackHeight / 2;
    final paint = Paint()
      ..strokeWidth = trackHeight
      ..strokeCap = StrokeCap.butt;

    void line(double from, double to, Color color) {
      if (to <= from) return;
      canvas.drawLine(
        Offset(size.width * from, y),
        Offset(size.width * to, y),
        paint..color = color,
      );
    }

    line(0, 1, Colors.white24);
    line(0, buffered, Colors.white54);
    line(0, played, kVideoAccent);
    if (handleRadius > 0) {
      canvas.drawCircle(
        Offset(size.width * played, y),
        handleRadius,
        Paint()..color = kVideoAccent,
      );
    }
  }

  @override
  bool shouldRepaint(_ProgressPainter old) =>
      old.played != played ||
      old.buffered != buffered ||
      old.handleRadius != handleRadius ||
      old.trackHeight != trackHeight;
}
