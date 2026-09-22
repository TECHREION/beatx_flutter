/// One frequency band as reported by the platform.
///
/// Every value here comes from the device. Android decides how many bands
/// exist and where they sit — commonly five, at frequencies that are not the
/// textbook 31/62/.../16k — so nothing in the app may assume a band count or a
/// center frequency.
class EqualizerBand {
  const EqualizerBand({
    required this.index,
    required this.centerFrequencyHz,
    required this.gainDb,
  });

  /// Zero-based position of this band, as the platform indexes it.
  final int index;

  /// Center frequency in hertz, as reported by the device.
  final double centerFrequencyHz;

  /// Current gain in decibels.
  final double gainDb;

  /// Short axis label for this band's frequency, e.g. `31`, `1K`, `16K`.
  String get label {
    final hz = centerFrequencyHz;
    if (hz < 1000) return hz.round().toString();

    final kilohertz = hz / 1000.0;
    // Whole numbers read better without a trailing `.0` on a cramped axis.
    if ((kilohertz - kilohertz.roundToDouble()).abs() < 0.05) {
      return '${kilohertz.round()}K';
    }
    return '${kilohertz.toStringAsFixed(1)}K';
  }

  EqualizerBand copyWith({double? gainDb}) => EqualizerBand(
        index: index,
        centerFrequencyHz: centerFrequencyHz,
        gainDb: gainDb ?? this.gainDb,
      );

  @override
  String toString() =>
      'EqualizerBand(index: $index, ${centerFrequencyHz}Hz, ${gainDb}dB)';
}
