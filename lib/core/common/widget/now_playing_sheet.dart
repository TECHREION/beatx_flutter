import 'dart:io';
import 'package:beatx_flutter/core/services/image_cache/cached_image.dart';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../player/now_playing.dart';
import '../../player/player_controller.dart';

const _accent = Color(0xFF9BFF4D);
const _sheetColor = Color(0xFF111214);
const _cardColor = Color(0xFF1C1D20);

/// Hands [context] to the shared player for the track about to start, and
/// makes sure finishing a book offers the next one in its series.
///
/// Call just before `PlayerController.play`.
void attachNowPlaying(NowPlayingContext? context) {
  final player = Get.isRegistered<PlayerController>()
      ? Get.find<PlayerController>()
      : Get.put(PlayerController(), permanent: true);
  player.onCollectionFinished ??= _offerWhatsNext;
  player.setNowPlaying(context);
}

/// The end of a book (or the last episode of a show): offer the sequel, or
/// something similar, instead of just going quiet.
void _offerWhatsNext(NowPlayingContext playing) {
  final context = Get.context;
  if (context == null || !context.mounted) return;
  if (playing.sequel == null && playing.suggestions.isEmpty) return;
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: _sheetColor,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => _FinishedSheet(playing: playing),
  );
}

/// Opens the list of chapters (or episodes) of what is playing, with the
/// series it belongs to and suggestions for what to play after it.
Future<void> showNowPlayingSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: _sheetColor,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, scroll) => _NowPlayingSheet(scroll: scroll),
    ),
  );
}

class _NowPlayingSheet extends StatefulWidget {
  const _NowPlayingSheet({required this.scroll});

  final ScrollController scroll;

  @override
  State<_NowPlayingSheet> createState() => _NowPlayingSheetState();
}

class _NowPlayingSheetState extends State<_NowPlayingSheet> {
  final _currentKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    // Starts with the chapter that is playing in view, not chapter 1.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final row = _currentKey.currentContext;
      if (row != null && row.mounted) {
        Scrollable.ensureVisible(row, alignment: 0.3);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final player = Get.find<PlayerController>();
    return Obx(() {
      final playing = player.nowPlaying.value;
      if (playing == null) {
        return const Center(
          child: Text(
            'Nothing playing',
            style: TextStyle(color: Colors.white54),
          ),
        );
      }
      final trackId = player.trackId.value;
      final entries = playing.entries.toList();
      final prequel = playing.prequel;
      final sequel = playing.sequel;
      final suggestions = playing.suggestions.toList();
      final current = playing.entry(trackId);

      return CustomScrollView(
        controller: widget.scroll,
        slivers: [
          const SliverToBoxAdapter(child: _Handle()),
          SliverToBoxAdapter(
            child: _CollectionHeader(playing: playing, current: current),
          ),
          if (current != null)
            SliverToBoxAdapter(
              child: _NowPlayingCard(
                label: playing.position(trackId),
                title: current.title,
                isPlaying: player.isPlaying.value,
              ),
            ),
          if (sequel != null || prequel != null) ...[
            const SliverToBoxAdapter(child: _SectionTitle('In this series')),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    if (prequel != null)
                      _SeriesCard(entry: prequel, playing: playing),
                    if (prequel != null && sequel != null)
                      const SizedBox(height: 10),
                    if (sequel != null)
                      _SeriesCard(
                        entry: sequel,
                        playing: playing,
                        highlight: true,
                      ),
                  ],
                ),
              ),
            ),
          ],
          if (entries.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: _SectionTitle(
                playing.listName,
                trailing: '${entries.length}',
              ),
            ),
            SliverList.builder(
              itemCount: entries.length,
              itemBuilder: (context, i) {
                final entry = entries[i];
                final showGroup =
                    entry.group.isNotEmpty &&
                    (i == 0 || entries[i - 1].group != entry.group);
                final isCurrent = entry.id == trackId;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (showGroup)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
                        child: Text(
                          entry.group.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    _EntryRow(
                      key: isCurrent ? _currentKey : null,
                      entry: entry,
                      isCurrent: isCurrent,
                      isPlaying: isCurrent && player.isPlaying.value,
                      onTap: playing.playEntry == null || isCurrent
                          ? null
                          : () => playing.playEntry!(entry.id),
                    ),
                  ],
                );
              },
            ),
          ],
          if (suggestions.isNotEmpty) ...[
            const SliverToBoxAdapter(
              child: _SectionTitle('You might also like'),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 210,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: suggestions.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                  itemBuilder: (context, i) =>
                      _SuggestionTile(entry: suggestions[i], playing: playing),
                ),
              ),
            ),
          ],
          SliverToBoxAdapter(
            child: SizedBox(height: 24 + MediaQuery.paddingOf(context).bottom),
          ),
        ],
      );
    });
  }
}

class _Handle extends StatelessWidget {
  const _Handle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(top: 10, bottom: 6),
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.white24,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

class _CollectionHeader extends StatelessWidget {
  const _CollectionHeader({required this.playing, required this.current});

  final NowPlayingContext playing;
  final NowPlayingEntry? current;

  @override
  Widget build(BuildContext context) {
    final kindLabel = switch (playing.kind) {
      NowPlayingKind.chapter => 'AUDIOBOOK',
      NowPlayingKind.episode => 'PODCAST',
      NowPlayingKind.song => 'PLAYING FROM',
    };
    final count = playing.entries.length;
    final meta = [
      if (playing.collectionSubtitle.isNotEmpty) playing.collectionSubtitle,
      if (count > 0)
        '$count ${playing.listName.toLowerCase()}'.replaceFirst(
          RegExp(r's$'),
          count == 1 ? '' : 's',
        ),
    ].join(' · ');
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Row(
        children: [
          CoverImage(url: playing.collectionCoverUrl, size: 64, radius: 14),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  kindLabel,
                  style: const TextStyle(
                    color: _accent,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  playing.collectionTitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (meta.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    meta,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NowPlayingCard extends StatelessWidget {
  const _NowPlayingCard({
    required this.label,
    required this.title,
    required this.isPlaying,
  });

  final String label;
  final String title;
  final bool isPlaying;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _accent.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(
            isPlaying ? Icons.graphic_eq_rounded : Icons.pause_circle_outline,
            color: _accent,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isPlaying ? 'NOW PLAYING · $label' : 'PAUSED · $label',
                  style: const TextStyle(
                    color: _accent,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title, {this.trailing});

  final String title;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          if (trailing != null)
            Text(
              trailing!,
              style: const TextStyle(color: Colors.white54, fontSize: 13),
            ),
        ],
      ),
    );
  }
}

class _EntryRow extends StatelessWidget {
  const _EntryRow({
    super.key,
    required this.entry,
    required this.isCurrent,
    required this.isPlaying,
    required this.onTap,
  });

  final NowPlayingEntry entry;
  final bool isCurrent;
  final bool isPlaying;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = isCurrent ? _accent : Colors.white;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            SizedBox(
              width: 28,
              child: isCurrent
                  ? Icon(
                      isPlaying ? Icons.graphic_eq_rounded : Icons.pause,
                      color: _accent,
                      size: 20,
                    )
                  : const Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white38,
                      size: 20,
                    ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.label,
                    style: TextStyle(
                      color: isCurrent ? _accent : Colors.white54,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    entry.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: color,
                      fontSize: 15,
                      fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            if (entry.durationMs > 0) ...[
              const SizedBox(width: 12),
              Text(
                formatClock(entry.durationMs),
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A prequel or sequel, with a button to start it.
class _SeriesCard extends StatelessWidget {
  const _SeriesCard({
    required this.entry,
    required this.playing,
    this.highlight = false,
  });

  final SeriesEntry entry;
  final NowPlayingContext playing;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final label = entry.relation == SeriesRelation.sequel
        ? 'NEXT IN SERIES'
        : 'PREVIOUS IN SERIES';
    return Material(
      color: highlight ? _accent.withValues(alpha: 0.1) : _cardColor,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: playing.openSeries == null
            ? null
            : () {
                Navigator.of(context).pop();
                playing.openSeries!(entry);
              },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CoverImage(url: entry.coverUrl, size: 56, radius: 10),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: highlight ? _accent : Colors.white54,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      entry.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (entry.subtitle.isNotEmpty)
                      Text(
                        entry.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
              if (playing.playSeries != null)
                _PlayCircle(
                  label: 'Listen to ${entry.title}',
                  onTap: () {
                    Navigator.of(context).pop();
                    playing.playSeries!(entry);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SuggestionTile extends StatelessWidget {
  const _SuggestionTile({required this.entry, required this.playing});

  final SeriesEntry entry;
  final NowPlayingContext playing;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 130,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: playing.openSeries == null
            ? null
            : () {
                Navigator.of(context).pop();
                playing.openSeries!(entry);
              },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CoverImage(url: entry.coverUrl, size: 130, radius: 12),
            const SizedBox(height: 8),
            Text(
              entry.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (entry.subtitle.isNotEmpty)
              Text(
                entry.subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
          ],
        ),
      ),
    );
  }
}

class _PlayCircle extends StatelessWidget {
  const _PlayCircle({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: _accent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: const SizedBox(
            width: 44,
            height: 44,
            child: Icon(Icons.play_arrow_rounded, color: Colors.black),
          ),
        ),
      ),
    );
  }
}

/// Shown when the last chapter of a book ends: the next book in the series,
/// or similar books when there is no sequel.
class _FinishedSheet extends StatelessWidget {
  const _FinishedSheet({required this.playing});

  final NowPlayingContext playing;

  @override
  Widget build(BuildContext context) {
    final sequel = playing.sequel;
    final suggestions = playing.suggestions.take(6).toList();
    final what = playing.kind == NowPlayingKind.chapter ? 'book' : 'show';
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'You finished this $what',
                    style: const TextStyle(
                      color: _accent,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    playing.collectionTitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (sequel != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _SeriesCard(
                  entry: sequel,
                  playing: playing,
                  highlight: true,
                ),
              ),
            if (suggestions.isNotEmpty) ...[
              _SectionTitle(
                sequel != null ? 'More like this' : 'What to listen to next',
              ),
              SizedBox(
                height: 210,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: suggestions.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                  itemBuilder: (context, i) =>
                      _SuggestionTile(entry: suggestions[i], playing: playing),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A cover from a url, a file saved on the device, or a placeholder.
class CoverImage extends StatelessWidget {
  const CoverImage({
    super.key,
    required this.url,
    required this.size,
    this.radius = 8,
  });

  final String url;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      color: _cardColor,
      alignment: Alignment.center,
      child: Icon(
        Icons.headphones_rounded,
        color: Colors.white24,
        size: size * 0.4,
      ),
    );
    Widget image;
    if (url.startsWith('http')) {
      image = CachedImage.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => placeholder,
      );
    } else if (PlayerController.isLocalFilePath(url)) {
      image = Image.file(
        File(url.startsWith('file://') ? Uri.parse(url).toFilePath() : url),
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => placeholder,
      );
    } else {
      image = placeholder;
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(width: size, height: size, child: image),
    );
  }
}

/// 754000 → "12:34", 3723000 → "1:02:03".
String formatClock(int milliseconds) {
  final d = Duration(milliseconds: milliseconds);
  final h = d.inHours;
  final m = d.inMinutes.remainder(60);
  final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  return h > 0 ? '$h:${m.toString().padLeft(2, '0')}:$s' : '$m:$s';
}
