import 'dart:async';

import 'package:beatx_flutter/core/player/equalizer/equalizer_service.dart';
import 'package:beatx_flutter/core/player/equalizer/equalizer_store.dart';
import 'package:beatx_flutter/core/player/equalizer/equalizer_validation.dart';
import 'package:beatx_flutter/core/player/equalizer/models/equalizer_band.dart';
import 'package:beatx_flutter/core/player/equalizer/models/equalizer_exception.dart';
import 'package:beatx_flutter/core/player/equalizer/models/equalizer_settings.dart';

/// An in-memory stand-in for the native effect.
///
/// Applies exactly the same validation rules as the real implementation, so a
/// test that passes here is testing the contract rather than the fake.
class FakeEqualizerService implements EqualizerService {
  FakeEqualizerService({
    List<double> frequencies = const [60, 230, 910, 3600, 14000],
    this.minDb = -12,
    this.maxDb = 12,
    this.isSupported = true,
    this.readyImmediately = true,
  }) {
    _bands = [
      for (var i = 0; i < frequencies.length; i++)
        EqualizerBand(index: i, centerFrequencyHz: frequencies[i], gainDb: 0),
    ];
    if (readyImmediately) _readyCompleter.complete();
  }

  @override
  final bool isSupported;
  @override
  final double minDb;
  @override
  final double maxDb;

  final bool readyImmediately;
  final _readyCompleter = Completer<void>();

  late List<EqualizerBand> _bands;
  bool _enabled = false;

  /// Every gain write that reached the "native" layer, in order. Lets a test
  /// assert how many platform calls a drag actually produced.
  final writes = <(int, double)>[];
  int initializeCalls = 0;

  @override
  bool get isReady => _readyCompleter.isCompleted;

  @override
  List<EqualizerBand> get bands => _bands;

  @override
  bool get isEnabled => _enabled;

  /// Completes readiness, mimicking the first track starting playback.
  void becomeReady() {
    if (!_readyCompleter.isCompleted) _readyCompleter.complete();
  }

  @override
  Future<void> initialize() async => initializeCalls++;

  @override
  Future<void> whenReady() {
    if (!isSupported) throw const EqualizerException.notSupported();
    return _readyCompleter.future;
  }

  @override
  Future<void> setEnabled(bool enabled) async {
    if (!isSupported) throw const EqualizerException.notSupported();
    _enabled = enabled;
  }

  @override
  List<double> getBandFrequencies() =>
      _bands.map((b) => b.centerFrequencyHz).toList(growable: false);

  @override
  List<double> getBandGains() =>
      _bands.map((b) => b.gainDb).toList(growable: false);

  @override
  Future<void> setBandGain(int bandIndex, double gainDb) async {
    _requireReady();
    EqualizerValidation.bandIndex(bandIndex, _bands.length);
    EqualizerValidation.gain(gainDb, minDb, maxDb);
    writes.add((bandIndex, gainDb));
    _bands = [
      for (final band in _bands)
        band.index == bandIndex ? band.copyWith(gainDb: gainDb) : band,
    ];
  }

  @override
  Future<void> setAllBandGains(List<double> gains) async {
    _requireReady();
    EqualizerValidation.gainVector(gains, _bands.length, minDb, maxDb);
    for (var i = 0; i < gains.length; i++) {
      await setBandGain(i, gains[i]);
    }
  }

  @override
  Future<void> reset() async =>
      setAllBandGains(List<double>.filled(_bands.length, 0));

  void _requireReady() {
    if (!isSupported) throw const EqualizerException.notSupported();
    if (!isReady) throw const EqualizerException.notReady();
  }

  @override
  void dispose() {}
}

/// An [EqualizerStore] that keeps its blob in memory instead of the keychain.
class FakeEqualizerStore implements EqualizerStore {
  FakeEqualizerStore([this.stored]);

  EqualizerSettings? stored;
  int writeCount = 0;

  /// When true, [read] throws the way a locked or corrupt keystore would.
  bool failReads = false;

  @override
  Future<EqualizerSettings?> read() async {
    if (failReads) throw StateError('keystore unavailable');
    return stored;
  }

  @override
  Future<void> write(EqualizerSettings settings) async {
    writeCount++;
    stored = settings;
  }

  @override
  Future<void> clear() async => stored = null;
}
