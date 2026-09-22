import 'dart:convert';

import 'package:beatx_flutter/core/player/equalizer/equalizer_store.dart';
import 'package:beatx_flutter/core/player/equalizer/models/equalizer_preset.dart';
import 'package:beatx_flutter/core/player/equalizer/models/equalizer_settings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EqualizerSettings serialization', () {
    test('round-trips through JSON', () {
      const original = EqualizerSettings(
        enabled: true,
        preset: EqualizerPreset.rock,
        gains: [1, -2, 3.5, 0, -4],
      );

      final restored = EqualizerSettings.fromJson(
        jsonDecode(jsonEncode(original.toJson())),
      );

      expect(restored, isNotNull);
      expect(restored!.enabled, isTrue);
      expect(restored.preset, EqualizerPreset.rock);
      expect(restored.gains, [1, -2, 3.5, 0, -4]);
    });

    test('preserves the band count, which is what makes gains portable or not',
        () {
      final restored = EqualizerSettings.fromJson(
        jsonDecode(
          jsonEncode(
            EqualizerSettings(
              preset: EqualizerPreset.custom,
              gains: List<double>.filled(10, 1),
            ).toJson(),
          ),
        ),
      );
      expect(restored!.gains, hasLength(10));
    });

    test('rejects a blob from a different schema version', () {
      final future = {
        'schemaVersion': EqualizerSettings.schemaVersion + 1,
        'enabled': true,
        'preset': 'rock',
        'gains': <double>[1, 2, 3],
      };
      expect(EqualizerSettings.fromJson(future), isNull);
    });

    test('rejects structurally wrong payloads rather than half-reading them',
        () {
      expect(EqualizerSettings.fromJson(null), isNull);
      expect(EqualizerSettings.fromJson('not a map'), isNull);
      expect(EqualizerSettings.fromJson(<String, dynamic>{}), isNull);
      expect(
        EqualizerSettings.fromJson({
          'schemaVersion': EqualizerSettings.schemaVersion,
          'gains': 'not a list',
        }),
        isNull,
      );
      expect(
        EqualizerSettings.fromJson({
          'schemaVersion': EqualizerSettings.schemaVersion,
          'gains': [1, 'two', 3],
        }),
        isNull,
      );
    });

    test('falls back to custom for an unknown preset id', () {
      final restored = EqualizerSettings.fromJson({
        'schemaVersion': EqualizerSettings.schemaVersion,
        'enabled': false,
        'preset': 'preset_that_no_longer_exists',
        'gains': <double>[0, 0, 0],
      });
      expect(restored!.preset, EqualizerPreset.custom);
    });

    test('treats a missing enabled flag as off', () {
      final restored = EqualizerSettings.fromJson({
        'schemaVersion': EqualizerSettings.schemaVersion,
        'preset': 'normal',
        'gains': <double>[0],
      });
      expect(restored!.enabled, isFalse);
    });

    test('accepts integer gains, which is how JSON encodes whole numbers', () {
      final restored = EqualizerSettings.fromJson({
        'schemaVersion': EqualizerSettings.schemaVersion,
        'enabled': true,
        'preset': 'normal',
        'gains': [1, 2, 3],
      });
      expect(restored!.gains, [1.0, 2.0, 3.0]);
    });

    test('copyWith replaces only what it is given', () {
      const base = EqualizerSettings(
        enabled: true,
        preset: EqualizerPreset.jazz,
        gains: [1, 2],
      );
      final updated = base.copyWith(enabled: false);
      expect(updated.enabled, isFalse);
      expect(updated.preset, EqualizerPreset.jazz);
      expect(updated.gains, [1, 2]);
    });
  });

  group('EqualizerStore', () {
    // No plugin is registered in a unit test, so the secure-storage channel
    // throws MissingPluginException. That is exactly the failure the store has
    // to absorb: a broken keystore must never stop the app from starting.
    test('returns null instead of throwing when storage is unavailable',
        () async {
      expect(await EqualizerStore().read(), isNull);
    });

    test('a failed write is swallowed rather than surfaced mid-drag', () async {
      await expectLater(
        EqualizerStore().write(const EqualizerSettings()),
        completes,
      );
    });

    test('a failed clear is swallowed', () async {
      await expectLater(EqualizerStore().clear(), completes);
    });
  });
}
