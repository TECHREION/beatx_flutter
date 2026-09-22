import 'package:beatx_flutter/core/player/equalizer/models/equalizer_preset.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('preset curves', () {
    test('every selectable preset has one value per reference frequency', () {
      for (final preset in EqualizerPreset.selectable) {
        expect(
          preset.referenceCurve,
          hasLength(kReferenceFrequenciesHz.length),
          reason: '${preset.displayName} must define all 10 reference points',
        );
      }
    });

    test('no preset exceeds +/-8 dB', () {
      // Headroom matters: these sit on top of already-mastered audio, and a
      // hotter curve buys clipping rather than a better sound.
      for (final preset in EqualizerPreset.selectable) {
        for (final gain in preset.referenceCurve!) {
          expect(
            gain.abs(),
            lessThanOrEqualTo(8.0),
            reason: '${preset.displayName} has an excessive gain of $gain dB',
          );
        }
      }
    });

    test('normal is flat', () {
      expect(EqualizerPreset.normal.referenceCurve, everyElement(0.0));
    });

    test('custom carries no curve and refuses to be applied', () {
      expect(EqualizerPreset.custom.hasCurve, isFalse);
      expect(EqualizerPreset.custom.referenceCurve, isNull);
      expect(
        () => EqualizerPreset.custom.gainsFor(kReferenceFrequenciesHz),
        throwsStateError,
      );
    });

    test('custom is not offered as a selectable preset', () {
      expect(
        EqualizerPreset.selectable,
        isNot(contains(EqualizerPreset.custom)),
      );
    });

    test('all 13 named presets are present', () {
      expect(EqualizerPreset.selectable, hasLength(13));
    });

    test('bass presets actually move the bass', () {
      final boosted = EqualizerPreset.bassBooster.referenceCurve!;
      final reduced = EqualizerPreset.bassReducer.referenceCurve!;
      expect(boosted.first, greaterThan(3));
      expect(reduced.first, lessThan(-3));
    });
  });

  group('gainsFor resampling', () {
    test('returns the authored curve at the reference frequencies', () {
      final gains = EqualizerPreset.rock.gainsFor(kReferenceFrequenciesHz);
      expect(gains, hasLength(kReferenceFrequenciesHz.length));
      for (var i = 0; i < gains.length; i++) {
        expect(gains[i], closeTo(EqualizerPreset.rock.referenceCurve![i], 1e-9));
      }
    });

    test('resamples onto a 5-band device, which is the Android norm', () {
      // A real device band set: not the spec frequencies, and only five of
      // them. This is the case the whole interpolation exists for.
      const deviceBands = <double>[60, 230, 910, 3600, 14000];
      final gains = EqualizerPreset.bassBooster.gainsFor(deviceBands);

      expect(gains, hasLength(5));
      // Bass Booster lifts the low end and leaves the top alone.
      expect(gains.first, greaterThan(3));
      expect(gains.last, closeTo(0, 0.01));
    });

    test('interpolates in log-frequency space, not linear', () {
      // Midway between 1 kHz and 2 kHz in log space is ~1414 Hz, so the gain
      // there must be the average of the two endpoints.
      final pop = EqualizerPreset.pop;
      final atMid = pop.gainsFor([1414.21]).single;
      final at1k = pop.gainsFor([1000]).single;
      final at2k = pop.gainsFor([2000]).single;
      expect(atMid, closeTo((at1k + at2k) / 2, 0.01));
    });

    test('holds the endpoint value outside the reference range', () {
      // Devices report bands below 31 Hz and above 16 kHz; extrapolating there
      // would invent gains nobody authored.
      final low = EqualizerPreset.rock.gainsFor([10]).single;
      final high = EqualizerPreset.rock.gainsFor([22000]).single;
      expect(low, closeTo(EqualizerPreset.rock.referenceCurve!.first, 1e-9));
      expect(high, closeTo(EqualizerPreset.rock.referenceCurve!.last, 1e-9));
    });

    test('stays within the authored range for arbitrary frequencies', () {
      for (final preset in EqualizerPreset.selectable) {
        for (var hz = 20.0; hz < 20000; hz *= 1.3) {
          final gain = preset.gainsFor([hz]).single;
          expect(gain.abs(), lessThanOrEqualTo(8.0));
          expect(gain.isFinite, isTrue);
        }
      }
    });

    test('handles a single-band device without dividing by zero', () {
      final gains = EqualizerPreset.jazz.gainsFor([1000]);
      expect(gains, hasLength(1));
      expect(gains.single.isFinite, isTrue);
    });

    test('returns an empty result for a device reporting no bands', () {
      expect(EqualizerPreset.jazz.gainsFor(const []), isEmpty);
    });
  });

  group('fromId', () {
    test('round-trips every preset', () {
      for (final preset in EqualizerPreset.values) {
        expect(EqualizerPreset.fromId(preset.name), preset);
      }
    });

    test('falls back to custom for unknown or missing ids', () {
      // Protects restoration against a preset that was renamed or removed.
      expect(EqualizerPreset.fromId('deleted_preset'), EqualizerPreset.custom);
      expect(EqualizerPreset.fromId(null), EqualizerPreset.custom);
      expect(EqualizerPreset.fromId(''), EqualizerPreset.custom);
    });
  });
}
