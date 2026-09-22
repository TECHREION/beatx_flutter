import 'dart:math' as math;

/// The frequencies the preset curves are authored against, in hertz.
///
/// These are reference points only. They are **not** the bands the app
/// displays or drives — the device decides those. [EqualizerPreset.gainsFor]
/// resamples a curve onto whatever the device actually reports.
const kReferenceFrequenciesHz = <double>[
  31, 62, 125, 250, 500, 1000, 2000, 4000, 8000, 16000,
];

/// A named gain curve.
///
/// Gains are kept within ±8 dB even though most devices allow more. Preset
/// curves are applied on top of already-mastered material, so the extra
/// headroom mainly buys clipping and pumping rather than a better sound.
enum EqualizerPreset {
  normal('Normal', [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]),
  acoustic('Acoustic', [4, 4, 3, 1, 1.5, 1.5, 2.5, 3, 3, 2]),
  bassBooster('Bass Booster', [7, 6, 5, 3, 1, 0, 0, 0, 0, 0]),
  bassReducer('Bass Reducer', [-7, -6, -5, -3, -1, 0, 0, 0, 0, 0]),
  classical('Classical', [4, 3.5, 3, 2.5, -1.5, -1.5, 0, 2, 3, 3.5]),
  dance('Dance', [5, 6, 4, 0, 2, 3, 4, 4, 3, 0]),
  deep('Deep', [5, 4, 2.5, 1, 3, 2, 1, -1.5, -3, -4]),
  electronic('Electronic', [5, 4.5, 1, 0, -2, 2, 1, 1, 4, 5]),
  hipHop('Hip Hop', [6, 5, 2, 3, -1, -1, 1.5, -1, 2, 3]),
  jazz('Jazz', [4, 3, 1.5, 2, -1.5, -1.5, 0, 1.5, 3, 4]),
  pop('Pop', [-2, -1, 0, 2, 4, 4, 2, 0, -1, -2]),
  rock('Rock', [6, 5, 3.5, 1.5, -1, -1, 1, 3, 4.5, 5]),
  vocal('Vocal', [-3, -2, -1.5, 2, 4, 4.5, 4, 2.5, 0, -1.5]),

  /// Not a curve: the marker for gains the user has edited by hand.
  custom('Custom', null);

  const EqualizerPreset(this.displayName, this._curve);

  final String displayName;
  final List<double>? _curve;

  /// The authored curve, or null for [custom].
  List<double>? get referenceCurve => _curve;

  /// Whether this preset carries a curve that can be applied.
  bool get hasCurve => _curve != null;

  /// Every preset the UI offers, in display order, excluding [custom].
  static List<EqualizerPreset> get selectable =>
      values.where((preset) => preset.hasCurve).toList(growable: false);

  /// Resolves a stored [id] back to a preset, falling back to [custom] so a
  /// renamed or removed preset can never break restoration.
  static EqualizerPreset fromId(String? id) => values.firstWhere(
        (preset) => preset.name == id,
        orElse: () => custom,
      );

  /// Resamples this preset's curve onto [frequenciesHz].
  ///
  /// Interpolation happens in log-frequency space, which is how the ear (and
  /// every EQ axis) treats pitch: the gap from 31 Hz to 62 Hz is one octave,
  /// the same as 8 kHz to 16 kHz, and linear interpolation would badly skew
  /// the low end. Frequencies outside the reference range hold the nearest
  /// endpoint value rather than extrapolating into nonsense.
  ///
  /// Throws [StateError] if called on [custom], which has no curve.
  List<double> gainsFor(List<double> frequenciesHz) {
    final curve = _curve;
    if (curve == null) {
      throw StateError('EqualizerPreset.custom has no curve to apply.');
    }
    return frequenciesHz
        .map((hz) => _interpolate(curve, hz))
        .toList(growable: false);
  }

  static double _interpolate(List<double> curve, double hz) {
    if (hz <= kReferenceFrequenciesHz.first) return curve.first;
    if (hz >= kReferenceFrequenciesHz.last) return curve.last;

    final target = math.log(hz);
    for (var i = 0; i < kReferenceFrequenciesHz.length - 1; i++) {
      final lowHz = kReferenceFrequenciesHz[i];
      final highHz = kReferenceFrequenciesHz[i + 1];
      if (hz < lowHz || hz > highHz) continue;

      final low = math.log(lowHz);
      final high = math.log(highHz);
      final t = (target - low) / (high - low);
      return curve[i] + (curve[i + 1] - curve[i]) * t;
    }
    return curve.last;
  }
}
