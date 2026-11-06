import 'package:flutter/material.dart';

/// A remote picture that fills its parent, or [icon] when there is none or it
/// fails to load.
class ShopImage extends StatelessWidget {
  const ShopImage({
    super.key,
    required this.url,
    this.icon = Icons.image_rounded,
    this.background = const Color(0xFF1E1E25),
    this.iconColor = Colors.white24,
  });

  final String? url;
  final IconData icon;
  final Color background;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    final fallback = ColoredBox(
      color: background,
      child: Center(child: Icon(icon, color: iconColor, size: 36)),
    );
    final source = url;
    if (source == null || source.isEmpty) return fallback;

    return Image.network(
      source,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => fallback,
      loadingBuilder: (_, child, progress) =>
          progress == null ? child : ColoredBox(color: background),
    );
  }
}

/// The centred message for an empty or failed list.
class ShopMessage extends StatelessWidget {
  const ShopMessage({
    super.key,
    required this.icon,
    required this.message,
    this.onRetry,
  });

  final IconData icon;
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white30, size: 40),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFFA7A3AA),
              fontSize: 14,
              height: 1.4,
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 12),
            TextButton(
              onPressed: onRetry,
              child: const Text(
                'Try Again',
                style: TextStyle(
                  color: Color(0xFF3BDDEB),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class ShopLoading extends StatelessWidget {
  const ShopLoading({super.key});

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.all(40),
    child: Center(child: CircularProgressIndicator(color: Color(0xFF3BDDEB))),
  );
}

/// "Load more" under a paged list, or nothing once all of it is showing.
class ShopLoadMore extends StatelessWidget {
  const ShopLoadMore({
    super.key,
    required this.hasMore,
    required this.isLoading,
    required this.onTap,
  });

  final bool hasMore;
  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (!hasMore) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Center(
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF3BDDEB),
                ),
              )
            : TextButton(
                onPressed: onTap,
                child: const Text(
                  'Load more',
                  style: TextStyle(
                    color: Color(0xFF3BDDEB),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
      ),
    );
  }
}
