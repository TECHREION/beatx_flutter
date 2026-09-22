import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'equalizer_service.dart';
import 'equalizer_validation.dart';
import 'models/equalizer_band.dart';
import 'models/equalizer_exception.dart';

/// iOS equalizer, backed by a native `AUNBandEQ` running inside an
/// `MTAudioProcessingTap` on the current `AVPlayerItem`.
///
/// ## Availability is measured, not assumed
/// The tap can only attach to an asset that exposes an audio track. HLS assets
/// expose none, so on an HLS stream this service reports itself not ready and
/// the UI says so. It becomes ready by itself the moment a progressive
/// rendition is played — no feature flag, no app update. See
/// `docs/ios-equalizer-backend-requirements.md`.
///
/// [isReady] therefore reflects whether real samples have actually passed
/// through the unit, not whether the platform is iOS.
class IosEqualizerService implements EqualizerService {
  IosEqualizerService({MethodChannel? channel})
      : _channel = channel ?? const MethodChannel('com.beatx/equalizer');

  /// How often native state is polled while waiting to become ready. The tap
  /// attaches a moment after playback starts, and there is no push event for
  /// it, so a cheap poll is simpler than an EventChannel for one boolean.
  static const _pollInterval = Duration(seconds: 1);

  final MethodChannel _channel;
  final _readyCompleter = Completer<void>();

  Timer? _poll;
  List<EqualizerBand> _bands = const [];
  double _minDb = 0;
  double _maxDb = 0;
  bool _enabled = false;
  bool _processing = false;
  bool _hasSeenItem = false;
  bool _itemHasAudioTrack = false;

  @override
  bool get isSupported => true;

  @override
  bool get isReady => _processing && _bands.isNotEmpty;

  @override
  List<EqualizerBand> get bands => _bands;

  @override
  double get minDb => _minDb;

  @override
  double get maxDb => _maxDb;

  @override
  bool get isEnabled => _enabled;

  /// Why the equalizer is not ready, for a UI that should explain rather than
  /// just say "unavailable".
  EqualizerUnavailableReason get unavailableReason {
    if (isReady) return EqualizerUnavailableReason.none;
    if (!_hasSeenItem) return EqualizerUnavailableReason.needsPlayback;
    if (!_itemHasAudioTrack) return EqualizerUnavailableReason.incompatibleStream;
    return EqualizerUnavailableReason.needsPlayback;
  }

  @override
  Future<void> initialize() async {
    await _refresh();
    _poll ??= Timer.periodic(_pollInterval, (_) => _refresh());
  }

  Future<void> _refresh() async {
    try {
      final raw = await _channel.invokeMapMethod<String, dynamic>(
        'getConfiguration',
      );
      if (raw == null) return;

      _minDb = (raw['minDecibels'] as num).toDouble();
      _maxDb = (raw['maxDecibels'] as num).toDouble();
      _enabled = raw['enabled'] == true;
      _processing = raw['processing'] == true;
      _hasSeenItem = raw['hasSeenItem'] == true;
      _itemHasAudioTrack = raw['itemHasAudioTrack'] == true;

      final frequencies = (raw['frequencies'] as List).cast<num>();
      final gains = (raw['gains'] as List).cast<num>();
      _bands = [
        for (var i = 0; i < frequencies.length; i++)
          EqualizerBand(
            index: i,
            centerFrequencyHz: frequencies[i].toDouble(),
            gainDb: i < gains.length ? gains[i].toDouble() : 0,
          ),
      ];

      if (isReady && !_readyCompleter.isCompleted) _readyCompleter.complete();
    } on PlatformException catch (error) {
      _log('getConfiguration failed', error);
    } on MissingPluginException catch (error) {
      // The native plugin is not registered — treat as permanently unavailable
      // rather than polling forever.
      _log('plugin missing', error);
      _poll?.cancel();
      _poll = null;
    }
  }

  @override
  Future<void> whenReady() => _readyCompleter.future;

  @override
  Future<void> setEnabled(bool enabled) async {
    await _invoke('setEnabled', {'enabled': enabled});
    _enabled = enabled;
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
    // Validated in Dart first so a bad value never reaches the audio thread,
    // and so the failure mode matches Android exactly.
    EqualizerValidation.bandIndex(bandIndex, _bands.length);
    EqualizerValidation.gain(gainDb, _minDb, _maxDb);

    await _invoke('setBandGain', {'bandIndex': bandIndex, 'gainDb': gainDb});
    _bands = [
      for (final band in _bands)
        band.index == bandIndex ? band.copyWith(gainDb: gainDb) : band,
    ];
  }

  @override
  Future<void> setAllBandGains(List<double> gains) async {
    _requireReady();
    EqualizerValidation.gainVector(gains, _bands.length, _minDb, _maxDb);

    await _invoke('setAllGains', {'gains': gains});
    _bands = [
      for (var i = 0; i < _bands.length; i++) _bands[i].copyWith(gainDb: gains[i]),
    ];
  }

  @override
  Future<void> reset() async {
    _requireReady();
    await setAllBandGains(List<double>.filled(_bands.length, 0));
  }

  Future<void> _invoke(String method, [Map<String, dynamic>? args]) async {
    try {
      await _channel.invokeMethod<void>(method, args);
    } on PlatformException catch (error) {
      throw _mapPlatformException(error);
    } on MissingPluginException catch (error) {
      throw EqualizerException(
        EqualizerErrorKind.notSupported,
        'The native equalizer is not available.',
        cause: error,
      );
    }
  }

  EqualizerException _mapPlatformException(PlatformException error) {
    final kind = switch (error.code) {
      'invalid_band_index' => EqualizerErrorKind.invalidBandIndex,
      'gain_out_of_range' => EqualizerErrorKind.gainOutOfRange,
      'effect_unavailable' => EqualizerErrorKind.effectUnavailable,
      _ => EqualizerErrorKind.platformError,
    };
    return EqualizerException(
      kind,
      error.message ?? 'The equalizer operation failed.',
      cause: error,
    );
  }

  void _requireReady() {
    if (!isReady) throw const EqualizerException.notReady();
  }

  void _log(String what, Object error) {
    if (kDebugMode) debugPrint('[Equalizer/iOS] $what: $error');
  }

  @override
  void dispose() {
    _poll?.cancel();
    _poll = null;
  }
}

/// Why the equalizer cannot run right now.
enum EqualizerUnavailableReason {
  none,

  /// Nothing has played yet, so there is no audio to attach to.
  needsPlayback,

  /// The current stream's format exposes no audio track to process — the HLS
  /// case on iOS.
  incompatibleStream,
}
