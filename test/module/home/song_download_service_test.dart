import 'dart:convert';
import 'dart:io';

import 'package:beatx_flutter/module/home/model/downloaded_song_model.dart';
import 'package:beatx_flutter/module/home/services/song_download_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

DownloadedSong _song(String id, String fileName, {String cover = ''}) =>
    DownloadedSong(
      id: id,
      title: 'Title $id',
      artist: 'Artist',
      artworkUrl: 'https://example.com/$id.webp',
      fileName: fileName,
      coverFileName: cover,
      fileSize: 3,
      downloadedAt: DateTime.utc(2026, 9, 26),
    );

void main() {
  late Directory temp;
  late SongDownloadService service;

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('downloads_test');
    service = SongDownloadService(baseDirectory: () async => temp);
  });

  tearDown(() => temp.delete(recursive: true));

  group('audioExtension', () {
    test('takes the extension off a signed url path', () {
      expect(
        SongDownloadService.audioExtension(
          url:
              'https://bucket.s3.amazonaws.com/songs/audio/1789.flac'
              '?X-Amz-Signature=abc&x-id=GetObject',
          fallback: 'mp3',
        ),
        'flac',
      );
    });

    test('falls back to the content type, then the stream type', () {
      expect(
        SongDownloadService.audioExtension(
          url: 'https://example.com/stream/123',
          contentType: 'audio/mp4; charset=binary',
        ),
        'm4a',
      );
      expect(
        SongDownloadService.audioExtension(
          url: 'https://example.com/stream/123',
          fallback: 'MP3',
        ),
        'mp3',
      );
      expect(
        SongDownloadService.audioExtension(url: 'https://example.com/x'),
        'mp3',
      );
    });
  });

  test('progressOf never divides by an unknown total', () {
    expect(SongDownloadService.progressOf(50, 200), 0.25);
    expect(SongDownloadService.progressOf(50, -1), isNull);
    expect(SongDownloadService.progressOf(50, 0), isNull);
    expect(SongDownloadService.progressOf(300, 200), 1.0);
  });

  test('describes network and storage failures for the user', () {
    DioException dio(DioExceptionType type, [int? status]) => DioException(
      requestOptions: RequestOptions(),
      type: type,
      response: status == null
          ? null
          : Response(requestOptions: RequestOptions(), statusCode: status),
    );

    expect(
      SongDownloadService.describeDioError(
        dio(DioExceptionType.cancel),
      ).cancelled,
      isTrue,
    );
    expect(
      SongDownloadService.describeDioError(
        dio(DioExceptionType.connectionError),
      ).message,
      contains('No internet'),
    );
    expect(
      SongDownloadService.describeDioError(
        dio(DioExceptionType.badResponse, 403),
      ).message,
      contains('expired'),
    );
    expect(
      SongDownloadService.describeDioError(
        dio(DioExceptionType.badResponse, 503),
      ).message,
      contains('server'),
    );
    expect(
      SongDownloadService.describeFileError(
        const FileSystemException('write', '/x', OSError('No space', 28)),
      ).message,
      contains('storage'),
    );
  });

  test('rejects a url that is not http(s) before touching the network', () {
    expect(
      service.downloadAudio(songId: 'a', url: 'not a url', onProgress: (_) {}),
      throwsA(isA<SongDownloadException>()),
    );
  });

  test('index round-trips and drops entries whose audio is gone', () async {
    final dir = await service.root();
    await File('${dir.path}/a.flac').writeAsBytes([1, 2, 3]);
    await service.saveIndex([_song('a', 'a.flac'), _song('b', 'b.mp3')]);

    final loaded = await service.loadIndex();

    expect(loaded.map((song) => song.id), ['a']);
    expect(service.audioPath(loaded.single), '${dir.path}/a.flac');

    // The dropped entry is written out, not just skipped.
    final stored =
        jsonDecode(await File('${dir.path}/index.json').readAsString())
            as List;
    expect(stored, hasLength(1));
  });

  test('sweeps partial and unindexed files left by a killed app', () async {
    final dir = await service.root();
    await File('${dir.path}/a.flac').writeAsBytes([1]);
    await File('${dir.path}/covers/a.webp').writeAsBytes([1]);
    await File('${dir.path}/b.part').writeAsBytes([1]);
    await File('${dir.path}/c.mp3').writeAsBytes([1]);
    await File('${dir.path}/covers/c.webp').writeAsBytes([1]);
    await service.saveIndex([_song('a', 'a.flac', cover: 'a.webp')]);

    await service.loadIndex();

    final names = dir
        .listSync(recursive: true)
        .whereType<File>()
        .map((file) => file.path.substring(dir.path.length + 1))
        .toSet();
    expect(names, {'index.json', 'a.flac', 'covers/a.webp'});
  });

  test('a corrupt index reads as no downloads instead of throwing', () async {
    final dir = await service.root();
    await File('${dir.path}/index.json').writeAsString('{not json');
    expect(await service.loadIndex(), isEmpty);
  });
}
