import 'models/equalizer_band.dart';

/// Platform-facing equalizer API.
///
/// This layer owns the native effect and nothing else: bands, gains, the
/// enabled flag and the device's capabilities. Presets, "custom" detection,
/// persistence and UI throttling belong to `EqualizerController`, so that this
/// interface stays a thin, testable mirror of what the platform can actually
/// do.
///
/// Every method that changes the effect throws [EqualizerException] rather
/// than correcting a bad argument, so mistakes surface instead of silently
/// producing different audio than the caller asked for.
abstract class EqualizerService {
  /// Whether this platform can host a real equalizer.
  ///
  /// False means the feature should be hidden entirely — there is no partial
  /// or UI-only mode.
  bool get isSupported;

  /// Whether the device has reported its bands yet.
  ///
  /// On Android the native effect attaches to the player's audio session,
  /// which does not exist until a track has been loaded. Until then there are
  /// no bands to show and no gains to set.
  bool get isReady;

  /// The device's bands with their current gains. Empty until [isReady].
  List<EqualizerBand> get bands;

  /// Lowest gain the device accepts, in decibels. Zero until [isReady].
  double get minDb;

  /// Highest gain the device accepts, in decibels. Zero until [isReady].
  double get maxDb;

  /// Whether the effect is currently modifying the audio signal.
  bool get isEnabled;

  /// Prepares the service and begins band discovery.
  ///
  /// Returns as soon as discovery is under way; it does not wait for a track
  /// to start. Await [whenReady] if you need the bands themselves.
  Future<void> initialize();

  /// Completes once the device has reported its bands.
  ///
  /// Will not complete until playback has started at least once. Callers that
  /// must stay responsive should check [isReady] instead of awaiting this.
  Future<void> whenReady();

  /// Turns the effect on or off. Safe to call before [isReady]; the value is
  /// applied when the effect attaches.
  Future<void> setEnabled(bool enabled);

  /// Center frequencies reported by the device, in hertz.
  List<double> getBandFrequencies();

  /// Current gains, one per device band, in decibels.
  List<double> getBandGains();

  /// Sets one band's gain.
  ///
  /// Throws if [bandIndex] is not a band the device reports, or if [gainDb]
  /// falls outside [minDb]..[maxDb].
  Future<void> setBandGain(int bandIndex, double gainDb);

  /// Sets every band at once. [gains] must have exactly one entry per band.
  Future<void> setAllBandGains(List<double> gains);

  /// Returns every band to 0 dB. Does not change the enabled flag.
  Future<void> reset();

  /// Releases anything this service owns.
  ///
  /// The native effect itself is owned by the player's audio pipeline and is
  /// released when the player is disposed.
  void dispose();
}
