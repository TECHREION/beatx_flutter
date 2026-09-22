import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

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
  final bands = <EqualizerBand>[].obs;
  final currentPreset = EqualizerPreset.normal.obs;

  /// Set when an operation failed in a way the user should know about.
  final errorMessage = RxnString();

  /// Why the equalizer is not usable right now, so the screen can explain
  /// rather than just saying "unavailable".
  final unavailableReason = EqualizerUnavailableReason.needsPlayback.obs;

  double get minDb => _service.minDb;
  double get maxDb => _service.maxDb;

  final _pendingGains = <int, double>{};
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

    bands.assignAll(_service.bands);
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
      bands.assignAll(_service.bands);
      isReady.value = true;
      unavailableReason.value = EqualizerUnavailableReason.none;
      unawaited(_restoreSettings());
    });
  }

  /// Reapplies the stored configuration onto this device's bands.
  ///
  /// Stored gains belong to whichever device wrote them. If the band count or
  /// the supported range differs, the gains are meaningless here, so the
  /// preset is re-derived instead — that is what makes a preset portable and
  /// a raw gain vector not.
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

    final frequencies = _service.getBandFrequencies();
    var gains = stored.gains;

    final matchesDevice = gains.length == frequencies.length &&
        gains.every((gain) => gain >= minDb && gain <= maxDb);

    if (!matchesDevice) {
      if (stored.preset.hasCurve) {
        // Fit to this device: a curve authored at +/-8 dB can exceed what the
        // hardware allows, and the service rejects rather than clamps.
        gains = _fitToDevice(stored.preset.gainsFor(frequencies));
      } else {
        if (kDebugMode) {
          debugPrint(
            '[Equalizer] stored gains do not fit this device and the preset '
            'is custom; falling back to flat.',
          );
        }
        gains = List<double>.filled(frequencies.length, 0);
      }
    }

    try {
      await _service.setAllBandGains(gains);
      bands.assignAll(_service.bands);
      currentPreset.value = stored.preset;
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

    _pendingGains[bandIndex] = gainDb;
    _writeTimer ??= Timer(_writeThrottle, _flushPendingGains);
  }

  /// Called when a drag ends: flush immediately so the last value is never
  /// left sitting in the throttle window.
  Future<void> commitGain(int bandIndex, double gainDb) async {
    previewGain(bandIndex, gainDb);
    _writeTimer?.cancel();
    _writeTimer = null;
    await _flushPendingGains();
    _schedulePersist();
  }

  Future<void> _flushPendingGains() async {
    _writeTimer = null;
    if (_pendingGains.isEmpty) return;

    final batch = Map<int, double>.from(_pendingGains);
    _pendingGains.clear();

    for (final entry in batch.entries) {
      try {
        await _service.setBandGain(entry.key, entry.value);
      } on EqualizerException catch (error) {
        _report(error);
        // One bad band must not strand the others.
        continue;
      }
    }

    // Values that arrived while awaiting still need a write — this is the
    // trailing edge that keeps the audio matching the final slider position.
    if (_pendingGains.isNotEmpty) {
      _writeTimer ??= Timer(_writeThrottle, _flushPendingGains);
    }
  }

  /// Switches the active preset, resampled onto this device's real bands.
  Future<void> selectPreset(EqualizerPreset preset) async {
    if (!isReady.value || !preset.hasCurve) return;

    final fitted = _fitToDevice(preset.gainsFor(_service.getBandFrequencies()));

    try {
      await _service.setAllBandGains(fitted);
      bands.assignAll(_service.bands);
      currentPreset.value = preset;
      _schedulePersist();
    } on EqualizerException catch (error) {
      _report(error);
    }
  }

  /// Returns every band to 0 dB and selects [EqualizerPreset.normal].
  Future<void> reset() => selectPreset(EqualizerPreset.normal);

  /// Fits an authored curve to what the hardware actually accepts.
  ///
  /// Preset curves go to ±8 dB, but plenty of devices report a narrower range,
  /// and the service rejects an out-of-range gain rather than clamping it.
  /// Losing curve detail is the right trade here, and it is made explicitly in
  /// one place rather than hidden inside the service.
  List<double> _fitToDevice(List<double> gains) => gains
      .map((gain) => gain.clamp(minDb, maxDb).toDouble())
      .toList(growable: false);

  /// Flips to [EqualizerPreset.custom] as soon as the user's gains stop
  /// matching the active preset's curve.
  void _updatePresetFor(int bandIndex, double gainDb) {
    final preset = currentPreset.value;
    if (!preset.hasCurve) return;

    final reference =
        _fitToDevice(preset.gainsFor(_service.getBandFrequencies()));
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
