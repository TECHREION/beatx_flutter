import 'dart:ui';

import 'package:beatx_flutter/module/home/presentation/screens/audio_play_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../player/player_controller.dart';

class FloatingPlayer extends StatefulWidget {
  const FloatingPlayer({super.key});

  @override
  State<FloatingPlayer> createState() => _FloatingPlayerState();
}

class _FloatingPlayerState extends State<FloatingPlayer>
    with SingleTickerProviderStateMixin {
  late final PlayerController _ctrl;
  late final AnimationController _animCtrl;
  final List<Worker> _workers = [];

  bool _show = false;
  double _dragX = 0;
  bool _dismissing = false;

  @override
  void initState() {
    super.initState();
    _ctrl = Get.find<PlayerController>();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
    _show = _ctrl.title.value.isNotEmpty;

    // playCount increments on every play() call — fires even when the same
    // song is replayed after dismissal (avoids the equality-check race condition
    // that broke the audioAsset-based ever() listener).
    _workers.add(ever(_ctrl.playCount, (_) {
      if (!mounted) return;
      setState(() {
        _show = true;
        _dragX = 0;
        _dismissing = false;
      });
    }));

    // Hide only when the controller is fully stopped (title cleared).
    _workers.add(ever(_ctrl.title, (String t) {
      if (!mounted) return;
      if (t.isEmpty && _show && !_dismissing) setState(() => _show = false);
    }));
  }

  @override
  void dispose() {
    for (final w in _workers) {
      w.dispose();
    }
    _animCtrl.dispose();
    super.dispose();
  }

  void _onDragUpdate(DragUpdateDetails d) {
    if (_dismissing) return;
    setState(() => _dragX += d.delta.dx);
  }

  Future<void> _onDragEnd(DragEndDetails d) async {
    if (_dismissing) return;

    final velocity = d.velocity.pixelsPerSecond.dx;
    final screenW = MediaQuery.of(context).size.width;
    final shouldDismiss =
        _dragX.abs() > screenW * 0.3 || velocity.abs() > 700;

    if (shouldDismiss) {
      setState(() => _dismissing = true);
      final dir = (_dragX != 0 ? _dragX : velocity) > 0 ? 1.0 : -1.0;
      final startX = _dragX;
      final endX = dir * screenW * 1.5;

      _animCtrl.reset();
      void listener() {
        if (mounted) setState(() => _dragX = startX + (endX - startX) * _animCtrl.value);
      }
      _animCtrl.addListener(listener);
      await _animCtrl.animateTo(1, curve: Curves.easeOut);
      _animCtrl.removeListener(listener);

      if (mounted) {
        setState(() {
          _show = false;
          _dragX = 0;
          _dismissing = false;
        });
      }
      _ctrl.stop();
    } else {
      final startX = _dragX;
      _animCtrl.reset();
      void listener() {
        if (mounted) setState(() => _dragX = startX * (1 - _animCtrl.value));
      }
      _animCtrl.addListener(listener);
      await _animCtrl.animateTo(1, curve: Curves.easeOut);
      _animCtrl.removeListener(listener);
      if (mounted) setState(() => _dragX = 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_show) return const SizedBox.shrink();

    return GestureDetector(
      onHorizontalDragUpdate: _onDragUpdate,
      onHorizontalDragEnd: _onDragEnd,
      child: Transform.translate(
        offset: Offset(_dragX, 0),
        child: Obx(() => _buildPill()),
      ),
    );
  }

  Widget _buildPill() {
    final progress = _ctrl.duration.value.inMilliseconds > 0
        ? (_ctrl.position.value.inMilliseconds /
                _ctrl.duration.value.inMilliseconds)
            .clamp(0.0, 1.0)
        : 0.0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(50),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1C1C1F).withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(50),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.10),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    children: [
                      // Left side — tap to open PlayerScreen
                      Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => Get.to(
                            () => const PlayerScreen(),
                            transition: Transition.downToUp,
                            preventDuplicates: true,
                          ),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: SizedBox(
                                  width: 44,
                                  height: 44,
                                  child: Image.asset(
                                    _ctrl.imageAsset.value,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, err, trace) => Container(
                                      color: const Color(0xFF2A2A2D),
                                      child: const Icon(
                                        Icons.music_note_rounded,
                                        color: Colors.white54,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _ctrl.title.value,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0,
                                      ),
                                    ),
                                    Text(
                                      _ctrl.artist.value,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color:
                                            Colors.white.withValues(alpha: 0.55),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        letterSpacing: 0,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Playback controls
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: () {},
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                                minWidth: 32, minHeight: 32),
                            icon: const Icon(Icons.skip_previous_rounded,
                                color: Colors.white, size: 24),
                          ),
                          IconButton(
                            onPressed: () => _ctrl.isPlaying.value
                                ? _ctrl.pause()
                                : _ctrl.resume(),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                                minWidth: 36, minHeight: 36),
                            icon: Icon(
                              _ctrl.isPlaying.value
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          IconButton(
                            onPressed: () {},
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                                minWidth: 32, minHeight: 32),
                            icon: const Icon(Icons.skip_next_rounded,
                                color: Colors.white, size: 24),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Progress strip
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(50)),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 3,
                    backgroundColor: Colors.white.withValues(alpha: 0.12),
                    valueColor:
                        const AlwaysStoppedAnimation(Color(0xFF64FF8F)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
