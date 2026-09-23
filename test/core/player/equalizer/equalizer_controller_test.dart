import 'package:beatx_flutter/core/player/equalizer/equalizer_controller.dart';
import 'package:beatx_flutter/core/player/equalizer/equalizer_curve.dart';
import 'package:beatx_flutter/core/player/equalizer/models/equalizer_preset.dart';
import 'package:beatx_flutter/core/player/equalizer/models/equalizer_settings.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

/// Lets the controller's un-awaited bootstrap and its throttle timers run.
Future<void> settle([int ms = 60]) =>
    Future<void>.delayed(Duration(milliseconds: ms));

void main() {
  late FakeEqualizerService service;
  late FakeEqualizerStore store;
  late EqualizerController controller;

  Future<EqualizerController> boot({
    FakeEqualizerService? withService,
    FakeEqualizerStore? withStore,
  }) async {
    service = withService ?? FakeEqualizerService();
    store = withStore ?? FakeEqualizerStore();
    controller = EqualizerController(service: service, store: store);
    controller.onInit();
    await settle();
    return controller;
  }

  tearDown(() => controller.onClose());

  group('bootstrap', () {
    test('exposes the fixed display bands, not the device ones', () async {
      // The fake reports Android's usual five bands; the screen must still
      // show the same ten everywhere, or iOS and Android look different.
      await boot();
      expect(controller.isSupported.value, isTrue);
      expect(controller.isReady.value, isTrue);
      expect(controller.bands, hasLength(kDisplayFrequenciesHz.length));
      expect(
        controller.bands.map((b) => b.centerFrequencyHz),
        kDisplayFrequenciesHz,
      );
      expect(service.getBandFrequencies(), [60, 230, 910, 3600, 14000]);
    });

    test('offers the fixed display range whatever the device accepts',
        () async {
      await boot(withService: FakeEqualizerService(minDb: -4, maxDb: 4));
      expect(controller.minDb, kDisplayMinDb);
      expect(controller.maxDb, kDisplayMaxDb);
    });

    test('stays unsupported and does nothing when the platform has no EQ',
        () async {
      await boot(withService: FakeEqualizerService(isSupported: false));
      expect(controller.isSupported.value, isFalse);
      expect(controller.isReady.value, isFalse);
      // The display curve exists regardless of hardware; the screen hides the
      // whole feature when unsupported rather than reading an empty list.
      expect(controller.bands, hasLength(kDisplayFrequenciesHz.length));
      // No pointless platform work when the feature cannot exist.
      expect(service.initializeCalls, 0);
    });

    test('is not ready until playback gives the effect a session', () async {
      await boot(withService: FakeEqualizerService(readyImmediately: false));
      expect(controller.isSupported.value, isTrue);
      expect(controller.isReady.value, isFalse);
      // The axis renders flat while waiting rather than collapsing to nothing.
      expect(controller.bands, hasLength(kDisplayFrequenciesHz.length));
      expect(controller.bands.map((b) => b.gainDb), everyElement(0.0));

      service.becomeReady();
      await settle();

      expect(controller.isReady.value, isTrue);
      expect(controller.bands, hasLength(kDisplayFrequenciesHz.length));
    });

    test('ignores gain changes while not ready', () async {
      await boot(withService: FakeEqualizerService(readyImmediately: false));
      controller.previewGain(0, 6);
      await settle();
      expect(service.writes, isEmpty);
      expect(controller.errorMessage.value, isNull);
    });
  });

  group('presets', () {
    test('applies a preset to the display curve and resamples it down',
        () async {
      await boot();
      await controller.selectPreset(EqualizerPreset.bassBooster);

      expect(controller.currentPreset.value, EqualizerPreset.bassBooster);
      // The user sees the authored ten-band curve...
      expect(controller.bands, hasLength(kDisplayFrequenciesHz.length));
      expect(controller.bands.first.gainDb, closeTo(7, 1e-9));
      // ...while the five-band device gets it resampled.
      expect(service.getBandGains(), hasLength(5));
      expect(service.getBandGains().first, greaterThan(3));
    });

    test('becomes custom once a band is dragged off the curve', () async {
      await boot();
      await controller.selectPreset(EqualizerPreset.rock);
      expect(controller.currentPreset.value, EqualizerPreset.rock);

      await controller.commitGain(2, 7);
      expect(controller.currentPreset.value, EqualizerPreset.custom);
    });

    test('stays on the preset when a band is set to its own curve value',
        () async {
      await boot();
      await controller.selectPreset(EqualizerPreset.jazz);
      final current = controller.bands[1].gainDb;

      await controller.commitGain(1, current);
      expect(controller.currentPreset.value, EqualizerPreset.jazz);
    });

    test('reset returns every band to flat and selects Normal', () async {
      await boot();
      await controller.selectPreset(EqualizerPreset.rock);
      await controller.reset();

      expect(controller.currentPreset.value, EqualizerPreset.normal);
      expect(service.getBandGains(), everyElement(closeTo(0, 1e-9)));
    });

    test('fits a preset to a device with a narrower range instead of failing',
        () async {
      // Bass Booster asks for +7 dB; this device tops out at +4.
      await boot(withService: FakeEqualizerService(minDb: -4, maxDb: 4));
      await controller.selectPreset(EqualizerPreset.bassBooster);

      expect(controller.errorMessage.value, isNull);
      for (final gain in service.getBandGains()) {
        expect(gain, inInclusiveRange(-4, 4));
      }
    });
  });

  group('enabled state', () {
    test('round-trips through the service', () async {
      await boot();
      await controller.setEnabled(true);
      expect(controller.enabled.value, isTrue);
      expect(service.isEnabled, isTrue);

      await controller.setEnabled(false);
      expect(controller.enabled.value, isFalse);
      expect(service.isEnabled, isFalse);
    });
  });

  group('write throttling', () {
    test('a drag produces far fewer platform writes than slider events',
        () async {
      await boot();
      // 40 pixel-level updates, as a real drag would emit.
      for (var i = 0; i < 40; i++) {
        controller.previewGain(0, i * 0.1);
      }
      await settle(120);

      expect(service.writes.length, lessThan(10));
      // The displayed value tracks the finger regardless of throttling.
      expect(controller.bands[0].gainDb, closeTo(3.9, 1e-9));
    });

    test('the final value always reaches the platform', () async {
      await boot();
      for (var i = 0; i < 40; i++) {
        controller.previewGain(1, i * 0.1);
      }
      await controller.commitGain(1, 3.9);
      await settle(120);

      // The display band holds exactly what the finger left behind...
      expect(controller.bands[1].gainDb, closeTo(3.9, 1e-9));
      // ...and the device ends up with the whole curve, not a stale one. The
      // 62 Hz display band sits between the device's 60 Hz and 230 Hz bands,
      // so both move and neither reaches the full 3.9.
      expect(service.getBandGains(), hasLength(5));
      expect(service.getBandGains()[0], greaterThan(0));
      expect(service.getBandGains()[0], lessThanOrEqualTo(3.9));
    });
  });

  group('restoration', () {
    test('restores gains, preset and enabled state', () async {
      const curve = <double>[1, 2, 3, 4, 5, 4, 3, 2, 1, 0];
      await boot(
        withStore: FakeEqualizerStore(
          const EqualizerSettings(
            enabled: true,
            preset: EqualizerPreset.custom,
            gains: curve,
          ),
        ),
      );

      expect(controller.enabled.value, isTrue);
      expect(controller.currentPreset.value, EqualizerPreset.custom);
      expect(controller.bands.map((b) => b.gainDb), curve);
      // Stored curves are display-shaped now, so they survive a move to a
      // device with a different band layout.
      expect(service.getBandGains(), hasLength(5));
    });

    test('re-derives from the preset when stored gains are device-shaped',
        () async {
      // Written by an older build that stored the device's five gains.
      await boot(
        withStore: FakeEqualizerStore(
          EqualizerSettings(
            enabled: true,
            preset: EqualizerPreset.rock,
            gains: List<double>.filled(5, 5),
          ),
        ),
      );

      expect(controller.currentPreset.value, EqualizerPreset.rock);
      expect(controller.bands, hasLength(kDisplayFrequenciesHz.length));
      expect(service.getBandGains(), hasLength(5));
      // Rock lifts the low end; a blind copy of the old vector would have
      // been rejected outright.
      expect(service.getBandGains().first, greaterThan(0));
    });

    test('falls back to flat when a custom vector does not fit the device',
        () async {
      await boot(
        withStore: FakeEqualizerStore(
          EqualizerSettings(
            enabled: false,
            preset: EqualizerPreset.custom,
            gains: List<double>.filled(5, 5),
          ),
        ),
      );

      expect(service.getBandGains(), hasLength(5));
      expect(service.getBandGains(), everyElement(0.0));
      expect(controller.errorMessage.value, isNull);
    });

    test('clamps to a narrower device without losing the display curve',
        () async {
      // The display range is always +/-12; this device only accepts +/-4.
      await boot(
        withService: FakeEqualizerService(minDb: -4, maxDb: 4),
        withStore: FakeEqualizerStore(
          EqualizerSettings(
            enabled: true,
            preset: EqualizerPreset.rock,
            gains: List<double>.filled(kDisplayFrequenciesHz.length, 10),
          ),
        ),
      );

      expect(controller.bands.first.gainDb, closeTo(10, 1e-9));

      expect(controller.errorMessage.value, isNull);
      for (final gain in service.getBandGains()) {
        expect(gain, inInclusiveRange(-4, 4));
      }
    });

    test('survives an unreadable store', () async {
      final failing = FakeEqualizerStore()..failReads = true;
      await boot(withStore: failing);
      // Bootstrap still completed; the EQ is simply at its defaults.
      expect(controller.isReady.value, isTrue);
      expect(service.getBandGains(), everyElement(0.0));
    });
  });

  group('persistence', () {
    test('debounces writes during a drag', () async {
      await boot();
      for (var i = 0; i < 20; i++) {
        controller.previewGain(0, i * 0.1);
      }
      await controller.commitGain(0, 1.9);
      await settle(700);

      expect(store.writeCount, 1);
      expect(store.stored!.gains[0], closeTo(1.9, 1e-9));
      expect(store.stored!.preset, EqualizerPreset.custom);
    });

    test('persists the enabled flag', () async {
      await boot();
      await controller.setEnabled(true);
      await settle(700);

      expect(store.stored!.enabled, isTrue);
    });
  });
}
