import 'dart:io';
import 'dart:typed_data';

import 'package:beatx_flutter/core/services/image_cache/cached_image.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory dir;
  late int served;
  final png = Uint8List.fromList(List.generate(64, (i) => i));

  /// Stands in for the image host: counts requests, 404s for "missing".
  Future<Uint8List> host(String url) async {
    served++;
    await Future<void>.delayed(const Duration(milliseconds: 5));
    if (url.contains('missing')) {
      throw HttpException('Image 404', uri: Uri.parse(url));
    }
    return png;
  }

  setUp(() async {
    served = 0;
    dir = await Directory.systemTemp.createTemp('image_cache_test');
  });
  tearDown(() => dir.delete(recursive: true));

  const cover = 'https://cdn.example/covers/a.webp';

  test('downloads an image once, then reads it from disk', () async {
    final cache = ImageDiskCache.at(dir, download: host);

    expect(await cache.bytes(cover), png);
    expect(await cache.bytes(cover), png);
    expect(served, 1);

    // A new run (a fresh cache over the same folder) still has it.
    final afterRestart = ImageDiskCache.at(dir, download: host);
    expect(await afterRestart.bytes(cover), png);
    expect(served, 1);
    expect(afterRestart.downloads, 0);
  });

  test('asks once when several widgets want it at the same moment', () async {
    final cache = ImageDiskCache.at(dir, download: host);
    final results = await Future.wait([
      for (var i = 0; i < 5; i++) cache.bytes(cover),
    ]);
    expect(results.every((b) => b.length == png.length), isTrue);
    expect(served, 1);
  });

  test('a failed download is not saved, and is tried again', () async {
    final cache = ImageDiskCache.at(dir, download: host);
    const missing = 'https://cdn.example/covers/missing.webp';
    await expectLater(cache.bytes(missing), throwsA(isA<HttpException>()));
    await expectLater(cache.bytes(missing), throwsA(isA<HttpException>()));
    expect(served, 2);
    expect(dir.listSync().whereType<File>(), isEmpty);
  });
}
