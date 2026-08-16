import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../module/genre-artist/controller/genre_controller.dart';

/// Chrome shared by the song, video and audiobook search screens: the same
/// screen over a different endpoint, differing only in accent colour, what a
/// row says and where a row goes.

abstract final class SearchPalette {
  static const background = Color(0xFF0A0A0F);
  static const card = Color(0xFF121218);
  static const chip = Color(0xFF1C1C26);
  static const muted = Color(0xFF8B8B99);
}

/// Back button and screen name.
class SearchHeader extends StatelessWidget {
  const SearchHeader({
    super.key,
    required this.title,
    required this.icon,
    required this.accent,
  });

  final String title;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.maybePop(context),
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: SearchPalette.card,
                border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
              ),
              child: const Icon(
                Icons.chevron_left_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Icon(icon, color: accent, size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

/// The query box. Keeps its own [TextEditingController] so the clear button
/// can empty it.
class SearchQueryField extends StatefulWidget {
  const SearchQueryField({
    super.key,
    required this.hint,
    required this.accent,
    required this.onChanged,
    required this.onSubmitted,
    required this.onCleared,
  });

  final String hint;
  final Color accent;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onCleared;

  @override
  State<SearchQueryField> createState() => _SearchQueryFieldState();
}

class _SearchQueryFieldState extends State<SearchQueryField> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: TextField(
        controller: _controller,
        autofocus: true,
        textInputAction: TextInputAction.search,
        onChanged: (value) {
          // Repaints for the clear button, which is only there once something
          // has been typed.
          setState(() {});
          widget.onChanged(value);
        },
        onSubmitted: widget.onSubmitted,
        style: const TextStyle(color: Colors.white, letterSpacing: 0),
        cursorColor: widget.accent,
        decoration: InputDecoration(
          filled: true,
          fillColor: SearchPalette.card,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(26),
            borderSide: BorderSide.none,
          ),
          prefixIcon: const Icon(Icons.search_rounded, color: Colors.white70),
          suffixIcon: _controller.text.isEmpty
              ? null
              : GestureDetector(
                  onTap: () {
                    _controller.clear();
                    setState(() {});
                    widget.onCleared();
                  },
                  behavior: HitTestBehavior.opaque,
                  child: const Icon(
                    Icons.close_rounded,
                    color: Colors.white70,
                    size: 20,
                  ),
                ),
          hintText: widget.hint,
          hintStyle: const TextStyle(
            color: Colors.white38,
            fontWeight: FontWeight.w500,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }
}

/// The genre filter strip, over `GET /genre`.
///
/// The backend matches on genre id, so the chips carry ids and "All" carries
/// an empty one.
class SearchGenreBar extends StatelessWidget {
  const SearchGenreBar({
    super.key,
    required this.accent,
    required this.selectedId,
    required this.onSelected,
  });

  final Color accent;
  final String selectedId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final genres = GenreController.instance;

    return Obx(() {
      // Nothing to filter by until the genres land, and an empty strip beats
      // a row of placeholder chips.
      if (genres.genres.isEmpty) return const SizedBox(height: 8);

      return SizedBox(
        height: 38,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: genres.genres.length + 1,
          separatorBuilder: (_, _) => const SizedBox(width: 8),
          itemBuilder: (_, index) {
            final id = index == 0 ? '' : genres.genres[index - 1].id;
            final label = index == 0 ? 'All' : genres.genres[index - 1].name;

            return _GenreChip(
              label: label,
              accent: accent,
              selected: selectedId == id,
              onTap: () => onSelected(id),
            );
          },
        ),
      );
    });
  }
}

class _GenreChip extends StatelessWidget {
  const _GenreChip({
    required this.label,
    required this.accent,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final Color accent;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: selected ? accent.withValues(alpha: 0.18) : SearchPalette.chip,
          borderRadius: BorderRadius.circular(19),
          border: Border.all(
            color: selected ? accent : Colors.white.withValues(alpha: 0.06),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? accent : SearchPalette.muted,
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }
}

/// One match: artwork, captions and a trailing note.
class SearchResultTile extends StatelessWidget {
  const SearchResultTile({
    super.key,
    required this.coverUrl,
    required this.title,
    required this.subtitle,
    required this.fallbackIcon,
    required this.gradient,
    required this.accent,
    this.tag = '',
    this.meta = '',
    this.wideCover = false,
    this.onTap,
  });

  final String coverUrl;
  final String title;
  final String subtitle;
  final IconData fallbackIcon;
  final List<Color> gradient;
  final Color accent;

  /// Genre or category. The pill is dropped when the payload carried none.
  final String tag;

  /// The right-hand note — a length, a play count.
  final String meta;

  /// Videos are 16:9; songs and books are square.
  final bool wideCover;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: SearchPalette.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(13),
              child: SizedBox(
                width: wideCover ? 104 : 62,
                height: 62,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: gradient,
                    ),
                  ),
                  child: coverUrl.isEmpty
                      ? Icon(fallbackIcon, color: Colors.white, size: 25)
                      : Image.network(
                          coverUrl,
                          fit: BoxFit.cover,
                          // A missing cover should leave the gradient behind
                          // it showing rather than punch a hole in the row.
                          errorBuilder: (_, _, _) => const SizedBox.shrink(),
                          loadingBuilder: (context, child, progress) =>
                              progress == null
                              ? child
                              : const SizedBox.shrink(),
                        ),
                ),
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: SearchPalette.muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0,
                    ),
                  ),
                  if (tag.isNotEmpty) ...[
                    const SizedBox(height: 9),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: SearchPalette.chip,
                      ),
                      child: Text(
                        tag,
                        style: const TextStyle(
                          color: SearchPalette.muted,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (meta.isNotEmpty) ...[
              const SizedBox(width: 10),
              Text(
                meta,
                style: TextStyle(
                  color: accent,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// What sits where the results would be when there are none: the failure, the
/// "nothing matched" note, or nothing at all while the first search runs.
class SearchEmptyState extends StatelessWidget {
  const SearchEmptyState({
    super.key,
    required this.message,
    required this.query,
    required this.noun,
    required this.accent,
    required this.onRetry,
  });

  /// The failure that left the list empty, or empty when it is simply empty.
  final String message;

  /// What was searched for, so the note can name it.
  final String query;

  /// Plural kind being searched — "songs", "videos", "audiobooks".
  final String noun;
  final Color accent;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final failed = message.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 48, 32, 32),
      child: Column(
        children: [
          Icon(
            failed ? Icons.cloud_off_rounded : Icons.search_off_rounded,
            color: Colors.white24,
            size: 54,
          ),
          const SizedBox(height: 18),
          Text(
            failed ? 'Could not run your search' : 'No $noun found',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            failed
                ? message
                : query.isEmpty
                ? 'Nothing here yet. Try another genre.'
                : 'Nothing matched "$query". Try another name or genre.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: SearchPalette.muted,
              fontSize: 13,
              height: 1.45,
            ),
          ),
          if (failed) ...[
            const SizedBox(height: 22),
            GestureDetector(
              onTap: onRetry,
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 26,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  color: accent,
                ),
                child: const Text(
                  'Try again',
                  style: TextStyle(
                    color: Color(0xFF0A0A0F),
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// The results list, with the scroll-to-load and footer both screens share.
class SearchResultsList extends StatelessWidget {
  const SearchResultsList({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    required this.isLoadingMore,
    required this.accent,
    required this.onLoadMore,
  });

  final int itemCount;
  final NullableIndexedWidgetBuilder itemBuilder;
  final bool isLoadingMore;
  final Color accent;
  final VoidCallback onLoadMore;

  /// How close to the bottom the list gets before the next page is asked for.
  static const _loadMoreExtent = 240.0;

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        final metrics = notification.metrics;
        if (metrics.axis != Axis.vertical) return false;

        if (metrics.maxScrollExtent - metrics.pixels <= _loadMoreExtent) {
          // Guarded in the controller, so a burst of scroll notifications
          // still only fetches one page.
          onLoadMore();
        }
        return false;
      },
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: itemCount + 1,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          if (index == itemCount) {
            return isLoadingMore
                ? Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: accent,
                        ),
                      ),
                    ),
                  )
                : const SizedBox(height: 12);
          }

          return itemBuilder(context, index);
        },
      ),
    );
  }
}
