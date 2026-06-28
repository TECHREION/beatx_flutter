import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/player/player_controller.dart';
import '../../../home/presentation/screens/audio_play_screen.dart';

// ─── Preset data ─────────────────────────────────────────────────────────────

const _kFreqLabels = ['60 HZ', '150 HZ', '400 HZ', '1 KHZ', '2.4 KHZ', '15KHZ'];

const _kPresets = [
  'Bass Booster',
  'Classical',
  'Dance',
  'Flat',
  'Folk',
  'Heavy Metal',
  'Hip Hop',
  'Jazz',
  'Lounge',
  'Piano',
  'Pop',
  'R&B',
  'Rock',
  'Small Speakers',
  'Spoken Word',
  'Treble Reducer',
  'Vocal Booster',
];

// 6 values per preset — 0.0 = top (max boost), 1.0 = bottom (max cut)
const _kPresetGains = <String, List<double>>{
  'Bass Booster':   [0.10, 0.20, 0.45, 0.60, 0.60, 0.60],
  'Classical':      [0.20, 0.25, 0.45, 0.55, 0.35, 0.20],
  'Dance':          [0.15, 0.20, 0.50, 0.65, 0.45, 0.30],
  'Flat':           [0.50, 0.50, 0.50, 0.50, 0.50, 0.50],
  'Folk':           [0.35, 0.40, 0.45, 0.40, 0.35, 0.30],
  'Heavy Metal':    [0.10, 0.20, 0.65, 0.70, 0.55, 0.15],
  'Hip Hop':        [0.12, 0.18, 0.55, 0.65, 0.50, 0.30],
  'Jazz':           [0.25, 0.35, 0.48, 0.42, 0.30, 0.22],
  'Lounge':         [0.25, 0.38, 0.50, 0.55, 0.40, 0.28],
  'Piano':          [0.18, 0.28, 0.45, 0.38, 0.28, 0.20],
  'Pop':            [0.30, 0.40, 0.50, 0.45, 0.38, 0.33],
  'R&B':            [0.20, 0.30, 0.55, 0.60, 0.45, 0.25],
  'Rock':           [0.15, 0.25, 0.52, 0.62, 0.45, 0.18],
  'Small Speakers': [0.28, 0.38, 0.55, 0.65, 0.52, 0.42],
  'Spoken Word':    [0.45, 0.40, 0.35, 0.30, 0.40, 0.45],
  'Treble Reducer': [0.30, 0.35, 0.45, 0.55, 0.65, 0.75],
  'Vocal Booster':  [0.40, 0.35, 0.25, 0.28, 0.35, 0.40],
};

// ─── Screen ──────────────────────────────────────────────────────────────────

class EqualizerScreen extends StatefulWidget {
  const EqualizerScreen({super.key});

  @override
  State<EqualizerScreen> createState() => _EqualizerScreenState();
}

class _EqualizerScreenState extends State<EqualizerScreen> {
  int _selectedPreset = _kPresets.indexOf('Small Speakers');
  List<double> _gains = List<double>.from(_kPresetGains['Small Speakers']!);

  void _selectPreset(int index) {
    setState(() {
      _selectedPreset = index;
      _gains = List<double>.from(_kPresetGains[_kPresets[index]]!);
    });
  }

  void _updateGain(int band, double delta, double visHeight) {
    setState(() {
      _selectedPreset = -1;
      _gains[band] = (_gains[band] + delta / visHeight).clamp(0.0, 1.0);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0D12),
      body: SafeArea(
        child: Column(
          children: [
            _AppBar(onBack: () => Navigator.pop(context)),
            const SizedBox(height: 8),
            _EqSection(gains: _gains, onGainChanged: _updateGain),
            const SizedBox(height: 4),
            const _FreqLabels(),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: _kPresets.length,
                itemBuilder: (context, index) => _PresetTile(
                  label: _kPresets[index],
                  selected: _selectedPreset == index,
                  onTap: () => _selectPreset(index),
                ),
              ),
            ),
            const _MiniPlayer(),
          ],
        ),
      ),
    );
  }
}

// ─── App bar ─────────────────────────────────────────────────────────────────

class _AppBar extends StatelessWidget {
  const _AppBar({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          _CircleButton(icon: Icons.arrow_back_ios_rounded, onTap: onBack),
          const Expanded(
            child: Text(
              'Equalizer',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFFBD89FF),
                fontSize: 17,
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
              ),
            ),
          ),
          _CircleButton(icon: Icons.check_rounded, onTap: onBack),
        ],
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
          color: Color(0xFF2A2060),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }
}

// ─── EQ section ──────────────────────────────────────────────────────────────

class _EqSection extends StatelessWidget {
  const _EqSection({required this.gains, required this.onGainChanged});

  final List<double> gains;
  final void Function(int band, double delta, double visHeight) onGainChanged;

  static const double _visHeight = 200.0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _visHeight,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final xs = List.generate(6, (i) => 16.0 + (w - 32) * i / 5);

          return Stack(
            children: [
              // Background glow
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(0, 0.6),
                      radius: 0.9,
                      colors: [
                        const Color(0xFF1A3A2A).withValues(alpha: 0.6),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              // Curve
              CustomPaint(
                size: Size(w, _visHeight),
                painter: _EqPainter(gains: gains, xs: xs, height: _visHeight),
              ),
              // Draggable handles
              for (int i = 0; i < 6; i++)
                Positioned(
                  left: xs[i] - 13,
                  top: (gains[i] * _visHeight).clamp(0.0, _visHeight - 26),
                  child: GestureDetector(
                    onPanUpdate: (d) =>
                        onGainChanged(i, d.delta.dy, _visHeight),
                    child: const _EqHandle(),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

// ─── EQ Painter ──────────────────────────────────────────────────────────────

class _EqPainter extends CustomPainter {
  const _EqPainter({
    required this.gains,
    required this.xs,
    required this.height,
  });

  final List<double> gains;
  final List<double> xs;
  final double height;

  @override
  void paint(Canvas canvas, Size size) {
    // Guide lines
    final guidePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..strokeWidth = 1;
    for (final x in xs) {
      canvas.drawLine(Offset(x, 0), Offset(x, height), guidePaint);
    }

    // Centre line
    canvas.drawLine(
      Offset(0, height / 2),
      Offset(size.width, height / 2),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.06)
        ..strokeWidth = 1,
    );

    final pts = List.generate(
      6,
      (i) => Offset(xs[i], (gains[i] * height).clamp(2.0, height - 2.0)),
    );

    // Gradient fill
    final fillPath = _curvePath(pts)
      ..lineTo(pts.last.dx, height)
      ..lineTo(pts.first.dx, height)
      ..close();

    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF7B3FE4).withValues(alpha: 0.55),
            const Color(0xFF3B1F8C).withValues(alpha: 0.30),
            Colors.transparent,
          ],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(Rect.fromLTWH(0, 0, size.width, height)),
    );

    final stroke = _curvePath(pts);

    // Glow
    canvas.drawPath(
      stroke,
      Paint()
        ..color = const Color(0xFF9B6FFF).withValues(alpha: 0.35)
        ..strokeWidth = 8
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    // Main line
    canvas.drawPath(
      stroke,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.90)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  Path _curvePath(List<Offset> pts) {
    final path = Path()..moveTo(pts[0].dx, pts[0].dy);
    for (int i = 0; i < pts.length - 1; i++) {
      final cx = (pts[i].dx + pts[i + 1].dx) / 2;
      path.cubicTo(cx, pts[i].dy, cx, pts[i + 1].dy,
          pts[i + 1].dx, pts[i + 1].dy);
    }
    return path;
  }

  @override
  bool shouldRepaint(_EqPainter old) =>
      old.gains != gains || old.xs != xs;
}

// ─── Draggable handle ────────────────────────────────────────────────────────

class _EqHandle extends StatelessWidget {
  const _EqHandle();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.85),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF9B6FFF).withValues(alpha: 0.6),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: 9,
          height: 9,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFFBD89FF),
          ),
        ),
      ),
    );
  }
}

// ─── Frequency labels ────────────────────────────────────────────────────────

class _FreqLabels extends StatelessWidget {
  const _FreqLabels();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final label in _kFreqLabels)
          Expanded(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.45),
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 0,
              ),
            ),
          ),
      ],
    );
  }
}

// ─── Preset tile ─────────────────────────────────────────────────────────────

class _PresetTile extends StatelessWidget {
  const _PresetTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          border: selected
              ? Border.all(color: const Color(0xFF40DDEB), width: 1.5)
              : const Border(
                  bottom: BorderSide(color: Color(0xFF1E1E24), width: 1),
                ),
          color: selected
              ? Colors.white.withValues(alpha: 0.03)
              : Colors.transparent,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: selected
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.85),
                  fontSize: 16,
                  fontWeight:
                      selected ? FontWeight.w700 : FontWeight.w500,
                  letterSpacing: 0,
                ),
              ),
            ),
            if (selected)
              const Icon(Icons.check_rounded, color: Colors.white, size: 20),
          ],
        ),
      ),
    );
  }
}

// ─── Mini player ─────────────────────────────────────────────────────────────

class _MiniPlayer extends StatelessWidget {
  const _MiniPlayer();

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<PlayerController>();

    return Obx(() {
      if (ctrl.title.value.isEmpty) return const SizedBox.shrink();

      final progress = ctrl.duration.value.inMilliseconds > 0
          ? (ctrl.position.value.inMilliseconds /
                  ctrl.duration.value.inMilliseconds)
              .clamp(0.0, 1.0)
          : 0.0;

      return GestureDetector(
        onTap: () => Get.to(
          () => const PlayerScreen(),
          transition: Transition.downToUp,
          preventDuplicates: true,
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xFF111318),
            border: Border(
              top: BorderSide(color: Color(0xFF1E2128), width: 1),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        width: 46,
                        height: 46,
                        child: Image.asset(
                          ctrl.imageAsset.value,
                          fit: BoxFit.cover,
                          errorBuilder: (_, err, trace) => Container(
                            color: const Color(0xFF2A2A2D),
                            child: const Icon(
                              Icons.music_note_rounded,
                              color: Colors.white38,
                              size: 22,
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
                            ctrl.title.value,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            ctrl.artist.value,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.50),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.bluetooth_rounded,
                      color: Color(0xFF40DDEB),
                      size: 22,
                    ),
                    const SizedBox(width: 16),
                    GestureDetector(
                      onTap: () => ctrl.isPlaying.value
                          ? ctrl.pause()
                          : ctrl.resume(),
                      child: Icon(
                        ctrl.isPlaying.value
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ],
                ),
              ),
              _ProgressBar(progress: progress.toDouble()),
            ],
          ),
        ),
      );
    });
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final scrubX = (w * progress).clamp(6.0, w - 6.0);

        return SizedBox(
          height: 20,
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              Container(height: 2, color: Colors.white.withValues(alpha: 0.15)),
              Container(
                height: 2,
                width: w * progress,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF40DDEB), Color(0xFF9B6FFF)],
                  ),
                ),
              ),
              Positioned(
                left: scrubX - 6,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
