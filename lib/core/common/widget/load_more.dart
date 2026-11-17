import 'package:flutter/material.dart';

/// Calls [onLoadMore] as the scroll view inside nears its end, so the next
/// page is on its way before the user reaches the bottom.
///
/// Wrap the list's scroll view; nested horizontal lists are ignored.
class LoadMoreOnScroll extends StatelessWidget {
  const LoadMoreOnScroll({
    super.key,
    required this.onLoadMore,
    required this.child,
    this.threshold = 600,
  });

  final VoidCallback onLoadMore;
  final Widget child;

  /// How close to the end, in pixels, the next page is asked for.
  final double threshold;

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        final metrics = notification.metrics;
        if (metrics.axis == Axis.vertical && metrics.extentAfter < threshold) {
          onLoadMore();
        }
        return false;
      },
      child: child,
    );
  }
}

/// A spinner under the list while the next page loads.
class LoadMoreFooter extends StatelessWidget {
  const LoadMoreFooter({super.key, required this.loading, this.color});

  final bool loading;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    if (!loading) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2.4,
            color: color ?? Colors.white70,
          ),
        ),
      ),
    );
  }
}

/// [LoadMoreFooter] for a [CustomScrollView].
class SliverLoadMoreFooter extends StatelessWidget {
  const SliverLoadMoreFooter({super.key, required this.loading, this.color});

  final bool loading;
  final Color? color;

  @override
  Widget build(BuildContext context) => SliverToBoxAdapter(
    child: LoadMoreFooter(loading: loading, color: color),
  );
}
