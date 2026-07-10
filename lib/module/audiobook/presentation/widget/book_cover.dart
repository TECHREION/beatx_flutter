import 'package:flutter/material.dart';

/// Remote cover art with a branded placeholder while loading and on failure.
class BookCover extends StatelessWidget {
  const BookCover({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.iconSize = 54,
    this.alignment = Alignment.center,
  });

  final String url;
  final BoxFit fit;
  final double iconSize;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) return _CoverPlaceholder(iconSize: iconSize);

    return Image.network(
      url,
      fit: fit,
      alignment: alignment,
      loadingBuilder: (context, child, progress) =>
          progress == null ? child : _CoverPlaceholder(iconSize: iconSize),
      errorBuilder: (context, error, stackTrace) =>
          _CoverPlaceholder(iconSize: iconSize),
    );
  }
}

class _CoverPlaceholder extends StatelessWidget {
  const _CoverPlaceholder({required this.iconSize});

  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF202020),
      child: Center(
        child: Icon(
          Icons.menu_book_rounded,
          color: Colors.white38,
          size: iconSize,
        ),
      ),
    );
  }
}
