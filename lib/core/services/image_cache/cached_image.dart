import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

/// Covers, thumbnails and avatars kept on disk, so an image is downloaded
/// once — not on every app start, nor every time it scrolls back into view.
///
/// The image host marks them `Cache-Control: immutable` (a changed image
/// gets a new url), so a file saved here never needs checking again. The
/// folder is the platform's cache directory, which the OS may clear when the
/// device runs low, and it is kept under [maxBytes] by dropping the least
/// recently used files.
class ImageDiskCache {
  ImageDiskCache._();

  /// A cache in [directory] rather than the app's cache folder, for tests.
  @visibleForTesting
  ImageDiskCache.at(
    Directory directory, {
    Future<Uint8List> Function(String url)? download,
  }) : _dir = Future.value(directory),
       _fetch = download;

  /// Replaces the network in tests.
  Future<Uint8List> Function(String url)? _fetch;

  static final instance = ImageDiskCache._();

  static const maxBytes = 250 * 1024 * 1024;

  Future<Directory>? _dir;
  final _inFlight = <String, Future<Uint8List>>{};
  final _client = HttpClient()
    ..connectionTimeout = const Duration(seconds: 20)
    ..idleTimeout = const Duration(seconds: 30);

  /// How many times the network was actually asked, for tests.
  @visibleForTesting
  int downloads = 0;

  Future<Directory> get _directory => _dir ??= () async {
    final base = await getApplicationCacheDirectory();
    final dir = Directory('${base.path}/image_cache');
    await dir.create(recursive: true);
    // Tidy up once per launch, off the critical path.
    unawaited(_prune(dir));
    return dir;
  }();

  /// The image at [url]: from disk when it has been fetched before, else
  /// downloaded (once, however many widgets ask at the same moment) and
  /// saved.
  Future<Uint8List> bytes(String url) =>
      // A block body, not `=> _inFlight.remove(url)`: that would return this
      // very future to whenComplete, which would then wait on itself forever.
      _inFlight[url] ??= _bytes(url).whenComplete(() {
        _inFlight.remove(url);
      });

  Future<Uint8List> _bytes(String url) async {
    final Directory dir;
    try {
      dir = await _directory;
    } catch (_) {
      // No cache folder (storage unavailable): show the image anyway, and try
      // the folder again next time.
      _dir = null;
      return _download(url);
    }
    final file = File('${dir.path}/${_fileName(url)}');
    try {
      if (await file.exists()) {
        final cached = await file.readAsBytes();
        if (cached.isNotEmpty) {
          // Touch it, so pruning treats it as recently used.
          unawaited(file.setLastModified(DateTime.now()).catchError((_) {}));
          return cached;
        }
      }
    } catch (_) {
      // Unreadable: fetch it again below.
    }

    final downloaded = await _download(url);
    // Written to a temporary name first, so a crash mid-write never leaves a
    // half image that would be served from then on.
    try {
      final temp = File('${file.path}.part');
      await temp.writeAsBytes(downloaded, flush: true);
      await temp.rename(file.path);
    } catch (_) {
      // Best effort: the image still shows; it is fetched again next time.
    }
    return downloaded;
  }

  Future<Uint8List> _download(String url) async {
    downloads++;
    final fetch = _fetch;
    if (fetch != null) return fetch(url);
    final request = await _client.getUrl(Uri.parse(url));
    final response = await request.close();
    if (response.statusCode != HttpStatus.ok) {
      await response.drain<void>();
      throw HttpException('Image ${response.statusCode}', uri: Uri.parse(url));
    }
    final bytes = await consolidateHttpClientResponseBytes(response);
    if (bytes.isEmpty) throw HttpException('Empty image', uri: Uri.parse(url));
    return bytes;
  }

  /// A stable, filesystem-safe name for [url] (64-bit FNV-1a, in hex, plus
  /// the length to make a collision even less likely).
  static String _fileName(String url) {
    var hash = 0xcbf29ce484222325;
    const prime = 0x100000001b3;
    for (final unit in url.codeUnits) {
      hash ^= unit;
      hash = (hash * prime) & 0xFFFFFFFFFFFFFFFF;
    }
    return '${hash.toUnsigned(64).toRadixString(16)}_${url.length}';
  }

  /// Deletes the least recently used files until the folder is under
  /// [maxBytes].
  static Future<void> _prune(Directory dir) async {
    try {
      final files = <(File, FileStat)>[];
      var total = 0;
      await for (final entity in dir.list()) {
        if (entity is! File) continue;
        final stat = await entity.stat();
        files.add((entity, stat));
        total += stat.size;
      }
      if (total <= maxBytes) return;
      files.sort((a, b) => a.$2.modified.compareTo(b.$2.modified));
      for (final (file, stat) in files) {
        if (total <= maxBytes * 0.8) break;
        await file.delete();
        total -= stat.size;
      }
    } catch (_) {
      // A cache that cannot be tidied still works.
    }
  }

  /// Empties the cache (for a "clear cache" setting).
  Future<void> clear() async {
    final dir = await _directory;
    try {
      await dir.delete(recursive: true);
      await dir.create(recursive: true);
    } catch (_) {}
  }
}

/// [NetworkImage], but served from [ImageDiskCache]: downloaded once, then
/// read from disk.
@immutable
class CachedNetworkImageProvider
    extends ImageProvider<CachedNetworkImageProvider> {
  const CachedNetworkImageProvider(this.url, {this.scale = 1.0});

  final String url;
  final double scale;

  @override
  Future<CachedNetworkImageProvider> obtainKey(
    ImageConfiguration configuration,
  ) => SynchronousFuture(this);

  @override
  ImageStreamCompleter loadImage(
    CachedNetworkImageProvider key,
    ImageDecoderCallback decode,
  ) {
    return MultiFrameImageStreamCompleter(
      codec: _load(decode),
      scale: scale,
      debugLabel: url,
      informationCollector: () => [DiagnosticsProperty('URL', url)],
    );
  }

  Future<ui.Codec> _load(ImageDecoderCallback decode) async {
    final bytes = await ImageDiskCache.instance.bytes(url);
    return decode(await ui.ImmutableBuffer.fromUint8List(bytes));
  }

  @override
  bool operator ==(Object other) =>
      other is CachedNetworkImageProvider &&
      other.url == url &&
      other.scale == scale;

  @override
  int get hashCode => Object.hash(url, scale);
}

/// Drop-in for `Image.network`, with the image kept on disk
/// ([ImageDiskCache]) and decoded at the size it is shown, so the in-memory
/// cache holds many more covers before it has to drop any.
abstract final class CachedImage {
  static Widget network(
    String src, {
    Key? key,
    BoxFit? fit,
    double? width,
    double? height,
    Color? color,
    AlignmentGeometry alignment = Alignment.center,
    ImageErrorWidgetBuilder? errorBuilder,
    ImageLoadingBuilder? loadingBuilder,
    ImageFrameBuilder? frameBuilder,
    int? cacheWidth,
    int? cacheHeight,
  }) {
    return _CachedNetworkImage(
      key: key,
      src: src,
      fit: fit,
      width: width,
      height: height,
      color: color,
      alignment: alignment,
      errorBuilder: errorBuilder,
      loadingBuilder: loadingBuilder,
      frameBuilder: frameBuilder,
      cacheWidth: cacheWidth,
      cacheHeight: cacheHeight,
    );
  }
}

class _CachedNetworkImage extends StatelessWidget {
  const _CachedNetworkImage({
    super.key,
    required this.src,
    this.fit,
    this.width,
    this.height,
    this.color,
    this.alignment = Alignment.center,
    this.errorBuilder,
    this.loadingBuilder,
    this.frameBuilder,
    this.cacheWidth,
    this.cacheHeight,
  });

  final String src;
  final BoxFit? fit;
  final double? width;
  final double? height;
  final Color? color;
  final AlignmentGeometry alignment;
  final ImageErrorWidgetBuilder? errorBuilder;
  final ImageLoadingBuilder? loadingBuilder;
  final ImageFrameBuilder? frameBuilder;
  final int? cacheWidth;
  final int? cacheHeight;

  @override
  Widget build(BuildContext context) {
    final provider = CachedNetworkImageProvider(src);
    if (cacheWidth != null || cacheHeight != null) {
      return _image(
        ResizeImage.resizeIfNeeded(cacheWidth, cacheHeight, provider),
      );
    }
    final w = width, h = height;
    if (w != null && w.isFinite && h != null && h.isFinite) {
      return _image(_sized(context, provider, math.max(w, h)));
    }
    // No size given: decode to the space it is laid out in.
    return LayoutBuilder(
      builder: (context, constraints) {
        final side = math.max(
          constraints.maxWidth.isFinite ? constraints.maxWidth : 0.0,
          constraints.maxHeight.isFinite ? constraints.maxHeight : 0.0,
        );
        return _image(side > 0 ? _sized(context, provider, side) : provider);
      },
    );
  }

  /// [provider] decoded no bigger than needed for [side] logical pixels
  /// (with room for a cover crop), keeping its aspect ratio.
  static ImageProvider _sized(
    BuildContext context,
    ImageProvider provider,
    double side,
  ) {
    final pixels = (side * MediaQuery.devicePixelRatioOf(context) * 1.5)
        .round()
        .clamp(64, 2048);
    return ResizeImage(
      provider,
      width: pixels,
      height: pixels,
      policy: ResizeImagePolicy.fit,
    );
  }

  Widget _image(ImageProvider image) => Image(
    image: image,
    fit: fit,
    width: width,
    height: height,
    color: color,
    alignment: alignment,
    errorBuilder: errorBuilder,
    loadingBuilder: loadingBuilder,
    frameBuilder: frameBuilder,
    gaplessPlayback: true,
  );
}
