import '../equalizer_curve.dart';

/// The frequencies the preset curves are authored against, in hertz.
///
/// The same frequencies the screen shows, so applying a preset is a straight
/// copy for the UI; [EqualizerPreset.gainsFor] resamples onto other bands when
/// the hardware needs different ones.
const kReferenceFrequenciesHz = kDisplayFrequenciesHz;

/// A named gain curve.
///
/// Authored to be clearly audible, not just correct: many Android devices have
/// five wide bands, and a phone speaker reproduces little below about 200 Hz,
/// so gentle curves measured at around 4 dB in practice and sounded unchanged.
/// That is also why the bass presets reach up to 250 Hz and 500 Hz.
///
/// Gains stay within +/-10 dB. Past that, gain on top of already-mastered
/// material mostly buys clipping and pumping.
enum EqualizerPreset {
  normal('Normal', [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]),
  acoustic('Acoustic', [6, 6, 4.5, 1.5, 2, 2, 3.5, 4.5, 4.5, 3]),
  bassBooster('Bass Booster', [10, 10, 9, 7, 3, 0, 0, 0, 0, 0]),
  bassReducer('Bass Reducer', [-10, -10, -9, -7, -3, 0, 0, 0, 0, 0]),
  classical('Classical', [6, 5, 4.5, 3.5, -2, -2, 0, 3, 4.5, 5]),
  dance('Dance', [7.5, 9, 6, 0, 3, 4.5, 6, 6, 4.5, 0]),
  deep('Deep', [7.5, 6, 3.5, 1.5, 4.5, 3, 1.5, -2, -4.5, -6]),
  electronic('Electronic', [7.5, 6.5, 1.5, 0, -3, 3, 1.5, 1.5, 6, 7.5]),
  hipHop('Hip Hop', [9, 7.5, 3, 4.5, -1.5, -1.5, 2, -1.5, 3, 4.5]),
  jazz('Jazz', [6, 4.5, 2, 3, -2, -2, 0, 2, 4.5, 6]),
  pop('Pop', [-3, -1.5, 0, 3, 6, 6, 3, 0, -1.5, -3]),
  rock('Rock', [9, 7.5, 5, 2, -1.5, -1.5, 1.5, 4.5, 6.5, 7.5]),
  vocal('Vocal', [-4.5, -3, -2, 3, 6, 6.5, 6, 3.5, 0, -2]),

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
  static EqualizerPreset fromId(String? id) =>
      values.firstWhere((preset) => preset.name == id, orElse: () => custom);

  /// Resamples this preset's curve onto [frequenciesHz].
  ///
  /// Throws [StateError] if called on [custom], which has no curve.
  List<double> gainsFor(List<double> frequenciesHz) {
    final curve = _curve;
    if (curve == null) {
      throw StateError('EqualizerPreset.custom has no curve to apply.');
    }
    return resampleCurve(
      curve,
      fromHz: kReferenceFrequenciesHz,
      toHz: frequenciesHz,
    );
  }
}
