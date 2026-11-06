import 'dart:async';
import 'dart:io';

import 'package:app_pigeon/app_pigeon.dart';
import 'package:get/get.dart';

import '../../../core/api_handler/failure.dart';
import '../model/downloaded_song_model.dart';
import '../services/listen_interface.dart';
import '../services/lister_interface_impl.dart';
import '../services/song_download_service.dart';

enum DownloadStatus { notDownloaded, downloading, downloaded, failed }

/// What is needed to (re)start a download. Kept on the song's state so Retry
/// can run again without the screen that started it.
class DownloadRequest {
  const DownloadRequest({
    required this.songId,
    required this.title,
    required this.artist,
    this.coverUrl = '',
    this.durationMs = 0,
    this.genre = '',
  });

  final String songId;
  final String title;
  final String artist;
  final String coverUrl;
  final int durationMs;
  final String genre;
}

/// One song's download state. Each song has its own observables, so a widget
/// showing one song's progress rebuilds only when that song's download moves.
class SongDownloadState {
  final status = DownloadStatus.notDownloaded.obs;

  /// 0–1 while downloading, or null while the total size is unknown.
  final progress = RxnDouble();

  /// Why the last attempt failed, or empty.
  final error = ''.obs;

  DownloadRequest? request;
  CancelToken? _cancelToken;

  /// Whole percent for display. Never NaN: an unknown size reads as null.
  int? get percent {
    final value = progress.value;
    return value == null ? null : (value * 100).floor().clamp(0, 100);
  }
}

/// Offline downloads for songs: starts, tracks, retries, cancels and removes
/// them, and answers whether a song can play from the device.
///
/// The downloaded list is kept in [SongDownloadService]'s index, so it
/// survives restarts and is readable with no connection at all.
class DownloadController extends GetxController {
  DownloadController({SongDownloadService? service})
    : _service = service ?? SongDownloadService();

  /// The shared instance, registered on first use.
  static DownloadController get instance {
    if (!Get.isRegistered<DownloadController>()) {
      Get.put(DownloadController(), permanent: true);
    }
    return Get.find<DownloadController>();
  }

  final SongDownloadService _service;

  /// Every saved song, newest first.
  final songs = <DownloadedSong>[].obs;

  /// False until the saved list has been read from disk.
  final isReady = false.obs;

  /// True when the downloads went too long without checking in with the
  /// server. They are hidden, not deleted, until the next successful sync.
  final isLocked = false.obs;

  /// The saved songs the user may see and play right now.
  List<DownloadedSong> get visibleSongs =>
      isLocked.value ? const [] : songs.toList();

  final _states = <String, SongDownloadState>{};
  Future<void>? _loading;
  Future<void>? _syncing;

  /// Index writes are chained so two downloads finishing together cannot
  /// interleave their writes.
  Future<void> _indexWrite = Future.value();

  ListenInterface _listenInterface() {
    if (!Get.isRegistered<ListenInterface>() &&
        Get.isRegistered<AuthorizedPigeon>()) {
      Get.put<ListenInterface>(
        ListenInterfaceImpl(Get.find<AuthorizedPigeon>()),
      );
    }
    return Get.find<ListenInterface>();
  }

  @override
  void onInit() {
    super.onInit();
    ready();
  }

  /// Completes once the saved list has been read. Safe to call repeatedly.
  Future<void> ready() => _loading ??= _load();

  Future<void> _load() async {
    try {
      final loaded = await _service.loadIndex();
      loaded.sort((a, b) => b.downloadedAt.compareTo(a.downloadedAt));
      songs.assignAll(loaded);
      for (final song in loaded) {
        stateFor(song.id).status.value = DownloadStatus.downloaded;
      }
      await _applyValidity();
    } catch (_) {
      // Storage unreadable: nothing reads as downloaded, and streaming is
      // unaffected.
    }
    isReady.value = true;
  }

  Future<void> _applyValidity() async {
    final validUntil = await _service.validUntil();
    isLocked.value = validUntil != null && DateTime.now().isAfter(validUntil);
  }

  /// Checks the saved songs in with the server. Run on every launch with a
  /// signed-in user; a second call joins one already running.
  Future<void> syncWithServer() =>
      _syncing ??= _sync().whenComplete(() => _syncing = null);

  Future<void> _sync() async {
    await ready();
    try {
      final deviceId = await _service.deviceId();
      await _registerUntrackedSongs(deviceId);

      final result = await _listenInterface().syncDownloads(
        deviceId: deviceId,
        downloadIds: [
          for (final song in songs)
            if (song.downloadId.isNotEmpty) song.downloadId,
        ],
      );
      final sync = result.fold((_) => null, (success) => success.data);
      if (sync != null) {
        // Taken down, deleted, or removed from the website.
        final removed = sync.remove.toSet();
        for (final song in songs.toList()) {
          if (removed.contains(song.downloadId)) {
            await _forget(song, tellServer: false);
          }
        }
        await _service.saveValidUntil(sync.validUntil);
      }
      await _applyValidity();
    } catch (_) {
      // Storage trouble. The next launch tries again.
    }
  }

  /// Gives songs saved before downloads were tracked a server record, so the
  /// sync can cover them too. One the server says is not available (404) is no
  /// longer published, so it goes the way of anything the sync says to remove.
  /// Any other failure is left for the next sync.
  Future<void> _registerUntrackedSongs(String deviceId) async {
    final untracked = songs.where((song) => song.downloadId.isEmpty).toList();
    for (final song in untracked) {
      final result = await _listenInterface().createSongDownload(
        songId: song.id,
        deviceId: deviceId,
        deviceName: _deviceName,
      );
      final unavailable = result.fold(
        (failure) => failure.failure == Failure.notFound,
        (_) => false,
      );
      if (unavailable) {
        await _forget(song, tellServer: false);
        continue;
      }

      final downloadId = result.fold(
        (_) => '',
        (success) => success.data?.downloadId ?? '',
      );
      if (downloadId.isEmpty) continue;

      final index = songs.indexWhere((entry) => entry.id == song.id);
      if (index >= 0) songs[index] = song.withDownloadId(downloadId);
      await _listenInterface().reportDownloadStatus(
        downloadId,
        completed: true,
      );
    }
    if (untracked.isNotEmpty) await _persist();
  }

  /// How this install is named on the website's device list.
  static String get _deviceName {
    if (Platform.isIOS) return 'BeatX on iOS';
    if (Platform.isAndroid) return 'BeatX on Android';
    return 'BeatX app';
  }

  /// The observable state for [songId], created on first ask.
  SongDownloadState stateFor(String songId) =>
      _states.putIfAbsent(songId, SongDownloadState.new);

  DownloadedSong? _find(String songId) =>
      songs.firstWhereOrNull((song) => song.id == songId);

  int get totalBytes => songs.fold(0, (sum, song) => sum + song.fileSize);

  String audioPath(DownloadedSong song) => _service.audioPath(song);

  /// The saved cover if it is still on disk, else null.
  String? coverPath(DownloadedSong song) {
    final path = _service.coverPath(song);
    if (path == null || !File(path).existsSync()) return null;
    return path;
  }

  /// The download to play [songId] from, or null to stream it.
  ///
  /// Checks the file is really there first. If it was removed behind the
  /// app's back, the stale entry is dropped and the song reads as not
  /// downloaded, so playback falls back to streaming instead of failing.
  Future<DownloadedSong?> playableDownload(String songId) async {
    await ready();
    if (isLocked.value) return null;
    final song = _find(songId);
    if (song == null) return null;
    if (File(audioPath(song)).existsSync()) return song;

    await _forget(song);
    return null;
  }

  /// Downloads a song. Returns a message to show when it fails, or null when
  /// it finished, was cancelled, or was already downloaded or running.
  Future<String?> download(DownloadRequest request) async {
    await ready();

    final state = stateFor(request.songId);
    final status = state.status.value;
    if (status == DownloadStatus.downloading) return null;
    if (status == DownloadStatus.downloaded) {
      if (await playableDownload(request.songId) != null) return null;
    }

    final cancelToken = CancelToken();
    state
      ..request = request
      .._cancelToken = cancelToken
      ..error.value = ''
      ..progress.value = 0
      ..status.value = DownloadStatus.downloading;

    var downloadId = '';
    try {
      // The link is signed and expires within the hour, so a fresh one is
      // fetched for every attempt — which is also what makes Retry recover
      // from an expired link. Repeating this for a song does not add a record.
      final grantResult = await _listenInterface().createSongDownload(
        songId: request.songId,
        deviceId: await _service.deviceId(),
        deviceName: _deviceName,
      );
      final grant = grantResult.fold(
        (failure) => throw SongDownloadException(failure.uiMessage),
        (success) => success.data,
      );
      downloadId = grant?.downloadId ?? '';
      final url = grant?.url ?? '';
      if (cancelToken.isCancelled) {
        throw const SongDownloadException('', cancelled: true);
      }

      final audio = await _service.downloadAudio(
        songId: request.songId,
        url: url,
        fallbackExtension: grant?.format,
        cancelToken: cancelToken,
        onProgress: (value) => state.progress.value = value,
      );

      final coverFileName = await _service.downloadCover(
        songId: request.songId,
        url: request.coverUrl,
        cancelToken: cancelToken,
      );

      final song = DownloadedSong(
        id: request.songId,
        downloadId: downloadId,
        title: request.title,
        artist: request.artist,
        artworkUrl: request.coverUrl,
        fileName: audio.fileName,
        coverFileName: coverFileName,
        fileSize: audio.fileSize,
        durationMs: grant?.durationMs ?? request.durationMs,
        genre: request.genre,
        downloadedAt: DateTime.now(),
      );

      songs
        ..removeWhere((entry) => entry.id == song.id)
        ..insert(0, song);
      try {
        await _persist();
      } catch (_) {
        // Without an index entry the file would be swept as an orphan on
        // the next launch anyway; undo now so the state stays honest.
        songs.removeWhere((entry) => entry.id == song.id);
        await _service.delete(song);
        throw const SongDownloadException(
          'The song could not be saved on this device.',
        );
      }

      state
        ..progress.value = 1
        ..status.value = DownloadStatus.downloaded;
      _reportResult(downloadId, completed: true);
      return null;
    } on SongDownloadException catch (error) {
      if (error.cancelled) {
        state
          ..progress.value = null
          ..status.value = DownloadStatus.notDownloaded;
        // The record would otherwise hold one of the account's device slots.
        if (downloadId.isNotEmpty) {
          unawaited(_listenInterface().deleteDownload(downloadId));
        }
        return null;
      }
      _reportResult(downloadId, completed: false);
      return _fail(state, error.message);
    } catch (_) {
      _reportResult(downloadId, completed: false);
      return _fail(state, 'Download failed. Tap Retry.');
    } finally {
      state._cancelToken = null;
    }
  }

  /// Tells the server how the attempt ended. Best effort: the outcome on this
  /// device does not depend on it.
  void _reportResult(String downloadId, {required bool completed}) {
    if (downloadId.isEmpty) return;
    unawaited(
      _listenInterface().reportDownloadStatus(downloadId, completed: completed),
    );
  }

  String _fail(SongDownloadState state, String message) {
    state
      ..progress.value = null
      ..error.value = message
      ..status.value = DownloadStatus.failed;
    return message;
  }

  /// Runs the last failed download for [songId] again.
  Future<String?> retry(String songId) async {
    final request = stateFor(songId).request;
    if (request == null) return 'Nothing to retry for this song.';
    return download(request);
  }

  /// Stops a running download. The partial file is deleted.
  void cancel(String songId) {
    stateFor(songId)._cancelToken?.cancel();
  }

  /// Deletes the saved file and its entry. The song itself stays available
  /// online. A download still running is cancelled instead.
  Future<void> remove(String songId) async {
    final state = stateFor(songId);
    if (state.status.value == DownloadStatus.downloading) {
      cancel(songId);
      return;
    }

    final song = _find(songId);
    if (song != null) await _forget(song);

    state
      ..progress.value = null
      ..error.value = ''
      ..status.value = DownloadStatus.notDownloaded;
  }

  Future<void> _forget(DownloadedSong song, {bool tellServer = true}) async {
    songs.removeWhere((entry) => entry.id == song.id);
    stateFor(song.id).status.value = DownloadStatus.notDownloaded;
    await _service.delete(song);
    if (tellServer && song.downloadId.isNotEmpty) {
      // Best effort, so removing a download also works offline.
      unawaited(_listenInterface().deleteDownload(song.downloadId));
    }
    try {
      await _persist();
    } catch (_) {
      // The entry is rechecked against the disk on the next launch.
    }
  }

  Future<void> _persist() {
    final snapshot = songs.toList();
    final write = _indexWrite.then((_) => _service.saveIndex(snapshot));
    // A failed write must not poison the chain for the next one.
    _indexWrite = write.catchError((_) {});
    return write;
  }

  @override
  void onClose() {
    for (final state in _states.values) {
      state._cancelToken?.cancel();
    }
    super.onClose();
  }
}
