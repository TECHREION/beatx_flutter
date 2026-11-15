import 'dart:io';

import 'package:beatx_flutter/core/api_handler/success.dart';
import 'package:beatx_flutter/core/helpers/typedefs.dart';
import 'package:beatx_flutter/module/home/controller/download_controller.dart';
import 'package:beatx_flutter/module/home/model/offline_download_model.dart';
import 'package:beatx_flutter/module/home/services/listen_interface.dart';
import 'package:beatx_flutter/module/home/services/song_download_service.dart';
import 'package:beatx_flutter/module/watch/controller/video_download_controller.dart';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

/// The download endpoints, as the live server answers them for a video.
final class _FakeApi extends ListenInterface {
  final contentTypes = <String>[];
  final deviceIds = <String>[];
  final deleted = <String>[];
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
    deviceIds.add(deviceId);
    return Right(
      Success(
        data: SongDownloadGrant(
          downloadId: 'dl-$songId',
          // The backend hands out the uploaded source file.
          url: 'https://bucket.example.com/videos/source/$songId.mov?sig=1',
          format: 'mp4',
          durationMs: 5000,
        ),
      ),
    );
  }

  @override
  FutureRequest<Success<void>> reportDownloadStatus(
    String downloadId, {
    required bool completed,
  }) async => Right(Success<void>());

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

/// Writes a small file instead of going to the network.
class _FakeFiles extends SongDownloadService {
  _FakeFiles(Directory base, {super.folder, super.video})
    : super(baseDirectory: () async => base);

  @override
  Future<({String fileName, int fileSize})> downloadAudio({
    required String songId,
    required String url,
    String? fallbackExtension,
    required void Function(double? progress) onProgress,
    CancelToken? cancelToken,
  }) async {
    onProgress(1);
    final dir = await root();
    final ext = SongDownloadService.videoExtension(url: url);
    await File('${dir.path}/$songId.$ext').writeAsBytes([1, 2, 3]);
    return (fileName: '$songId.$ext', fileSize: 3);
  }

  @override
  Future<String> downloadCover({
    required String songId,
    required String url,
    CancelToken? cancelToken,
  }) async => '';
}

const _request = DownloadRequest(
  songId: 'v1',
  title: 'Live at the Arena',
  artist: 'Artcell',
  coverUrl: 'https://example.com/v1.webp',
);

void main() {
  late Directory temp;
  late _FakeApi api;

  setUp(() async {
    Get.testMode = true;
    temp = await Directory.systemTemp.createTemp('video_download_test');
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

  VideoDownloadController newController() => VideoDownloadController(
    service: _FakeFiles(temp, folder: 'video_downloads', video: true),
  )..onInit();

  test('downloads a video as a video, under the songs\' device id', () async {
    final videos = newController();
    expect(await videos.download(_request), isNull);

    expect(api.contentTypes, ['video']);
    expect(api.deviceIds.single, await DownloadController.instance.deviceId());
    expect(videos.stateFor('v1').status.value, DownloadStatus.downloaded);
    expect(videos.videos.single.fileName, 'v1.mov');

    // Survives a restart, and plays from the file.
    final restarted = newController();
    final path = await restarted.playablePath('v1');
    expect(path, endsWith('/video_downloads/v1.mov'));
  });

  test('joins the check-in, and drops what the server removes', () async {
    final videos = newController();
    await videos.download(_request);

    api.syncResult = const DownloadSyncResult(remove: ['dl-v1']);
    await DownloadController.instance.syncWithServer();

    expect(api.syncedIds, contains('dl-v1'));
    expect(videos.videos, isEmpty);
    expect(videos.stateFor('v1').status.value, DownloadStatus.notDownloaded);
  });

  test('removing a download tells the server', () async {
    final videos = newController();
    await videos.download(_request);
    await videos.remove('v1');

    expect(api.deleted, ['dl-v1']);
    expect(await videos.playablePath('v1'), isNull);
  });

  test('video file types are recognised', () {
    expect(SongDownloadService.videoExtension(url: 'https://x/a.MP4'), 'mp4');
    expect(
      SongDownloadService.videoExtension(
        url: 'https://x/source',
        contentType: 'video/quicktime',
      ),
      'mov',
    );
    expect(SongDownloadService.videoExtension(url: 'https://x/source'), 'mp4');
  });
}
