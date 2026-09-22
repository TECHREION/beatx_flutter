import 'dart:convert';

import 'package:app_pigeon/app_pigeon.dart';
import 'package:flutter/foundation.dart';

import 'models/equalizer_settings.dart';

/// Persists the equalizer configuration between launches.
///
/// Uses the same `FlutterSecureStorage` the rest of the app already relies on
/// (see `PlayerController`'s measured-duration cache and the language
/// controller) rather than introducing a second key-value store.
class EqualizerStore {
  EqualizerStore({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const storageKey = 'equalizer_settings';

  final FlutterSecureStorage _storage;

  /// Reads stored settings, or null when there is nothing usable to restore.
  ///
  /// Any failure — missing key, corrupt JSON, schema bump, unreadable
  /// keystore — resolves to null. A broken preference must never stop the app
  /// from starting or playing.
  Future<EqualizerSettings?> read() async {
    try {
      final stored = await _storage.read(key: storageKey);
      if (stored == null || stored.isEmpty) return null;
      return EqualizerSettings.fromJson(jsonDecode(stored));
    } catch (error) {
      if (kDebugMode) {
        debugPrint('[Equalizer] could not read stored settings: $error');
      }
      return null;
    }
  }

  /// Writes [settings], best effort.
  ///
  /// A failed write costs the user their settings at next launch, which is not
  /// worth surfacing mid-drag, so it is logged in debug and swallowed.
  Future<void> write(EqualizerSettings settings) async {
    try {
      await _storage.write(
        key: storageKey,
        value: jsonEncode(settings.toJson()),
      );
    } catch (error) {
      if (kDebugMode) {
        debugPrint('[Equalizer] could not persist settings: $error');
      }
    }
  }

  Future<void> clear() async {
    try {
      await _storage.delete(key: storageKey);
    } catch (error) {
      if (kDebugMode) {
        debugPrint('[Equalizer] could not clear settings: $error');
      }
    }
  }
}
