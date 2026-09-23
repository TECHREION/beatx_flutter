import 'dart:math' as math;

/// The bands the equalizer screen always shows, in hertz.
///
/// Fixed on every platform on purpose. iOS runs our own `AUNBandEQ` on exactly
/// these frequencies, but Android hands back whatever the device's native
/// effect happens to expose — five bands on one handset, six or ten on the
/// next, at frequencies like 60/150/400/1k/2.4k/15k. Driving the UI off that
/// gave the two platforms visibly different screens and made a saved setting
/// meaningless on another device.
///
/// So the user always edits this curve, and [resampleCurve] projects it onto
/// whatever bands the hardware really has.
const kDisplayFrequenciesHz = <double>[
  31, 62, 125, 250, 500, 1000, 2000, 4000, 8000, 16000,
];

/// The range the screen offers, in decibels.
///
/// Matches the iOS engine exactly. Devices that accept less get the curve
/// clamped to their own range on the way down; devices that accept more simply
/// go unused, which costs nothing — past this, gain applied on top of already
/// mastered material mostly buys clipping.
const kDisplayMinDb = -12.0;
const kDisplayMaxDb = 12.0;

/// Resamples [gains], authored at [fromHz], onto [toHz].
///
/// Interpolation happens in log-frequency space, which is how the ear (and
/// every EQ axis) treats pitch: 31 Hz to 62 Hz is one octave, the same as 8 kHz
/// to 16 kHz, and interpolating linearly would badly skew the low end.
/// Frequencies outside the authored range hold the nearest endpoint rather than
/// extrapolating into nonsense.
///
/// [gains] and [fromHz] must be the same length, and [fromHz] must be
/// ascending — both hold for every curve in the app.
List<double> resampleCurve(
  List<double> gains, {
  required List<double> fromHz,
  required List<double> toHz,
}) {
  assert(
    gains.length == fromHz.length,
    'a curve needs one gain per authored frequency',
  );
  if (gains.isEmpty || toHz.isEmpty) return const [];
  return toHz
      .map((hz) => _interpolate(gains, fromHz, hz))
      .toList(growable: false);
}

double _interpolate(List<double> gains, List<double> fromHz, double hz) {
  if (hz <= fromHz.first) return gains.first;
  if (hz >= fromHz.last) return gains.last;

  final target = math.log(hz);
  for (var i = 0; i < fromHz.length - 1; i++) {
    final lowHz = fromHz[i];
    final highHz = fromHz[i + 1];
    if (hz < lowHz || hz > highHz) continue;

    final low = math.log(lowHz);
    final high = math.log(highHz);
    final t = (target - low) / (high - low);
    return gains[i] + (gains[i + 1] - gains[i]) * t;
  }
  return gains.last;
}

/// Clamps every gain into [min]..[max].
///
/// The service rejects an out-of-range gain rather than correcting it, so this
/// is where a curve is fitted to what a given device will actually accept.
List<double> clampCurve(List<double> gains, double min, double max) =>
    gains.map((gain) => gain.clamp(min, max).toDouble()).toList(growable: false);
