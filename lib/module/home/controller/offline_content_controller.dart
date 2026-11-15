import 'dart:async';
import 'dart:io';

import 'package:app_pigeon/app_pigeon.dart';
import 'package:get/get.dart';

import '../model/downloaded_song_model.dart';
import '../model/offline_download_model.dart';
import '../services/listen_interface.dart';
import '../services/lister_interface_impl.dart';
import '../services/song_download_service.dart';
import 'download_controller.dart';

/// Offline downloads for one kind of content other than songs (videos,
/// podcast episodes, audiobooks), over the same `POST /downloads` flow.
///
/// Each kind keeps its own private folder and list, but shares the songs'
/// device id and check-in: the account counts this install as one device,
/// and a stale check-in hides every kind alike.
///
/// An item is one download. Most have one file, saved under the item's id;
/// an audiobook has one per chapter, saved under the chapter's id with
/// [DownloadedSong.groupId] pointing back at the book. Everything here that
/// takes an `itemId` means the item; `fileId` means one saved file.
abstract class OfflineContentController extends GetxController {
  OfflineContentController({
    required this.contentType,
    required SongDownloadService service,
    required this.noun,
  }) : _service = service;

  /// What `POST /downloads` calls this kind: `video`, `episode`, `audiobook`.
  final String contentType;

  /// How messages name an item: "video", "episode", "audiobook".
  final String noun;

  final SongDownloadService _service;

  /// Every saved file, newest item first, an item's files in order.
  final files = <DownloadedSong>[].obs;
  final isReady = false.obs;

  final _states = <String, SongDownloadState>{};
  final _cancelTokens = <String, CancelToken>{};
  Future<void>? _loading;
  Future<void> _indexWrite = Future.value();

  DownloadController get _songs => DownloadController.instance;

  /// The saved files the user may play now: none while the downloads are
  /// locked for want of a check-in.
  List<DownloadedSong> get visibleFiles =>
      _songs.isLocked.value ? const [] : files.toList();

  /// [visibleFiles] gathered by item, newest first, each item's files in
  /// order.
  List<List<DownloadedSong>> get visibleItems {
    final items = <String, List<DownloadedSong>>{};
    for (final file in visibleFiles) {
      items.putIfAbsent(file.itemId, () => []).add(file);
    }
    return items.values.toList();
  }

  int get totalBytes => files.fold(0, (sum, file) => sum + file.fileSize);

  ListenInterface _api() {
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
    _songs.addOtherDownloads(
      contentType,
      ids: () => {
        for (final file in files)
          if (file.downloadId.isNotEmpty) file.downloadId,
      }.toList(),
      onRemoved: (removed) async {
        for (final itemId in {
          for (final file in files)
            if (removed.contains(file.downloadId)) file.itemId,
        }) {
          await _forget(itemId, tellServer: false);
        }
      },
    );
    ready();
  }

  /// Completes once the saved list has been read. Safe to call repeatedly.
  Future<void> ready() => _loading ??= _load();

  Future<void> _load() async {
    try {
      final loaded = await _service.loadIndex();
      // Newest item first; a chapter keeps its place within its book.
      final order = <String, DateTime>{};
      for (final file in loaded) {
        final at = order[file.itemId];
        if (at == null || file.downloadedAt.isAfter(at)) {
          order[file.itemId] = file.downloadedAt;
        }
      }
      loaded.sort((a, b) {
        final byItem = order[b.itemId]!.compareTo(order[a.itemId]!);
        if (byItem != 0) return byItem;
        if (a.itemId != b.itemId) return a.itemId.compareTo(b.itemId);
        return a.trackNumber.compareTo(b.trackNumber);
      });
      files.assignAll(loaded);
      for (final file in loaded) {
        stateFor(file.itemId).status.value = DownloadStatus.downloaded;
      }
    } catch (_) {
      // Storage unreadable: nothing reads as downloaded; streaming still works.
    }
    isReady.value = true;
  }

  SongDownloadState stateFor(String itemId) =>
      _states.putIfAbsent(itemId, SongDownloadState.new);

  /// The saved files of [itemId], in order.
  List<DownloadedSong> filesOf(String itemId) =>
      files.where((file) => file.itemId == itemId).toList();

  String filePath(DownloadedSong file) => _service.audioPath(file);

  /// The saved cover if it is still on disk, else null.
  String? coverPath(DownloadedSong file) {
    final path = _service.coverPath(file);
    if (path == null || !File(path).existsSync()) return null;
    return path;
  }

  /// The file to play [fileId] from, or null to stream it. A file removed
  /// behind the app's back drops its whole item, so playback falls back to
  /// streaming and the item can be downloaded again.
  Future<String?> playablePath(String fileId) async {
    await ready();
    if (_songs.isLocked.value) return null;
    final file = files.firstWhereOrNull((entry) => entry.id == fileId);
    if (file == null) return null;
    final path = filePath(file);
    if (File(path).existsSync()) return path;
    await _forget(file.itemId);
    return null;
  }

  /// Downloads an item. Returns a message to show when it fails, or null when
  /// it finished, was cancelled, or was already saved or running.
  ///
  /// [request]'s `songId` is the item's id, `artist` the channel, show or
  /// author.
  Future<String?> download(DownloadRequest request) async {
    await ready();
    final itemId = request.songId;
    final state = stateFor(itemId);
    if (state.status.value == DownloadStatus.downloading) return null;
    if (state.status.value == DownloadStatus.downloaded &&
        await _isComplete(itemId)) {
      return null;
    }

    final cancelToken = CancelToken();
    _cancelTokens[itemId] = cancelToken;
    state
      ..request = request
      ..error.value = ''
      ..progress.value = 0
      ..status.value = DownloadStatus.downloading;

    var downloadId = '';
    final saved = <DownloadedSong>[];
    try {
      // Signed for an hour, so every attempt (and Retry) gets fresh links;
      // asking again for the same item refreshes the record, no duplicate.
      final grantResult = await _api().createSongDownload(
        songId: itemId,
        contentType: contentType,
        deviceId: await _songs.deviceId(),
        deviceName: DownloadController.deviceName,
      );
      final grant = grantResult.fold(
        (failure) => throw SongDownloadException(failure.uiMessage),
        (success) => success.data,
      );
      downloadId = grant?.downloadId ?? '';
      if (cancelToken.isCancelled) {
        throw const SongDownloadException('', cancelled: true);
      }

      final parts = _partsOf(grant);
      if (parts.isEmpty) {
        throw SongDownloadException('This $noun has nothing to download yet.');
      }
      final single = parts.length == 1;

      final coverFileName = await _service.downloadCover(
        songId: itemId,
        url: request.coverUrl,
        cancelToken: cancelToken,
      );
      final now = DateTime.now();

      for (var i = 0; i < parts.length; i++) {
        final part = parts[i];
        final fileId = single || part.contentId.isEmpty
            ? (single ? itemId : '$itemId-${i + 1}')
            : part.contentId;
        final file = await _service.downloadAudio(
          songId: fileId,
          url: part.url,
          fallbackExtension: part.format,
          cancelToken: cancelToken,
          // Each file is an equal share; a book's chapters are similar enough.
          onProgress: (value) => state.progress.value = value == null
              ? (i == 0 ? null : i / parts.length)
              : (i + value) / parts.length,
        );
        saved.add(
          DownloadedSong(
            id: fileId,
            downloadId: downloadId,
            title: single || part.title.isEmpty
                ? (single ? request.title : 'Chapter ${i + 1}')
                : part.title,
            artist: request.artist,
            artworkUrl: request.coverUrl,
            fileName: file.fileName,
            coverFileName: coverFileName,
            fileSize: file.fileSize,
            durationMs: part.durationMs ?? (single ? request.durationMs : 0),
            genre: request.genre,
            downloadedAt: now,
            groupId: single ? '' : itemId,
            groupTitle: single ? '' : request.title,
            trackNumber: single
                ? 0
                : (part.trackNumber > 0 ? part.trackNumber : i + 1),
          ),
        );
      }

      files
        ..removeWhere((entry) => entry.itemId == itemId)
        ..insertAll(0, saved);
      try {
        await _persist();
      } catch (_) {
        files.removeWhere((entry) => entry.itemId == itemId);
        throw SongDownloadException(
          'The $noun could not be saved on this device.',
        );
      }

      state
        ..progress.value = 1
        ..status.value = DownloadStatus.downloaded;
      _report(downloadId, completed: true);
      return null;
    } on SongDownloadException catch (error) {
      await _discard(saved, itemId);
      if (error.cancelled) {
        state
          ..progress.value = null
          ..status.value = DownloadStatus.notDownloaded;
        // Otherwise the record keeps holding one of the account's slots.
        if (downloadId.isNotEmpty) {
          unawaited(_api().deleteDownload(downloadId));
        }
        return null;
      }
      _report(downloadId, completed: false);
      return _fail(state, error.message);
    } catch (_) {
      await _discard(saved, itemId);
      _report(downloadId, completed: false);
      return _fail(state, 'Download failed. Tap Retry.');
    } finally {
      _cancelTokens.remove(itemId);
    }
  }

  /// The files to fetch: the grant's list, or its lone link from an older
  /// server that only sent one.
  static List<DownloadGrantFile> _partsOf(SongDownloadGrant? grant) {
    if (grant == null) return const [];
    if (grant.files.isNotEmpty) {
      final parts = grant.files.toList();
      // Chapters arrive in order; trackNumber only confirms it.
      if (parts.every((part) => part.trackNumber > 0)) {
        parts.sort((a, b) => a.trackNumber.compareTo(b.trackNumber));
      }
      return parts;
    }
    if (grant.url.isEmpty) return const [];
    return [
      DownloadGrantFile(
        contentId: '',
        url: grant.url,
        format: grant.format,
        durationMs: grant.durationMs,
      ),
    ];
  }

  /// Deletes files saved by an attempt that did not finish, unless they are
  /// what the list already holds for the item.
  Future<void> _discard(List<DownloadedSong> saved, String itemId) async {
    final kept = {for (final file in filesOf(itemId)) file.fileName};
    for (final file in saved) {
      if (!kept.contains(file.fileName)) {
        await _service.delete(
          DownloadedSong(
            id: file.id,
            title: file.title,
            artist: file.artist,
            artworkUrl: '',
            fileName: file.fileName,
            fileSize: 0,
            downloadedAt: file.downloadedAt,
          ),
        );
      }
    }
  }

  Future<bool> _isComplete(String itemId) async {
    final saved = filesOf(itemId);
    if (saved.isEmpty) return false;
    for (final file in saved) {
      if (await playablePath(file.id) == null) return false;
    }
    return true;
  }

  void _report(String downloadId, {required bool completed}) {
    if (downloadId.isEmpty) return;
    unawaited(_api().reportDownloadStatus(downloadId, completed: completed));
  }

  String _fail(SongDownloadState state, String message) {
    state
      ..progress.value = null
      ..error.value = message
      ..status.value = DownloadStatus.failed;
    return message;
  }

  Future<String?> retry(String itemId) async {
    final request = stateFor(itemId).request;
    if (request == null) return 'Nothing to retry for this $noun.';
    return download(request);
  }

  /// Stops a running download; partial files are deleted.
  void cancel(String itemId) => _cancelTokens[itemId]?.cancel();

  /// Deletes the saved files. The item stays available online.
  Future<void> remove(String itemId) async {
    final state = stateFor(itemId);
    if (state.status.value == DownloadStatus.downloading) {
      cancel(itemId);
      return;
    }
    await _forget(itemId);
    state
      ..progress.value = null
      ..error.value = ''
      ..status.value = DownloadStatus.notDownloaded;
  }

  Future<void> _forget(String itemId, {bool tellServer = true}) async {
    final gone = filesOf(itemId);
    files.removeWhere((entry) => entry.itemId == itemId);
    stateFor(itemId).status.value = DownloadStatus.notDownloaded;
    for (final file in gone) {
      await _service.delete(file);
    }
    final downloadIds = {
      for (final file in gone)
        if (file.downloadId.isNotEmpty) file.downloadId,
    };
    if (tellServer) {
      for (final id in downloadIds) {
        unawaited(_api().deleteDownload(id));
      }
    }
    try {
      await _persist();
    } catch (_) {
      // Rechecked against the disk on the next launch.
    }
  }

  Future<void> _persist() {
    final snapshot = files.toList();
    final write = _indexWrite.then((_) => _service.saveIndex(snapshot));
    _indexWrite = write.catchError((_) {});
    return write;
  }

  @override
  void onClose() {
    for (final token in _cancelTokens.values) {
      token.cancel();
    }
    super.onClose();
  }
}
