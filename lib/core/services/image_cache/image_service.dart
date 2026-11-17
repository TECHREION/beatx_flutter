import 'package:flutter/foundation.dart';

import 'cached_image.dart';

/// Image bytes for [SmartNetworkImage], from the shared disk cache
/// ([ImageDiskCache]) so they survive restarts.
///
/// The few most recent are also held in memory; the cap keeps a long
/// session from holding every image it has ever shown.
class ImageService {
  static final ImageService _instance = ImageService._internal();
  factory ImageService() => _instance;
  ImageService._internal();

  static const _memoryLimit = 40;

  /// Insertion-ordered: the first entry is the least recently used.
  final Map<String, Uint8List> _memoryCache = {};

  Future<Uint8List?> fetchImage(String url) async {
    if (url.isEmpty) return null;
    final hit = _memoryCache.remove(url);
    if (hit != null) return _memoryCache[url] = hit;

    try {
      final bytes = await ImageDiskCache.instance.bytes(url);
      _memoryCache[url] = bytes;
      while (_memoryCache.length > _memoryLimit) {
        _memoryCache.remove(_memoryCache.keys.first);
      }
      return bytes;
    } catch (_) {
      return null;
    }
  }
}
