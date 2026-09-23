import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Animated waveform for the player screen.
///
/// The bars bounce continuously while audio is playing and settle back to a
/// calm resting shape when paused. Bars left of the playback head are tinted
/// with the accent colour, the rest stay dim.
class LiveWaveform extends StatefulWidget {
  const LiveWaveform({
    super.key,
    required this.isPlaying,
    required this.progress,
    this.barCount = 20,
    this.height = 70,
    this.barWidth = 3,
    this.activeColor = const Color(0xFF9BFF4D),
    this.inactiveColor = Colors.white24,
  });

  final bool isPlaying;

  /// 0..1 playback progress, used only for the bar colouring.
  final double progress;

  final int barCount;
  final double height;
  final double barWidth;
  final Color activeColor;
  final Color inactiveColor;

  @override
  State<LiveWaveform> createState() => _LiveWaveformState();
}

class _LiveWaveformState extends State<LiveWaveform>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  );

  /// Per bar phase/speed offsets so no two bars move in lockstep.
  late List<double> _phases;
  late List<double> _speeds;

  /// Current and target heights, eased every frame so the motion stays fluid
  /// instead of jumping between random values.
  late List<double> _heights;

  /// 0 = paused (resting), 1 = playing (full bounce).
  double _energy = 0;

  @override
  void initState() {
    super.initState();
    _seedBars();
    _controller.addListener(_tick);
    if (widget.isPlaying) _controller.repeat();
  }

  void _seedBars() {
    final random = math.Random(7);
    _phases = List.generate(
      widget.barCount,
      (_) => random.nextDouble() * math.pi * 2,
    );
    _speeds = List.generate(
      widget.barCount,
      (_) => 1.6 + random.nextDouble() * 2.4,
    );
    _heights = List.filled(widget.barCount, widget.height * 0.18);
  }

  @override
  void didUpdateWidget(covariant LiveWaveform oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.barCount != oldWidget.barCount) _seedBars();
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        if (!_controller.isAnimating) _controller.repeat();
      }
      // When pausing we keep ticking until the bars have eased down, the
      // ticker stops itself inside _tick once the energy reaches zero.
    }
  }

  void _tick() {
    final target = widget.isPlaying ? 1.0 : 0.0;
    // Ramp up quickly, fade out a bit slower.
    _energy += (target - _energy) * (target > _energy ? 0.12 : 0.06);
    if (!widget.isPlaying && _energy < 0.01) {
      _energy = 0;
      _controller.stop();
    }

    final t = _controller.value * math.pi * 2;
    final minH = widget.height * 0.12;
    for (var i = 0; i < widget.barCount; i++) {
      // Two sines at different rates approximate the uneven bounce of a real
      // spectrum without needing FFT data.
      final wave =
          math.sin(t * _speeds[i] * 6 + _phases[i]) * 0.6 +
          math.sin(t * _speeds[i] * 2.3 + _phases[i] * 1.7) * 0.4;
      // Low frequencies (left side) swing harder, like a real spectrum.
      final tilt = 1.0 - (i / widget.barCount) * 0.45;
      final amplitude = ((wave + 1) / 2) * tilt;
      final target =
          minH + amplitude * (widget.height - minH) * _energy +
          (1 - _energy) * widget.height * 0.06;
      _heights[i] += (target - _heights[i]) * 0.25;
    }
    setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_tick);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeCount = (widget.progress.clamp(0.0, 1.0) * widget.barCount)
        .round();
    return SizedBox(
      height: widget.height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(widget.barCount, (i) {
          return Container(
            width: widget.barWidth,
            height: _heights[i],
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: i < activeCount ? widget.activeColor : widget.inactiveColor,
            ),
          );
        }),
      ),
    );
  }
}
