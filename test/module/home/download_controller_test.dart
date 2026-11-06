import 'dart:io';

import 'package:beatx_flutter/core/api_handler/failure.dart';
import 'package:beatx_flutter/core/api_handler/success.dart';
import 'package:beatx_flutter/core/helpers/typedefs.dart';
import 'package:beatx_flutter/module/home/controller/download_controller.dart';
import 'package:beatx_flutter/module/home/model/downloaded_song_model.dart';
import 'package:beatx_flutter/module/home/model/offline_download_model.dart';
import 'package:beatx_flutter/module/home/services/listen_interface.dart';
import 'package:beatx_flutter/module/home/services/song_download_service.dart';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

/// Answers the download endpoints; every other endpoint is unused here.
final class _FakeListen extends ListenInterface {
  bool offline = false;
  final notOnServer = <String>{};
  int downloadRequests = 0;
  final reported = <String, bool>{};
  final deleted = <String>[];
  List<String>? syncedIds;
  DownloadSyncResult? syncResult;

  Left<DataCRUDFailure, T> _noInternet<T>() => Left(
    DataCRUDFailure(
      failure: Failure.socketFailure,
      fullError: 'No internet connection.',
    ),
  );

  @override
  FutureRequest<Success<SongDownloadGrant>> createSongDownload({
    required String songId,
    required String deviceId,
    required String deviceName,
  }) async {
    downloadRequests++;
    if (offline) return _noInternet();
    if (notOnServer.contains(songId)) {
      return Left(
        DataCRUDFailure(
          failure: Failure.notFound,
          fullError: 'This is not available to download',
        ),
      );
    }
    return Right(
      Success(
        data: SongDownloadGrant(
          downloadId: 'dl-$songId',
          url: 'https://bucket.example.com/songs/audio/$songId.flac',
          format: 'mp3',
          durationMs: 1000,
        ),
      ),
    );
  }

  @override
  FutureRequest<Success<void>> reportDownloadStatus(
    String downloadId, {
    required bool completed,
  }) async {
    reported[downloadId] = completed;
    return Right(Success<void>());
  }

  @override
  FutureRequest<Success<void>> deleteDownload(String downloadId) async {
    deleted.add(downloadId);
    return Right(Success<void>());
  }

  @override
  FutureRequest<Success<DownloadSyncResult>> syncDownloads({
    required String deviceId,
    required List<String> downloadIds,
  }) async {
    syncedIds = downloadIds;
    if (offline) return _noInternet();
    return Right(Success(data: syncResult ?? const DownloadSyncResult()));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Writes a small file instead of going to the network.
class _FakeService extends SongDownloadService {
  _FakeService(Directory base) : super(baseDirectory: () async => base);

  SongDownloadException? nextError;
  final progressSeen = <double?>[];

  @override
  Future<({String fileName, int fileSize})> downloadAudio({
    required String songId,
    required String url,
    String? fallbackExtension,
    required void Function(double? progress) onProgress,
    CancelToken? cancelToken,
  }) async {
    final error = nextError;
    if (error != null) {
      nextError = null;
      throw error;
    }
    for (final value in [0.25, 0.5, 1.0]) {
      onProgress(value);
      progressSeen.add(value);
    }
    final dir = await root();
    final extension = SongDownloadService.audioExtension(url: url);
    await File('${dir.path}/$songId.$extension').writeAsBytes([1, 2, 3, 4]);
    return (fileName: '$songId.$extension', fileSize: 4);
  }

  @override
  Future<String> downloadCover({
    required String songId,
    required String url,
    CancelToken? cancelToken,
  }) async => '';
}

const _request = DownloadRequest(
  songId: 'song1',
  title: 'Aniket Prantor',
  artist: 'Artcell',
  coverUrl: 'https://example.com/cover.webp',
);

void main() {
  late Directory temp;
  late _FakeListen listen;
  late _FakeService service;

  setUp(() async {
    Get.testMode = true;
    temp = await Directory.systemTemp.createTemp('download_ctrl_test');
    listen = _FakeListen();
    service = _FakeService(temp);
    Get.put<ListenInterface>(listen);
  });

  tearDown(() async {
    Get.reset();
    await temp.delete(recursive: true);
  });

  DownloadController newController() =>
      DownloadController(service: service)..onInit();

  test('downloads, reports progress and survives a restart', () async {
    final ctrl = newController();

    expect(await ctrl.download(_request), isNull);

    final state = ctrl.stateFor('song1');
    expect(state.status.value, DownloadStatus.downloaded);
    expect(state.percent, 100);
    expect(service.progressSeen, [0.25, 0.5, 1.0]);
    // Saved under the url's real extension, not the backend's "mp3".
    expect(ctrl.songs.single.fileName, 'song1.flac');

    final restarted = newController();
    final playable = await restarted.playableDownload('song1');
    expect(playable?.title, 'Aniket Prantor');
    expect(restarted.stateFor('song1').status.value, DownloadStatus.downloaded);
  });

  test('a second tap while downloaded does not download again', () async {
    final ctrl = newController();
    await ctrl.download(_request);
    await ctrl.download(_request);
    expect(listen.downloadRequests, 1);
  });

  test('offline fails with a message, and retry recovers', () async {
    final ctrl = newController();
    listen.offline = true;

    final error = await ctrl.download(_request);
    expect(error, contains('No internet'));
    expect(ctrl.stateFor('song1').status.value, DownloadStatus.failed);
    expect(ctrl.stateFor('song1').percent, isNull);

    listen.offline = false;
    expect(await ctrl.retry('song1'), isNull);
    expect(ctrl.stateFor('song1').status.value, DownloadStatus.downloaded);
  });

  test('a cancelled download returns to not downloaded silently', () async {
    final ctrl = newController();
    service.nextError = const SongDownloadException('', cancelled: true);

    expect(await ctrl.download(_request), isNull);
    expect(ctrl.stateFor('song1').status.value, DownloadStatus.notDownloaded);
  });

  test('remove deletes the file and the entry', () async {
    final ctrl = newController();
    await ctrl.download(_request);
    final path = ctrl.audioPath(ctrl.songs.single);

    await ctrl.remove('song1');

    expect(File(path).existsSync(), isFalse);
    expect(ctrl.songs, isEmpty);
    expect(ctrl.stateFor('song1').status.value, DownloadStatus.notDownloaded);
    expect(await newController().playableDownload('song1'), isNull);
  });

  test('a file deleted behind the app falls back to streaming', () async {
    final ctrl = newController();
    await ctrl.download(_request);
    await File(ctrl.audioPath(ctrl.songs.single)).delete();

    expect(await ctrl.playableDownload('song1'), isNull);
    expect(ctrl.songs, isEmpty);
    expect(ctrl.stateFor('song1').status.value, DownloadStatus.notDownloaded);
  });

  test('downloads of different songs keep separate state', () async {
    final ctrl = newController();
    listen.offline = true;
    await ctrl.download(_request);
    listen.offline = false;
    await ctrl.download(
      const DownloadRequest(songId: 'song2', title: 'Two', artist: 'B'),
    );

    expect(ctrl.stateFor('song1').status.value, DownloadStatus.failed);
    expect(ctrl.stateFor('song2').status.value, DownloadStatus.downloaded);
    expect(ctrl.totalBytes, 4);
  });

  test('a finished download is reported and carries its server id', () async {
    final ctrl = newController();
    await ctrl.download(_request);

    expect(ctrl.songs.single.downloadId, 'dl-song1');
    expect(listen.reported, {'dl-song1': true});
  });

  test('a failed file download is reported as failed', () async {
    final ctrl = newController();
    service.nextError = const SongDownloadException('Broken');

    expect(await ctrl.download(_request), 'Broken');
    expect(listen.reported, {'dl-song1': false});
  });

  test('cancelling frees the server record', () async {
    final ctrl = newController();
    service.nextError = const SongDownloadException('', cancelled: true);

    await ctrl.download(_request);
    expect(listen.deleted, ['dl-song1']);
  });

  test('removing a download also deletes the server record', () async {
    final ctrl = newController();
    await ctrl.download(_request);

    await ctrl.remove('song1');
    expect(listen.deleted, ['dl-song1']);
  });

  test('sync deletes what the server says to remove, and only that', () async {
    final ctrl = newController();
    await ctrl.download(_request);
    await ctrl.download(
      const DownloadRequest(songId: 'song2', title: 'Two', artist: 'B'),
    );
    final removedPath = ctrl.audioPath(
      ctrl.songs.firstWhere((song) => song.id == 'song1'),
    );
    listen.syncResult = const DownloadSyncResult(remove: ['dl-song1']);

    await ctrl.syncWithServer();

    expect(listen.syncedIds, unorderedEquals(['dl-song1', 'dl-song2']));
    expect(File(removedPath).existsSync(), isFalse);
    expect(ctrl.songs.map((song) => song.id), ['song2']);
    expect(ctrl.stateFor('song1').status.value, DownloadStatus.notDownloaded);
    // The server already dropped it; it must not be asked to again.
    expect(listen.deleted, isEmpty);
  });

  test('songs saved before tracking are registered by the sync', () async {
    final first = newController();
    await first.download(_request);
    await service.saveIndex([
      DownloadedSong.fromJson({
        ...first.songs.single.toJson(),
        'downloadId': '',
      }),
    ]);
    listen.reported.clear();

    final restarted = newController();
    await restarted.syncWithServer();

    expect(restarted.songs.single.downloadId, 'dl-song1');
    expect(listen.syncedIds, ['dl-song1']);
    expect(listen.reported, {'dl-song1': true});
    // Persisted, so the next launch does not register it again.
    expect((await service.loadIndex()).single.downloadId, 'dl-song1');
  });

  group('a song saved before tracking', () {
    Future<DownloadController> restartedWithUntrackedSong() async {
      final first = newController();
      await first.download(_request);
      await service.saveIndex([
        DownloadedSong.fromJson({
          ...first.songs.single.toJson(),
          'downloadId': '',
        }),
      ]);
      return newController();
    }

    test('is removed when the server no longer has it', () async {
      final restarted = await restartedWithUntrackedSong();
      await restarted.ready();
      final path = restarted.audioPath(restarted.songs.single);
      listen.notOnServer.add('song1');
      final asked = listen.downloadRequests;

      await restarted.syncWithServer();

      expect(File(path).existsSync(), isFalse);
      expect(restarted.songs, isEmpty);
      expect(
        restarted.stateFor('song1').status.value,
        DownloadStatus.notDownloaded,
      );
      expect(listen.deleted, isEmpty);

      // Gone for good, so the next launch does not ask about it again.
      await restarted.syncWithServer();
      expect(listen.downloadRequests, asked + 1);
    });

    test('is kept when the server cannot be reached', () async {
      final restarted = await restartedWithUntrackedSong();
      listen.offline = true;

      await restarted.syncWithServer();

      expect(restarted.songs, hasLength(1));
      expect(restarted.songs.single.downloadId, isEmpty);
    });
  });

  test('past validUntil the songs hide until a sync succeeds', () async {
    final ctrl = newController();
    await ctrl.download(_request);
    listen.syncResult = DownloadSyncResult(
      validUntil: DateTime.now().subtract(const Duration(minutes: 1)),
    );
    await ctrl.syncWithServer();

    final locked = newController();
    expect(await locked.playableDownload('song1'), isNull);
    expect(locked.isLocked.value, isTrue);
    expect(locked.visibleSongs, isEmpty);
    // Hidden, not deleted.
    expect(locked.songs, hasLength(1));

    // Still offline: nothing changes.
    listen.offline = true;
    await locked.syncWithServer();
    expect(locked.isLocked.value, isTrue);

    listen.offline = false;
    listen.syncResult = DownloadSyncResult(
      validUntil: DateTime.now().add(const Duration(days: 30)),
    );
    await locked.syncWithServer();
    expect(locked.isLocked.value, isFalse);
    expect((await locked.playableDownload('song1'))?.id, 'song1');
  });

  test('the device id is stable and survives the orphan sweep', () async {
    final id = await service.deviceId();
    expect(id, hasLength(32));

    await service.loadIndex();
    expect(await service.deviceId(), id);
  });
}
