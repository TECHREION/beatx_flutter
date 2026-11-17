import 'package:flutter/material.dart';
import 'package:beatx_flutter/core/services/image_cache/cached_image.dart';

/// An image from the API (`http…`) or a bundled asset path; empty or broken
/// sources show [fallback].
Widget artistImage(
  String src, {
  required Widget fallback,
  BoxFit fit = BoxFit.cover,
  double? width,
  double? height,
}) {
  if (src.isEmpty) {
    return SizedBox(width: width, height: height, child: fallback);
  }
  Widget onError(BuildContext _, Object _, StackTrace? _) =>
      SizedBox(width: width, height: height, child: fallback);
  return src.startsWith('http')
      ? CachedImage.network(
          src,
          fit: fit,
          width: width,
          height: height,
          errorBuilder: onError,
        )
      : Image.asset(
          src,
          fit: fit,
          width: width,
          height: height,
          errorBuilder: onError,
        );
}

/// The [ImageProvider] for [src], or null when there is none.
ImageProvider? artistImageProvider(String src) {
  if (src.isEmpty) return null;
  return src.startsWith('http')
      ? CachedNetworkImageProvider(src)
      : AssetImage(src);
}
