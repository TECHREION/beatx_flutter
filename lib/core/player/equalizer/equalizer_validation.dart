import 'models/equalizer_exception.dart';

/// Argument checks for equalizer operations.
///
/// Pure and platform-free so they can be exercised without a device, and
/// shared by every implementation so the rules cannot drift apart.
///
/// These throw rather than correct. Clamping a bad gain would produce audio
/// the caller did not ask for and hide the bug that produced it.
class EqualizerValidation {
  const EqualizerValidation._();

  /// Throws unless [bandIndex] addresses a band the device reports.
  static void bandIndex(int index, int bandCount) {
    if (index < 0 || index >= bandCount) {
      throw EqualizerException.invalidBandIndex(index, bandCount);
    }
  }

  /// Throws unless [gainDb] sits within the device's supported range.
  ///
  /// NaN is rejected explicitly: every comparison against it is false, so it
  /// would otherwise slip through a plain range check and reach the native
  /// effect.
  static void gain(double gainDb, double minDb, double maxDb) {
    if (gainDb.isNaN || gainDb < minDb || gainDb > maxDb) {
      throw EqualizerException.gainOutOfRange(gainDb, minDb, maxDb);
    }
  }

  /// Throws unless [gains] has one valid entry per band.
  ///
  /// Validates the whole vector before any of it is applied, so a bad value at
  /// the end cannot leave the equalizer half-written.
  static void gainVector(
    List<double> gains,
    int bandCount,
    double minDb,
    double maxDb,
  ) {
    if (gains.length != bandCount) {
      throw EqualizerException.bandCountMismatch(gains.length, bandCount);
    }
    for (final value in gains) {
      gain(value, minDb, maxDb);
    }
  }
}
