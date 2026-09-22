import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/player/equalizer/equalizer_controller.dart';
import '../../../../core/player/equalizer/equalizer_service_ios.dart';
import '../../../../core/player/equalizer/models/equalizer_band.dart';
import '../../../../core/player/equalizer/models/equalizer_preset.dart';
import '../../../../core/theme/responsive.dart';

const _kPageBackground = Color(0xFF07060B);
const _kCardBackground = Color(0xFF131218);
const _kAccent = Color(0xFFA855F7);
const _kNodeAccent = Color(0xFF22D3EE);
const _kCurve = Color(0xFFCBB2F7);

/// The equalizer.
///
/// Everything shown here is driven by what the platform actually reports: the
/// number of nodes on the curve, their frequency labels and the gain range all
/// come from [EqualizerController.bands] and the device's min/max. Nothing is
/// hardcoded, because Android decides its own band layout and lying about it
/// would mean labelling a point 31 Hz while it moves something else.
///
/// When the device has no equalizer, this screen is never reachable — the
/// entry points are hidden rather than showing controls that do nothing.
class EqualizerScreen extends StatelessWidget {
  const EqualizerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = EqualizerController.instance;

    return Scaffold(
      backgroundColor: _kPageBackground,
      body: Stack(
        children: [
          // The glow sits behind everything so the curve reads as lit from
          // within rather than drawn on a flat panel.
          const Positioned.fill(child: _TopGlow()),
          SafeArea(
            child: Column(
              children: [
                const _TopBar(),
                Expanded(
                  child: Obx(() {
                    if (!controller.isSupported.value) {
                      return const _MessageState(
                        icon: Icons.graphic_eq,
                        title: 'Not available on this device',
                        message:
                            'This platform does not provide an audio equalizer '
                            'that can change what you hear.',
                      );
                    }
                    if (!controller.isReady.value) {
                      // Two genuinely different situations, so say which one it
                      // is rather than showing one vague message.
                      return switch (controller.unavailableReason.value) {
                        EqualizerUnavailableReason.incompatibleStream =>
                          const _MessageState(
                            icon: Icons.graphic_eq,
                            title: 'Not available for this track',
                            message:
                                'The equalizer processes the audio as it plays, '
                                "and this track's streaming format does not "
                                'expose an audio track it can attach to.',
                          ),
                        _ => const _MessageState(
                            icon: Icons.play_circle_outline,
                            title: 'Start playing something',
                            message:
                                'The equalizer attaches to the audio being '
                                'played, so it becomes available once a track '
                                'is running.',
                          ),
                      };
                    }
                    return _EqualizerBody(controller: controller);
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Back on the left, title in the middle, done on the right — both buttons as
/// circular glyphs so they sit on the glow instead of boxing it in.
class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(context.pageInset, 8, context.pageInset, 4),
      child: Row(
        children: [
          _CircleButton(
            icon: Icons.arrow_back,
            onTap: Get.back,
            tooltip: 'Back',
          ),
          const Expanded(
            child: Text(
              'Equalizer',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _kAccent,
                fontSize: 19,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          _CircleButton(
            icon: Icons.check,
            onTap: Get.back,
            tooltip: 'Done',
          ),
        ],
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({
    required this.icon,
    required this.onTap,
    required this.tooltip,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: const Color(0xFF1C1B24),
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            width: 40,
            height: 40,
            child: Icon(icon, color: Colors.white, size: 20),
          ),
        ),
      ),
    );
  }
}

/// A soft purple wash behind the top of the screen.
class _TopGlow extends StatelessWidget {
  const _TopGlow();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -0.85),
          radius: 1.1,
          colors: [Color(0x332F1065), Color(0x00000000)],
        ),
      ),
    );
  }
}

class _EqualizerBody extends StatelessWidget {
  const _EqualizerBody({required this.controller});

  final EqualizerController controller;

  @override
  Widget build(BuildContext context) {
    return ContentWidth(
      maxWidth: 720,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CurveEditor(controller: controller),
          _AxisLabels(controller: controller),
          _ControlRow(controller: controller),
          _ErrorBanner(controller: controller),
          const SizedBox(height: 4),
          const Divider(height: 1, color: Color(0xFF1E1D25)),
          // The curve stays put while the preset list scrolls under it, which
          // is what makes picking a preset and watching the curve answer the
          // same gesture.
          Expanded(child: _PresetList(controller: controller)),
        ],
      ),
    );
  }
}

/// The curve itself: one draggable node per device band.
class _CurveEditor extends StatefulWidget {
  const _CurveEditor({required this.controller});

  final EqualizerController controller;

  @override
  State<_CurveEditor> createState() => _CurveEditorState();
}

class _CurveEditorState extends State<_CurveEditor> {
  /// Keeps the node grabbed at pan start under the finger for the whole drag,
  /// so a steep curve cannot hand the gesture to a neighbour mid-stroke.
  int? _dragIndex;

  /// Room for a node to sit at the very top or bottom of the range without
  /// its ring being clipped by the canvas edge.
  static const _nodeInset = 12.0;
  static const _height = 190.0;

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;

    return Obx(() {
      final bands = controller.bands;
      if (bands.isEmpty) return const SizedBox(height: _height);

      // Dimming rather than hiding: the layout must not jump when the
      // equalizer is switched off, and the curve stays readable either way.
      final enabled = controller.enabled.value;

      return Padding(
        padding: EdgeInsets.symmetric(horizontal: context.pageInset),
        child: AnimatedOpacity(
          opacity: enabled ? 1 : 0.4,
          duration: const Duration(milliseconds: 150),
          child: SizedBox(
            height: _height,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final geometry = _CurveGeometry(
                  size: Size(constraints.maxWidth, _height),
                  inset: _nodeInset,
                  count: bands.length,
                  minDb: controller.minDb,
                  maxDb: controller.maxDb,
                );

                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onPanDown: enabled
                      ? (details) => _dragIndex =
                          geometry.nearestIndex(details.localPosition.dx)
                      : null,
                  onPanUpdate: enabled
                      ? (details) => _onDrag(geometry, details.localPosition)
                      : null,
                  onPanEnd: enabled ? (_) => _endDrag() : null,
                  onPanCancel: enabled ? _endDrag : null,
                  // A tap is a drag with no movement: still move the node
                  // there, because tapping the curve and having nothing happen
                  // is the wrong answer.
                  onTapDown: enabled
                      ? (details) {
                          _dragIndex =
                              geometry.nearestIndex(details.localPosition.dx);
                          _onDrag(geometry, details.localPosition);
                        }
                      : null,
                  onTapUp: enabled ? (_) => _endDrag() : null,
                  child: CustomPaint(
                    painter: _CurvePainter(
                      gains: [for (final band in bands) band.gainDb],
                      geometry: geometry,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );
    });
  }

  void _onDrag(_CurveGeometry geometry, Offset position) {
    final index = _dragIndex;
    if (index == null) return;
    widget.controller.previewGain(index, geometry.gainAt(position.dy));
  }

  void _endDrag() {
    final index = _dragIndex;
    _dragIndex = null;
    if (index == null) return;
    final bands = widget.controller.bands;
    if (index >= bands.length) return;
    // Flush the last position out of the write throttle and persist it.
    widget.controller.commitGain(index, bands[index].gainDb);
  }
}

/// Maps between gains and pixels for the curve, in one place, so the painter
/// and the gesture handler can never disagree about where a node is.
class _CurveGeometry {
  _CurveGeometry({
    required this.size,
    required this.inset,
    required this.count,
    required this.minDb,
    required this.maxDb,
  });

  final Size size;
  final double inset;
  final int count;
  final double minDb;
  final double maxDb;

  double get _plotHeight => size.height - inset * 2;
  double get _plotWidth => size.width - inset * 2;

  double xFor(int index) =>
      count == 1 ? size.width / 2 : inset + _plotWidth * index / (count - 1);

  double yFor(double gainDb) {
    final range = maxDb - minDb;
    // A device reporting a zero range would otherwise divide by zero; park the
    // curve in the middle, which is the only honest place for it.
    if (range <= 0) return size.height / 2;
    final t = (gainDb.clamp(minDb, maxDb) - minDb) / range;
    return inset + _plotHeight * (1 - t);
  }

  /// The gain a finger at [dy] is asking for, clamped to what the device takes.
  double gainAt(double dy) {
    if (_plotHeight <= 0) return minDb;
    final t = 1 - ((dy - inset) / _plotHeight).clamp(0.0, 1.0);
    return minDb + (maxDb - minDb) * t;
  }

  int nearestIndex(double dx) {
    if (count <= 1) return 0;
    final step = _plotWidth / (count - 1);
    if (step <= 0) return 0;
    return (((dx - inset) / step).round()).clamp(0, count - 1);
  }
}

class _CurvePainter extends CustomPainter {
  const _CurvePainter({required this.gains, required this.geometry});

  final List<double> gains;
  final _CurveGeometry geometry;

  @override
  void paint(Canvas canvas, Size size) {
    if (gains.isEmpty) return;

    final points = <Offset>[
      for (var i = 0; i < gains.length; i++)
        Offset(geometry.xFor(i), geometry.yFor(gains[i])),
    ];

    _paintBaseline(canvas, size);

    final line = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      line.lineTo(point.dx, point.dy);
    }

    // The fill runs to the canvas edges rather than to the first and last
    // node, so the band of colour reads as a continuous spectrum.
    final fill = Path.from(line)
      ..lineTo(size.width, points.last.dy)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..lineTo(0, points.first.dy)
      ..close();

    canvas.drawPath(
      fill,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xCC7B2FD4), Color(0x14591C9E)],
        ).createShader(Offset.zero & size),
    );

    canvas.drawPath(
      line,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = _kCurve,
    );

    for (final point in points) {
      _paintNode(canvas, point);
    }
  }

  /// A faint 0 dB line, so "flat" is something you can see rather than infer.
  void _paintBaseline(Canvas canvas, Size size) {
    final y = geometry.yFor(0);
    canvas.drawLine(
      Offset(0, y),
      Offset(size.width, y),
      Paint()
        ..strokeWidth = 1
        ..color = Colors.white.withValues(alpha: 0.06),
    );
  }

  void _paintNode(Canvas canvas, Offset center) {
    canvas.drawCircle(
      center,
      9,
      Paint()..color = _kNodeAccent.withValues(alpha: 0.22),
    );
    canvas.drawCircle(center, 6, Paint()..color = _kNodeAccent);
    canvas.drawCircle(center, 3.2, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(_CurvePainter old) =>
      !listEquals(old.gains, gains) || old.geometry.size != geometry.size;

  static bool listEquals(List<double> a, List<double> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// Frequency labels under the curve, one per node, aligned to the same x
/// positions the painter uses.
class _AxisLabels extends StatelessWidget {
  const _AxisLabels({required this.controller});

  final EqualizerController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final bands = controller.bands;
      if (bands.isEmpty) return const SizedBox.shrink();

      return Padding(
        padding: EdgeInsets.fromLTRB(context.pageInset, 6, context.pageInset, 0),
        child: Row(
          children: [
            for (final band in bands)
              Expanded(
                child: Text(
                  _axisLabel(band),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.clip,
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 10,
                    letterSpacing: 0.4,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }

  static String _axisLabel(EqualizerBand band) =>
      band.centerFrequencyHz < 1000 ? '${band.label} HZ' : '${band.label}HZ';
}

/// On/off and reset, kept as one quiet row so the curve and the presets stay
/// the things you look at.
class _ControlRow extends StatelessWidget {
  const _ControlRow({required this.controller});

  final EqualizerController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final enabled = controller.enabled.value;

      return Padding(
        padding:
            EdgeInsets.fromLTRB(context.pageInset, 10, context.pageInset, 10),
        child: Row(
          children: [
            _TogglePill(
              enabled: enabled,
              onTap: () => controller.setEnabled(!enabled),
            ),
            const Spacer(),
            TextButton(
              onPressed: enabled ? controller.reset : null,
              style: TextButton.styleFrom(
                foregroundColor: Colors.white70,
                disabledForegroundColor: Colors.white24,
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              child: const Text('Reset'),
            ),
          ],
        ),
      );
    });
  }
}

class _TogglePill extends StatelessWidget {
  const _TogglePill({required this.enabled, required this.onTap});

  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: enabled ? _kAccent.withValues(alpha: 0.18) : _kCardBackground,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.power_settings_new,
                size: 16,
                color: enabled ? _kAccent : Colors.white38,
              ),
              const SizedBox(width: 8),
              Text(
                enabled ? 'On' : 'Off',
                style: TextStyle(
                  color: enabled ? Colors.white : Colors.white54,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The preset list: one row each, the active one outlined and ticked.
class _PresetList extends StatelessWidget {
  const _PresetList({required this.controller});

  final EqualizerController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final current = controller.currentPreset.value;
      final enabled = controller.enabled.value;

      // Custom is shown only once the user has actually made the gains their
      // own; it is a state, not something to pick.
      final presets = <EqualizerPreset>[
        if (current == EqualizerPreset.custom) EqualizerPreset.custom,
        ...EqualizerPreset.selectable,
      ];

      return ListView.builder(
        padding: EdgeInsets.only(top: 4, bottom: 24 + context.pageInset),
        itemCount: presets.length,
        itemBuilder: (context, index) {
          final preset = presets[index];
          return _PresetRow(
            label: preset.displayName,
            selected: preset == current,
            onTap: enabled && preset.hasCurve
                ? () => controller.selectPreset(preset)
                : null,
          );
        },
      );
    });
  }
}

class _PresetRow extends StatelessWidget {
  const _PresetRow({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.pageInset, vertical: 2),
      child: Material(
        color: selected ? _kNodeAccent.withValues(alpha: 0.06) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: selected ? _kNodeAccent : Colors.transparent,
                width: 1.2,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: onTap == null && !selected
                          ? Colors.white38
                          : Colors.white,
                      fontSize: 15,
                      fontWeight:
                          selected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
                if (selected)
                  const Icon(Icons.check, color: _kNodeAccent, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.controller});

  final EqualizerController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final message = controller.errorMessage.value;
      if (message == null) return const SizedBox.shrink();
      return Padding(
        padding:
            EdgeInsets.fromLTRB(context.pageInset, 0, context.pageInset, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.error_outline, color: _kAccent, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _MessageState extends StatelessWidget {
  const _MessageState({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: context.pageInset + 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white38, size: 44),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white54, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
