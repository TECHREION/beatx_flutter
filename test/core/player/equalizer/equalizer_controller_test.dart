import 'package:beatx_flutter/core/player/equalizer/equalizer_controller.dart';
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
    test('exposes the device bands once ready', () async {
      await boot();
      expect(controller.isSupported.value, isTrue);
      expect(controller.isReady.value, isTrue);
      expect(controller.bands, hasLength(5));
      expect(
        controller.bands.map((b) => b.centerFrequencyHz),
        [60, 230, 910, 3600, 14000],
      );
    });

    test('stays unsupported and does nothing when the platform has no EQ',
        () async {
      await boot(withService: FakeEqualizerService(isSupported: false));
      expect(controller.isSupported.value, isFalse);
      expect(controller.isReady.value, isFalse);
      expect(controller.bands, isEmpty);
      // No pointless platform work when the feature cannot exist.
      expect(service.initializeCalls, 0);
    });

    test('is not ready until playback gives the effect a session', () async {
      await boot(withService: FakeEqualizerService(readyImmediately: false));
      expect(controller.isSupported.value, isTrue);
      expect(controller.isReady.value, isFalse);
      expect(controller.bands, isEmpty);

      service.becomeReady();
      await settle();

      expect(controller.isReady.value, isTrue);
      expect(controller.bands, hasLength(5));
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
    test('applies a preset resampled onto the device bands', () async {
      await boot();
      await controller.selectPreset(EqualizerPreset.bassBooster);

      expect(controller.currentPreset.value, EqualizerPreset.bassBooster);
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

      expect(service.writes.last.$1, 1);
      expect(service.writes.last.$2, closeTo(3.9, 1e-9));
      expect(service.getBandGains()[1], closeTo(3.9, 1e-9));
    });
  });

  group('restoration', () {
    test('restores gains, preset and enabled state', () async {
      await boot(
        withStore: FakeEqualizerStore(
          const EqualizerSettings(
            enabled: true,
            preset: EqualizerPreset.custom,
            gains: [1, 2, 3, 4, 5],
          ),
        ),
      );

      expect(controller.enabled.value, isTrue);
      expect(controller.currentPreset.value, EqualizerPreset.custom);
      expect(service.getBandGains(), [1, 2, 3, 4, 5]);
    });

    test('re-derives from the preset when the band count differs', () async {
      // Settings written on a 10-band device, restored on a 5-band one.
      await boot(
        withStore: FakeEqualizerStore(
          EqualizerSettings(
            enabled: true,
            preset: EqualizerPreset.rock,
            gains: List<double>.filled(10, 5),
          ),
        ),
      );

      expect(controller.currentPreset.value, EqualizerPreset.rock);
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
            gains: List<double>.filled(10, 5),
          ),
        ),
      );

      expect(service.getBandGains(), hasLength(5));
      expect(service.getBandGains(), everyElement(0.0));
      expect(controller.errorMessage.value, isNull);
    });

    test('re-derives when stored gains exceed this device range', () async {
      // Same band count, but the old device allowed +/-12 and this one +/-4.
      await boot(
        withService: FakeEqualizerService(minDb: -4, maxDb: 4),
        withStore: FakeEqualizerStore(
          const EqualizerSettings(
            enabled: true,
            preset: EqualizerPreset.rock,
            gains: [10, 10, 10, 10, 10],
          ),
        ),
      );

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
