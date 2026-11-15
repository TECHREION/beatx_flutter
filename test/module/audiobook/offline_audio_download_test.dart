import 'dart:io';

import 'package:beatx_flutter/core/api_handler/success.dart';
import 'package:beatx_flutter/core/helpers/typedefs.dart';
import 'package:beatx_flutter/module/audiobook/controller/audiobook_download_controller.dart';
import 'package:beatx_flutter/module/home/controller/download_controller.dart';
import 'package:beatx_flutter/module/home/model/offline_download_model.dart';
import 'package:beatx_flutter/module/home/services/listen_interface.dart';
import 'package:beatx_flutter/module/home/services/song_download_service.dart';
import 'package:beatx_flutter/module/podcast/controller/episode_download_controller.dart';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

/// The download endpoints, answering as the handoff doc describes: one file
/// for an episode, one per chapter (in order) for an audiobook.
final class _FakeApi extends ListenInterface {
  final contentTypes = <String>[];
  final deleted = <String>[];
  final reports = <String, bool>{};
  List<String>? syncedIds;
  DownloadSyncResult syncResult = const DownloadSyncResult();

  @override
  FutureRequest<Success<SongDownloadGrant>> createSongDownload({
    required String songId,
    required String deviceId,
    required String deviceName,
    String contentType = 'song',
  }) async {
    contentTypes.add(contentType);
    final body = {
      'download': {'_id': 'dl-$songId'},
      'files': contentType == 'audiobook'
          ? [
              // Out of order on purpose: trackNumber decides.
              for (final n in [2, 1, 3])
                {
                  'contentType': 'chapter',
                  'contentId': 'ch$n',
                  'title': 'Chapter $n',
                  'url': 'https://bucket.example.com/ch$n.mp3?sig=1',
                  'format': 'mp3',
                  'durationMs': n * 1000,
                  'trackNumber': n,
                },
            ]
          : [
              {
                'contentType': 'episode',
                'contentId': songId,
                'title': 'Episode',
                'url': 'https://bucket.example.com/$songId.mp3?sig=1',
                'format': 'mp3',
                'durationMs': 9000,
              },
            ],
    };
    return Right(Success(data: SongDownloadGrant.fromJson(body)));
  }

  @override
  FutureRequest<Success<void>> reportDownloadStatus(
    String downloadId, {
    required bool completed,
  }) async {
    reports[downloadId] = completed;
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
    return Right(Success(data: syncResult));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Writes a small file instead of going to the network; [failOn] fails that
/// file's download.
class _FakeFiles extends SongDownloadService {
  _FakeFiles(Directory base, {super.folder, this.failOn})
    : super(baseDirectory: () async => base);

  final String? failOn;

  @override
  Future<({String fileName, int fileSize})> downloadAudio({
    required String songId,
    required String url,
    String? fallbackExtension,
    required void Function(double? progress) onProgress,
    CancelToken? cancelToken,
  }) async {
    if (songId == failOn) {
      throw const SongDownloadException('The connection dropped.');
    }
    onProgress(1);
    final dir = await root();
    await File('${dir.path}/$songId.mp3').writeAsBytes([1, 2, 3, 4]);
    return (fileName: '$songId.mp3', fileSize: 4);
  }

  @override
  Future<String> downloadCover({
    required String songId,
    required String url,
    CancelToken? cancelToken,
  }) async => '';
}

const _book = DownloadRequest(
  songId: 'book1',
  title: 'The Long Road',
  artist: 'A. Writer',
);

const _episode = DownloadRequest(
  songId: 'ep1',
  title: 'Pilot',
  artist: 'The Show',
);

void main() {
  late Directory temp;
  late _FakeApi api;

  setUp(() async {
    Get.testMode = true;
    temp = await Directory.systemTemp.createTemp('offline_audio_test');
    api = _FakeApi();
    Get.put<ListenInterface>(api);
    Get.put(
      DownloadController(service: _FakeFiles(temp))..onInit(),
      permanent: true,
    );
  });

  tearDown(() async {
    Get.reset();
    await temp.delete(recursive: true);
  });

  AudiobookDownloadController books({String? failOn}) =>
      AudiobookDownloadController(
        service: _FakeFiles(
          temp,
          folder: 'audiobook_downloads',
          failOn: failOn,
        ),
      )..onInit();

  EpisodeDownloadController episodes() => EpisodeDownloadController(
    service: _FakeFiles(temp, folder: 'episode_downloads'),
  )..onInit();

  test('an episode is saved as one file under its own id', () async {
    final controller = episodes();
    expect(await controller.download(_episode), isNull);

    expect(api.contentTypes, ['episode']);
    expect(controller.files.single.id, 'ep1');
    expect(controller.files.single.durationMs, 9000);
    expect(controller.stateFor('ep1').status.value, DownloadStatus.downloaded);
    expect(
      await controller.playablePath('ep1'),
      endsWith('/episode_downloads/ep1.mp3'),
    );
  });

  test('an audiobook saves every chapter, in order, as one item', () async {
    final controller = books();
    expect(await controller.download(_book), isNull);

    expect(api.contentTypes, ['audiobook']);
    expect(api.reports, {'dl-book1': true});
    final item = controller.visibleItems.single;
    expect([for (final f in item) f.id], ['ch1', 'ch2', 'ch3']);
    expect(item.first.groupId, 'book1');
    expect(item.first.groupTitle, 'The Long Road');
    expect(
      controller.stateFor('book1').status.value,
      DownloadStatus.downloaded,
    );

    // Survives a restart, in order, and each chapter plays from its file.
    final restarted = books();
    await restarted.ready();
    expect([for (final f in restarted.files) f.id], ['ch1', 'ch2', 'ch3']);
    expect(
      await restarted.playablePath('ch2'),
      endsWith('/audiobook_downloads/ch2.mp3'),
    );
  });

  test('a chapter that fails leaves nothing half-saved', () async {
    final controller = books(failOn: 'ch2');
    final error = await controller.download(_book);

    expect(error, 'The connection dropped.');
    expect(controller.files, isEmpty);
    expect(controller.stateFor('book1').status.value, DownloadStatus.failed);
    expect(api.reports, {'dl-book1': false});
    expect(
      File('${temp.path}/audiobook_downloads/ch1.mp3').existsSync(),
      isFalse,
    );
  });

  test('removing a book deletes every chapter and tells the server', () async {
    final controller = books();
    await controller.download(_book);
    await controller.remove('book1');

    expect(api.deleted, ['dl-book1']);
    expect(controller.files, isEmpty);
    for (final n in [1, 2, 3]) {
      expect(
        File('${temp.path}/audiobook_downloads/ch$n.mp3').existsSync(),
        isFalse,
      );
    }
  });

  test('episodes and books join the check-in, once per download', () async {
    final bookDownloads = books();
    final episodeDownloads = episodes();
    await bookDownloads.download(_book);
    await episodeDownloads.download(_episode);

    api.syncResult = const DownloadSyncResult(remove: ['dl-book1']);
    await DownloadController.instance.syncWithServer();

    expect(api.syncedIds, unorderedEquals(['dl-book1', 'dl-ep1']));
    expect(bookDownloads.files, isEmpty);
    expect(episodeDownloads.files, hasLength(1));
  });
}
