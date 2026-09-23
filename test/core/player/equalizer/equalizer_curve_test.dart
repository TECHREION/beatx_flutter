import 'package:beatx_flutter/core/player/equalizer/equalizer_curve.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('kDisplayFrequenciesHz', () {
    test('matches the iOS engine, so the mapping there is the identity', () {
      // EqualizerEngine.frequencies in ios/Runner/Equalizer/EqualizerEngine.swift.
      expect(kDisplayFrequenciesHz, [
        31,
        62,
        125,
        250,
        500,
        1000,
        2000,
        4000,
        8000,
        16000,
      ]);
      expect(kDisplayMinDb, -12);
      expect(kDisplayMaxDb, 12);
    });
  });

  group('resampleCurve', () {
    test('is the identity when the frequencies match', () {
      const gains = <double>[1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
      expect(
        resampleCurve(
          gains,
          fromHz: kDisplayFrequenciesHz,
          toHz: kDisplayFrequenciesHz,
        ),
        gains,
      );
    });

    test('projects the ten display bands onto a five-band device', () {
      // The band layout the user's Android phone reports.
      const deviceHz = <double>[60, 230, 910, 3600, 14000];
      final gains = resampleCurve(
        List<double>.filled(kDisplayFrequenciesHz.length, 6),
        fromHz: kDisplayFrequenciesHz,
        toHz: deviceHz,
      );

      expect(gains, hasLength(5));
      // A flat curve stays flat wherever it is sampled.
      expect(gains, everyElement(closeTo(6, 1e-9)));
    });

    test('interpolates in log-frequency space, not linear', () {
      // One octave up from 31 Hz is 62 Hz, so the midpoint of that span sits
      // at sqrt(31*62) Hz — not at (31+62)/2.
      const curve = <double>[0, 10, 10, 10, 10, 10, 10, 10, 10, 10];
      final geometricMid = resampleCurve(
        curve,
        fromHz: kDisplayFrequenciesHz,
        toHz: const [43.8],
      ).single;
      expect(geometricMid, closeTo(5, 0.05));

      // Linear interpolation would have put the halfway point at 46.5 Hz.
      final linearMid = resampleCurve(
        curve,
        fromHz: kDisplayFrequenciesHz,
        toHz: const [46.5],
      ).single;
      expect(linearMid, greaterThan(5.5));
    });

    test('holds the endpoints rather than extrapolating past them', () {
      const curve = <double>[4, 0, 0, 0, 0, 0, 0, 0, 0, -4];
      expect(
        resampleCurve(curve, fromHz: kDisplayFrequenciesHz, toHz: const [20]),
        [4],
      );
      expect(
        resampleCurve(curve, fromHz: kDisplayFrequenciesHz, toHz: const [22000]),
        [-4],
      );
    });

    test('carries a shaped curve across a coarser device', () {
      // Bass Booster: lifted low end, flat top.
      const bassBooster = <double>[7, 6, 5, 3, 1, 0, 0, 0, 0, 0];
      final gains = resampleCurve(
        bassBooster,
        fromHz: kDisplayFrequenciesHz,
        toHz: const [60, 230, 910, 3600, 14000],
      );

      expect(gains.first, greaterThan(3), reason: '60 Hz should stay boosted');
      expect(gains.last, closeTo(0, 1e-9), reason: '14 kHz should stay flat');
      // The shape is preserved: each band sits no higher than the one below.
      for (var i = 1; i < gains.length; i++) {
        expect(gains[i], lessThanOrEqualTo(gains[i - 1] + 1e-9));
      }
    });

    test('returns nothing when there is nowhere to sample', () {
      expect(
        resampleCurve(const [1, 2], fromHz: const [100, 200], toHz: const []),
        isEmpty,
      );
    });
  });

  group('clampCurve', () {
    test('fits a curve into a narrower device range', () {
      expect(clampCurve(const [10, -10, 2], -4, 4), [4, -4, 2]);
    });

    test('leaves a curve that already fits alone', () {
      expect(clampCurve(const [1, -1, 0], -12, 12), [1, -1, 0]);
    });
  });
}
