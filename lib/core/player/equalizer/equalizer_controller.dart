import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import 'equalizer_curve.dart';
import 'equalizer_service.dart';
import 'equalizer_service_ios.dart';
import 'equalizer_store.dart';
import 'models/equalizer_band.dart';
import 'models/equalizer_exception.dart';
import 'models/equalizer_preset.dart';
import 'models/equalizer_settings.dart';

/// The equalizer as the UI sees it.
///
/// Owns everything that is not the native effect itself: preset selection,
/// "custom" detection, persistence, and the write throttling that keeps a
/// slider drag from flooding the platform channel.
///
/// It also owns the gap between what the user edits and what the hardware
/// exposes. [bands] is always the fixed [kDisplayFrequenciesHz] set at
/// [kDisplayMinDb]..[kDisplayMaxDb], identical on every device and both
/// platforms; the curve is resampled onto the device's real bands on the way
/// down to the service. On iOS that mapping is the identity — our engine runs
/// on exactly these frequencies and range — so only Android does real work.
class EqualizerController extends GetxController {
  EqualizerController({
    required EqualizerService service,
    EqualizerStore? store,
  })  : _service = service,
        _store = store ?? EqualizerStore();

  static EqualizerController get instance {
    if (!Get.isRegistered<EqualizerController>()) {
      Get.put(
        EqualizerController(service: Get.find<EqualizerService>()),
        permanent: true,
      );
    }
    return Get.find<EqualizerController>();
  }

  /// One native write per band at most this often while dragging. Fast enough
  /// that the audio follows the finger, slow enough to stay off the channel's
  /// back.
  static const _writeThrottle = Duration(milliseconds: 32);

  /// Settings are rewritten this long after the last change, so a drag stores
  /// once instead of sixty times.
  static const _persistDebounce = Duration(milliseconds: 500);

  /// Gains closer than this count as "unchanged" when deciding whether the
  /// user has departed from a preset. Comfortably below one audible step.
  static const _gainEpsilon = 0.05;

  final EqualizerService _service;
  final EqualizerStore _store;

  /// Whether the platform has a real equalizer. When false the feature is
  /// hidden entirely — there is no degraded mode.
  final isSupported = false.obs;

  /// Whether the device has reported its bands. False until playback starts.
  final isReady = false.obs;

  final enabled = false.obs;

  /// The curve the user edits: always ten bands, the same everywhere.
  final bands = <EqualizerBand>[
    for (var i = 0; i < kDisplayFrequenciesHz.length; i++)
      EqualizerBand(
        index: i,
        centerFrequencyHz: kDisplayFrequenciesHz[i],
        gainDb: 0,
      ),
  ].obs;

  final currentPreset = EqualizerPreset.normal.obs;

  /// Set when an operation failed in a way the user should know about.
  final errorMessage = RxnString();

  /// Why the equalizer is not usable right now, so the screen can explain
  /// rather than just saying "unavailable".
  final unavailableReason = EqualizerUnavailableReason.needsPlayback.obs;

  /// The range the screen offers. Fixed, not the device's — a curve is fitted
  /// to whatever the hardware accepts only when it is written.
  double get minDb => kDisplayMinDb;
  double get maxDb => kDisplayMaxDb;

  /// The gains as the user set them, one per display band.
  List<double> get _displayGains =>
      bands.map((band) => band.gainDb).toList(growable: false);

  /// Set while a curve write is waiting on the throttle.
  bool _writePending = false;
  Timer? _availabilityTimer;
  Timer? _writeTimer;
  Timer? _persistTimer;
  bool _restored = false;

  @override
  void onInit() {
    super.onInit();
    isSupported.value = _service.isSupported;
    if (!isSupported.value) return;
    unawaited(_bootstrap());
  }

  Future<void> _bootstrap() async {
    await _service.initialize();
    _watchAvailability();
    try {
      // Resolves only once a track has loaded and the effect has a session.
      await _service.whenReady();
    } on EqualizerException catch (error) {
      _report(error);
      return;
    } catch (error) {
      _report(
        EqualizerException(
          EqualizerErrorKind.effectUnavailable,
          'The equalizer is unavailable on this device.',
          cause: error,
        ),
      );
      return;
    }

    isReady.value = true;
    unavailableReason.value = EqualizerUnavailableReason.none;
    await _restoreSettings();
  }

  /// Polls the platform while the equalizer is not yet attached, so the screen
  /// reflects reality without the user having to reopen it.
  ///
  /// On iOS the tap attaches a moment after playback starts, and whether it can
  /// attach at all depends on the stream's format — neither of which the
  /// platform pushes as an event.
  void _watchAvailability() {
    _availabilityTimer?.cancel();
    _availabilityTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final service = _service;
      if (service is IosEqualizerService) {
        unavailableReason.value = service.unavailableReason;
      }
      if (!_service.isReady) return;

      timer.cancel();
      _availabilityTimer = null;
      isReady.value = true;
      unavailableReason.value = EqualizerUnavailableReason.none;
      unawaited(_restoreSettings());
    });
  }

  /// Reapplies the stored configuration.
  ///
  /// Stored gains are display gains — ten bands at a fixed range, the same on
  /// every device — so unlike the device-shaped gains this used to store, they
  /// carry over from one handset to another. A vector that still does not fit
  /// (written by an older build, or corrupted) falls back to re-deriving the
  /// stored preset, and only a custom curve with no preset to fall back on
  /// goes flat.
  Future<void> _restoreSettings() async {
    if (_restored) return;
    _restored = true;

    EqualizerSettings? stored;
    try {
      stored = await _store.read();
    } catch (error) {
      // The store already swallows its own failures, but it must not be able
      // to take the equalizer down with it if that ever changes.
      if (kDebugMode) debugPrint('[Equalizer] restore failed: $error');
      return;
    }
    if (stored == null) return;

    var gains = stored.gains;
    final fits = gains.length == kDisplayFrequenciesHz.length &&
        gains.every((gain) => gain >= kDisplayMinDb && gain <= kDisplayMaxDb);

    if (!fits) {
      if (stored.preset.hasCurve) {
        gains = stored.preset.gainsFor(kDisplayFrequenciesHz);
      } else {
        if (kDebugMode) {
          debugPrint(
            '[Equalizer] stored gains are not a display curve and the preset '
            'is custom; falling back to flat.',
          );
        }
        gains = List<double>.filled(kDisplayFrequenciesHz.length, 0);
      }
    }

    await _applyDisplayCurve(gains);
    currentPreset.value = stored.preset;

    try {
      await _service.setEnabled(stored.enabled);
      enabled.value = stored.enabled;
    } on EqualizerException catch (error) {
      _report(error);
    }
  }

  Future<void> setEnabled(bool value) async {
    try {
      await _service.setEnabled(value);
      enabled.value = value;
      _schedulePersist();
    } on EqualizerException catch (error) {
      _report(error);
    }
  }

  /// Called continuously while a slider is dragged.
  ///
  /// Updates the displayed value immediately and throttles the native write,
  /// so the UI stays at full frame rate without queueing a platform call per
  /// pixel.
  void previewGain(int bandIndex, double gainDb) {
    if (!isReady.value) return;
    if (bandIndex < 0 || bandIndex >= bands.length) return;

    bands[bandIndex] = bands[bandIndex].copyWith(gainDb: gainDb);
    bands.refresh();
    _updatePresetFor(bandIndex, gainDb);

    // One display band does not map to one device band, so the whole curve is
    // rewritten rather than a single gain.
    _writePending = true;
    _writeTimer ??= Timer(_writeThrottle, _flushCurve);
  }

  /// Called when a drag ends: flush immediately so the last value is never
  /// left sitting in the throttle window.
  Future<void> commitGain(int bandIndex, double gainDb) async {
    previewGain(bandIndex, gainDb);
    _writeTimer?.cancel();
    _writeTimer = null;
    await _flushCurve();
    _schedulePersist();
  }

  Future<void> _flushCurve() async {
    _writeTimer = null;
    if (!_writePending) return;
    _writePending = false;

    await _writeCurveToDevice(_displayGains);

    // A value that arrived while awaiting still needs a write — this is the
    // trailing edge that keeps the audio matching the final slider position.
    if (_writePending) {
      _writeTimer ??= Timer(_writeThrottle, _flushCurve);
    }
  }

  /// Projects the display curve onto the device's real bands and pushes it.
  ///
  /// This is the only place the two models meet. On iOS the frequencies and
  /// range match exactly, so the resample is the identity.
  Future<void> _writeCurveToDevice(List<double> displayGains) async {
    if (!isReady.value) return;

    final deviceGains = _fitToDevice(
      resampleCurve(
        displayGains,
        fromHz: kDisplayFrequenciesHz,
        toHz: _service.getBandFrequencies(),
      ),
    );
    if (deviceGains.isEmpty) return;

    try {
      await _service.setAllBandGains(deviceGains);
    } on EqualizerException catch (error) {
      _report(error);
    }
  }

  /// Replaces the whole display curve and pushes it to the device.
  Future<void> _applyDisplayCurve(List<double> gains) async {
    bands.assignAll([
      for (var i = 0; i < kDisplayFrequenciesHz.length; i++)
        EqualizerBand(
          index: i,
          centerFrequencyHz: kDisplayFrequenciesHz[i],
          gainDb: gains[i].clamp(kDisplayMinDb, kDisplayMaxDb).toDouble(),
        ),
    ]);
    await _writeCurveToDevice(_displayGains);
  }

  /// Switches the active preset.
  Future<void> selectPreset(EqualizerPreset preset) async {
    if (!isReady.value || !preset.hasCurve) return;

    await _applyDisplayCurve(preset.gainsFor(kDisplayFrequenciesHz));
    currentPreset.value = preset;
    _schedulePersist();
  }

  /// Returns every band to 0 dB and selects [EqualizerPreset.normal].
  Future<void> reset() => selectPreset(EqualizerPreset.normal);

  /// Fits a curve to what the hardware actually accepts.
  ///
  /// The display range is fixed at ±12 dB, but plenty of devices report a
  /// narrower one, and the service rejects an out-of-range gain rather than
  /// clamping it. Losing curve detail is the right trade here, and it is made
  /// explicitly in one place rather than hidden inside the service.
  List<double> _fitToDevice(List<double> gains) =>
      clampCurve(gains, _service.minDb, _service.maxDb);

  /// Flips to [EqualizerPreset.custom] as soon as the user's gains stop
  /// matching the active preset's curve.
  void _updatePresetFor(int bandIndex, double gainDb) {
    final preset = currentPreset.value;
    if (!preset.hasCurve) return;

    final reference = preset.gainsFor(kDisplayFrequenciesHz);
    if (bandIndex >= reference.length) return;

    if ((reference[bandIndex] - gainDb).abs() > _gainEpsilon) {
      currentPreset.value = EqualizerPreset.custom;
    }
  }

  void _schedulePersist() {
    _persistTimer?.cancel();
    _persistTimer = Timer(_persistDebounce, () {
      unawaited(
        _store.write(
          EqualizerSettings(
            enabled: enabled.value,
            preset: currentPreset.value,
            gains: bands.map((band) => band.gainDb).toList(growable: false),
          ),
        ),
      );
    });
  }

  void _report(EqualizerException error) {
    if (kDebugMode) debugPrint('[Equalizer] $error');
    // notReady is an expected state before playback starts, not a failure the
    // user needs to see.
    if (error.kind == EqualizerErrorKind.notReady) return;
    errorMessage.value = error.message;
  }

  @override
  void onClose() {
    _availabilityTimer?.cancel();
    _writeTimer?.cancel();
    _persistTimer?.cancel();
    _service.dispose();
    super.onClose();
  }
}
