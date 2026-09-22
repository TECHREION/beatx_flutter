import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import 'equalizer_service.dart';
import 'equalizer_validation.dart';
import 'models/equalizer_band.dart';
import 'models/equalizer_exception.dart';

/// Drives the native equalizer that just_audio attaches to the player's
/// audio pipeline.
///
/// ## Android
/// just_audio creates an `android.media.audiofx.Equalizer` bound to
/// ExoPlayer's own audio session id, and re-creates it whenever that session
/// changes (player recreation, some route changes). Gains are restored onto
/// the new effect automatically, so nothing here has to track sessions.
/// Changing a gain calls `setBandLevel` on the live effect — the player is
/// never rebuilt and audio never glitches.
///
/// ## iOS / everything else
/// [isSupported] is false. `AVAudioUnitEQ` belongs to `AVAudioEngine`, which
/// cannot be composed with the `AVPlayer` that just_audio uses on Darwin, so
/// there is no honest way to process the signal here yet. The service refuses
/// every operation rather than presenting controls that do nothing.
class EqualizerServiceImpl implements EqualizerService {
  EqualizerServiceImpl(this._equalizer);

  final AndroidEqualizer _equalizer;

  final _readyCompleter = Completer<void>();

  /// Held once discovered so a gain write does not go through a Future on
  /// every slider movement.
  AndroidEqualizerParameters? _parameters;
  List<EqualizerBand> _bands = const [];
  double _minDb = 0;
  double _maxDb = 0;
  bool _enabled = false;
  bool _initialized = false;

  /// Cached because `Platform` throws on web and this is read on every build.
  static final bool _platformSupported = !kIsWeb && Platform.isAndroid;

  @override
  bool get isSupported => _platformSupported;

  @override
  bool get isReady => _readyCompleter.isCompleted;

  @override
  List<EqualizerBand> get bands => _bands;

  @override
  double get minDb => _minDb;

  @override
  double get maxDb => _maxDb;

  @override
  bool get isEnabled => _enabled;

  @override
  Future<void> initialize() async {
    if (!isSupported || _initialized) return;
    _initialized = true;
    // Deliberately not awaited. just_audio completes `parameters` only when
    // the effect attaches to a live audio session, which happens on the first
    // setUrl/setAsset. Awaiting here would hang until the user plays
    // something — possibly forever.
    unawaited(_discoverBands());
  }

  Future<void> _discoverBands() async {
    try {
      final parameters = await _equalizer.parameters;
      _parameters = parameters;
      _minDb = parameters.minDecibels;
      _maxDb = parameters.maxDecibels;
      _bands = parameters.bands
          .map(
            (band) => EqualizerBand(
              index: band.index,
              centerFrequencyHz: band.centerFrequency,
              gainDb: band.gain,
            ),
          )
          .toList(growable: false);

      if (!_readyCompleter.isCompleted) _readyCompleter.complete();
    } catch (error, stackTrace) {
      _log('band discovery failed', error, stackTrace);
      if (!_readyCompleter.isCompleted) {
        _readyCompleter.completeError(
          EqualizerException(
            EqualizerErrorKind.effectUnavailable,
            'The device did not provide an equalizer effect.',
            cause: error,
          ),
        );
      }
    }
  }

  @override
  Future<void> whenReady() {
    if (!isSupported) throw const EqualizerException.notSupported();
    return _readyCompleter.future;
  }

  @override
  Future<void> setEnabled(bool enabled) async {
    if (!isSupported) throw const EqualizerException.notSupported();
    try {
      // Safe before the effect attaches: just_audio keeps the flag and applies
      // it during activation.
      await _equalizer.setEnabled(enabled);
      _enabled = enabled;
    } catch (error, stackTrace) {
      _log('setEnabled($enabled) failed', error, stackTrace);
      throw EqualizerException(
        EqualizerErrorKind.platformError,
        'Could not ${enabled ? 'enable' : 'disable'} the equalizer.',
        cause: error,
      );
    }
  }

  @override
  List<double> getBandFrequencies() =>
      _bands.map((band) => band.centerFrequencyHz).toList(growable: false);

  @override
  List<double> getBandGains() =>
      _bands.map((band) => band.gainDb).toList(growable: false);

  @override
  Future<void> setBandGain(int bandIndex, double gainDb) async {
    _requireReady();
    EqualizerValidation.bandIndex(bandIndex, _bands.length);
    EqualizerValidation.gain(gainDb, _minDb, _maxDb);
    await _applyGain(bandIndex, gainDb);
  }

  @override
  Future<void> setAllBandGains(List<double> gains) async {
    _requireReady();
    // Validates the whole vector before touching the effect, so a bad value at
    // the end cannot leave the EQ half-applied.
    EqualizerValidation.gainVector(gains, _bands.length, _minDb, _maxDb);
    for (var i = 0; i < gains.length; i++) {
      await _applyGain(i, gains[i]);
    }
  }

  @override
  Future<void> reset() async {
    _requireReady();
    await setAllBandGains(List<double>.filled(_bands.length, 0));
  }

  Future<void> _applyGain(int bandIndex, double gainDb) async {
    final parameters = _parameters;
    if (parameters == null) throw const EqualizerException.notReady();
    try {
      // Mutates the live native effect in place: this reaches
      // Equalizer.setBandLevel on the existing audio session. The player is
      // never rebuilt and playback never gaps.
      await parameters.bands[bandIndex].setGain(gainDb);
      _bands = [
        for (final band in _bands)
          band.index == bandIndex ? band.copyWith(gainDb: gainDb) : band,
      ];
    } catch (error, stackTrace) {
      _log('setBandGain($bandIndex, $gainDb) failed', error, stackTrace);
      throw EqualizerException(
        EqualizerErrorKind.platformError,
        'Could not set the gain for band $bandIndex.',
        cause: error,
      );
    }
  }

  void _requireReady() {
    if (!isSupported) throw const EqualizerException.notSupported();
    if (!isReady) throw const EqualizerException.notReady();
  }

  /// Diagnostics stay in debug builds: release logs must not carry device or
  /// playback detail.
  void _log(String what, Object error, StackTrace stackTrace) {
    if (!kDebugMode) return;
    debugPrint('[Equalizer] $what: $error\n$stackTrace');
  }

  @override
  void dispose() {
    // The AndroidEqualizer belongs to the player's AudioPipeline; disposing
    // the player releases the native effect. Completing the readiness future
    // here would lie about bands that never arrived, so it is left alone.
  }
}
