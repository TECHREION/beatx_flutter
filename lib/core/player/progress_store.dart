import 'dart:async';
import 'dart:convert';

import 'package:app_pigeon/app_pigeon.dart';

/// Where playback reached, kept on this device for every song, episode and
/// chapter (by id).
///
/// The server keeps progress too, but a download played offline cannot
/// reach it — this is what lets that play resume next time all the same.
/// Each entry carries when it was written, so a caller holding a server
/// position can tell which of the two is newer.
class ProgressStore {
  ProgressStore._();

  static const _key = 'local_playback_progress';

  /// Enough for a long history without letting the store grow forever; the
  /// least recently written ids drop off first.
  static const _maxEntries = 400;

  /// How close to the end counts as finished: resuming there would only
  /// replay the last few seconds, so it starts over instead.
  static const nearEnd = Duration(seconds: 5);

  static const _storage = FlutterSecureStorage();

  /// id → (positionMs, written at ms since epoch). Insertion-ordered, oldest
  /// first.
  static final _entries = <String, (int, int)>{};
  static Future<void>? _loading;

  /// Loads what earlier runs saved. Safe to call any number of times.
  static Future<void> ready() => _loading ??= _restore();

  static Future<void> _restore() async {
    try {
      final stored = await _storage.read(key: _key);
      if (stored == null || stored.isEmpty) return;
      final decoded = jsonDecode(stored);
      if (decoded is! Map) return;
      decoded.forEach((id, value) {
        if (id is! String || value is! List || value.length != 2) return;
        final position = value[0], at = value[1];
        if (position is num && at is num) {
          // Anything written since launch is newer than the stored copy.
          _entries.putIfAbsent(id, () => (position.toInt(), at.toInt()));
        }
      });
    } catch (_) {
      // Unreadable (or no secure storage, as in tests): start empty.
    }
  }

  /// Records [positionMs] for [id]; a [completed] item is forgotten, so it
  /// starts over next time.
  static void save(String id, int positionMs, {bool completed = false}) {
    if (id.isEmpty) return;
    _entries.remove(id);
    if (!completed && positionMs > 0) {
      _entries[id] = (positionMs, DateTime.now().millisecondsSinceEpoch);
      while (_entries.length > _maxEntries) {
        _entries.remove(_entries.keys.first);
      }
    }
    // After the stored entries have loaded, or writing would drop them.
    unawaited(ready().then((_) => _persist()));
  }

  /// The position saved for [id] and when, or null when there is none.
  static ({Duration position, DateTime savedAt})? entry(String id) {
    final value = _entries[id];
    if (value == null) return null;
    return (
      position: Duration(milliseconds: value.$1),
      savedAt: DateTime.fromMillisecondsSinceEpoch(value.$2),
    );
  }

  /// Remembers which item of a collection (the chapter of a book) was played
  /// last. Stored as an entry of its own, keyed by the collection.
  static void setCurrent(String collectionKey, String itemId) {
    if (collectionKey.isEmpty || itemId.isEmpty) return;
    _currents[collectionKey] = itemId;
    // Stored alongside positions under a reserved prefix.
    save('$_currentPrefix$collectionKey|$itemId', 1);
  }

  /// The item of [collectionKey] played last on this device and when, or
  /// null.
  static ({String id, DateTime savedAt})? currentEntry(String collectionKey) {
    final id = currentOf(collectionKey);
    if (id == null) return null;
    final at = entry('$_currentPrefix$collectionKey|$id')?.savedAt;
    return (id: id, savedAt: at ?? DateTime.fromMillisecondsSinceEpoch(0));
  }

  /// The item of [collectionKey] played last on this device, or null.
  static String? currentOf(String collectionKey) {
    final cached = _currents[collectionKey];
    if (cached != null) return cached;
    final prefix = '$_currentPrefix$collectionKey|';
    String? found;
    for (final id in _entries.keys) {
      if (id.startsWith(prefix)) found = id.substring(prefix.length);
    }
    return found;
  }

  static const _currentPrefix = '@current:';
  static final _currents = <String, String>{};

  /// Where to start an item that reached [position] of [length]: there, or
  /// the beginning when it was (nearly) finished or never started.
  static Duration resumeFrom(Duration position, Duration length) {
    if (position <= Duration.zero) return Duration.zero;
    if (length > Duration.zero && position >= length - nearEnd) {
      return Duration.zero;
    }
    return position;
  }

  /// Where to start [id]: from the server's position or the one kept on
  /// this device, whichever was saved later. The device's wins when the
  /// server has none (a download played offline) or did not answer.
  ///
  /// [server] is null when the server could not be asked.
  static Duration choose({
    required String id,
    required Duration length,
    ({Duration position, bool completed, DateTime? savedAt})? server,
  }) {
    final local = entry(id);
    final serverAt = server?.savedAt;
    final useLocal =
        local != null &&
        (server == null ||
            (server.position <= Duration.zero && !server.completed) ||
            (serverAt != null && local.savedAt.isAfter(serverAt)));
    if (useLocal) return resumeFrom(local.position, length);
    if (server == null || server.completed) return Duration.zero;
    return resumeFrom(server.position, length);
  }

  /// Forgets everything — on logout, since it belongs to that account.
  static Future<void> clear() async {
    _entries.clear();
    _currents.clear();
    try {
      await _storage.delete(key: _key);
    } catch (_) {}
  }

  static Future<void> _persist() async {
    try {
      await _storage.write(
        key: _key,
        value: jsonEncode({
          for (final MapEntry(:key, :value) in _entries.entries)
            key: [value.$1, value.$2],
        }),
      );
    } catch (_) {
      // Best effort: the position still holds for the rest of this run.
    }
  }
}
