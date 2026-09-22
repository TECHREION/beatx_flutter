import 'package:beatx_flutter/core/player/equalizer/equalizer_validation.dart';
import 'package:beatx_flutter/core/player/equalizer/models/equalizer_exception.dart';
import 'package:flutter_test/flutter_test.dart';

/// The contract these tests pin down is *rejection*, not correction: an out of
/// range gain must throw so the bug surfaces, never be quietly clamped into
/// something that sounds different from what the caller asked for.
void main() {
  Matcher throwsKind(EqualizerErrorKind kind) => throwsA(
        isA<EqualizerException>().having((e) => e.kind, 'kind', kind),
      );

  group('bandIndex', () {
    test('accepts every index the device reports', () {
      for (var i = 0; i < 5; i++) {
        expect(() => EqualizerValidation.bandIndex(i, 5), returnsNormally);
      }
    });

    test('rejects a negative index', () {
      expect(
        () => EqualizerValidation.bandIndex(-1, 5),
        throwsKind(EqualizerErrorKind.invalidBandIndex),
      );
    });

    test('rejects an index equal to the band count', () {
      expect(
        () => EqualizerValidation.bandIndex(5, 5),
        throwsKind(EqualizerErrorKind.invalidBandIndex),
      );
    });

    test('rejects a far out of range index', () {
      expect(
        () => EqualizerValidation.bandIndex(9999, 5),
        throwsKind(EqualizerErrorKind.invalidBandIndex),
      );
    });

    test('rejects any index when the device reports no bands', () {
      expect(
        () => EqualizerValidation.bandIndex(0, 0),
        throwsKind(EqualizerErrorKind.invalidBandIndex),
      );
    });
  });

  group('gain', () {
    test('accepts the boundary values themselves', () {
      expect(() => EqualizerValidation.gain(-12, -12, 12), returnsNormally);
      expect(() => EqualizerValidation.gain(12, -12, 12), returnsNormally);
      expect(() => EqualizerValidation.gain(0, -12, 12), returnsNormally);
    });

    test('rejects a gain above the device maximum', () {
      expect(
        () => EqualizerValidation.gain(12.1, -12, 12),
        throwsKind(EqualizerErrorKind.gainOutOfRange),
      );
    });

    test('rejects a gain below the device minimum', () {
      expect(
        () => EqualizerValidation.gain(-12.1, -12, 12),
        throwsKind(EqualizerErrorKind.gainOutOfRange),
      );
    });

    test('honours a narrower device range rather than a fixed +/-12', () {
      // Plenty of Android devices report a tighter range than the spec's
      // +/-12 dB, and the device always wins.
      expect(
        () => EqualizerValidation.gain(11, -10, 10),
        throwsKind(EqualizerErrorKind.gainOutOfRange),
      );
      expect(() => EqualizerValidation.gain(10, -10, 10), returnsNormally);
    });

    test('rejects NaN, which slips past a naive range comparison', () {
      expect(
        () => EqualizerValidation.gain(double.nan, -12, 12),
        throwsKind(EqualizerErrorKind.gainOutOfRange),
      );
    });

    test('rejects infinities', () {
      expect(
        () => EqualizerValidation.gain(double.infinity, -12, 12),
        throwsKind(EqualizerErrorKind.gainOutOfRange),
      );
      expect(
        () => EqualizerValidation.gain(double.negativeInfinity, -12, 12),
        throwsKind(EqualizerErrorKind.gainOutOfRange),
      );
    });

    test('does not clamp: the value is refused, not rewritten', () {
      // Guards against a future "helpful" clamp being reintroduced.
      Object? thrown;
      try {
        EqualizerValidation.gain(50, -12, 12);
      } catch (error) {
        thrown = error;
      }
      expect(thrown, isA<EqualizerException>());
    });
  });

  group('gainVector', () {
    test('accepts one valid gain per band', () {
      expect(
        () => EqualizerValidation.gainVector([0, 1, -1, 2, -2], 5, -12, 12),
        returnsNormally,
      );
    });

    test('rejects too few gains', () {
      expect(
        () => EqualizerValidation.gainVector([0, 0], 5, -12, 12),
        throwsKind(EqualizerErrorKind.bandCountMismatch),
      );
    });

    test('rejects too many gains', () {
      // The 10-point preset curves must be resampled onto the device's real
      // bands, never handed over raw.
      expect(
        () => EqualizerValidation.gainVector(
          List<double>.filled(10, 0),
          5,
          -12,
          12,
        ),
        throwsKind(EqualizerErrorKind.bandCountMismatch),
      );
    });

    test('rejects the whole vector when a single entry is out of range', () {
      expect(
        () => EqualizerValidation.gainVector([0, 0, 99, 0, 0], 5, -12, 12),
        throwsKind(EqualizerErrorKind.gainOutOfRange),
      );
    });
  });
}
