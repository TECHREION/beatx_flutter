import 'dart:io';

import 'package:beatx_flutter/core/api_handler/failure.dart';
import 'package:beatx_flutter/core/api_handler/success.dart';
import 'package:beatx_flutter/core/helpers/typedefs.dart';
import 'package:beatx_flutter/module/home/controller/download_controller.dart';
import 'package:beatx_flutter/module/home/model/miusic_stream.dart';
import 'package:beatx_flutter/module/home/services/listen_interface.dart';
import 'package:beatx_flutter/module/home/services/song_download_service.dart';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

/// Answers the stream-url request; every other endpoint is unused here.
final class _FakeListen extends ListenInterface {
  bool offline = false;
  int streamRequests = 0;

  @override
  FutureRequest<Success<SongStreamUrlModel>> getListenStreamUrl(
    String listenId,
  ) async {
    streamRequests++;
    if (offline) {
      return Left(
        DataCRUDFailure(
          failure: Failure.socketFailure,
          fullError: 'No internet connection.',
        ),
      );
    }
    return Right(
      Success(
        data: SongStreamUrlModel(
          streamUrl: 'https://bucket.example.com/songs/audio/$listenId.flac',
          durationMs: 1000,
          streamType: 'mp3',
        ),
      ),
    );
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
    expect(
      restarted.stateFor('song1').status.value,
      DownloadStatus.downloaded,
    );
  });

  test('a second tap while downloaded does not download again', () async {
    final ctrl = newController();
    await ctrl.download(_request);
    await ctrl.download(_request);
    expect(listen.streamRequests, 1);
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
}
