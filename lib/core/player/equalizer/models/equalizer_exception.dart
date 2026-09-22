/// Why an equalizer operation failed.
enum EqualizerErrorKind {
  /// The platform has no real equalizer. Nothing was changed and nothing will
  /// work — callers should hide the feature rather than retry.
  notSupported,

  /// The platform supports an equalizer but has not reported its bands yet.
  ///
  /// On Android the native effect is bound to the player's audio session,
  /// which only exists once a track has been loaded. Retry after playback
  /// starts.
  notReady,

  /// The band index is outside the range the device actually reports.
  invalidBandIndex,

  /// The gain is outside the device's supported decibel range.
  ///
  /// Deliberately an error rather than a silent clamp: a caller asking for a
  /// gain the hardware cannot produce has a bug, and quietly substituting a
  /// different value hides it.
  gainOutOfRange,

  /// The number of gains supplied does not match the device's band count.
  bandCountMismatch,

  /// The native effect could not be created or configured — the device
  /// exposes no `audiofx` implementation, or another app holds the effect.
  effectUnavailable,

  /// An unclassified failure crossing the platform boundary.
  platformError,
}

/// A failure raised by [EqualizerService].
///
/// Carries a machine-readable [kind] so callers can branch, plus a message
/// intended for logs rather than for users.
class EqualizerException implements Exception {
  const EqualizerException(this.kind, this.message, {this.cause});

  final EqualizerErrorKind kind;
  final String message;
  final Object? cause;

  const EqualizerException.notSupported()
      : this(
          EqualizerErrorKind.notSupported,
          'This platform does not provide a native equalizer.',
        );

  const EqualizerException.notReady()
      : this(
          EqualizerErrorKind.notReady,
          'The equalizer has no audio session yet. Start playback first.',
        );

  EqualizerException.invalidBandIndex(int index, int bandCount)
      : this(
          EqualizerErrorKind.invalidBandIndex,
          'Band index $index is out of range; the device reports $bandCount '
          'band(s).',
        );

  EqualizerException.gainOutOfRange(double gainDb, double minDb, double maxDb)
      : this(
          EqualizerErrorKind.gainOutOfRange,
          'Gain ${gainDb}dB is outside the device range '
          '${minDb}dB..${maxDb}dB.',
        );

  EqualizerException.bandCountMismatch(int supplied, int expected)
      : this(
          EqualizerErrorKind.bandCountMismatch,
          'Supplied $supplied gain(s) but the device reports $expected band(s).',
        );

  @override
  String toString() => 'EqualizerException(${kind.name}): $message';
}
