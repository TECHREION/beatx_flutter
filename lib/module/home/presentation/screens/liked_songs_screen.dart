import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/player/player_controller.dart';
import '../../controller/liked_songs_controller.dart';
import '../../model/listem_miusic_detalis_model.dart';

/// Every song the user has liked, over `GET /songs/liked`.
class LikedSongsScreen extends StatelessWidget {
  const LikedSongsScreen({super.key});

  static const _background = Color(0xFF050608);
  static const _accent = Color(0xFF9BFF4D);
  static const _accentAlt = Color(0xFF40DDEB);
  static const _muted = Color(0xFFA7A3AA);

  static const _artGradient = [Color(0xFF4DEBFF), Color(0xFF7B3BFF)];

  @override
  Widget build(BuildContext context) {
    final ctrl = LikedSongsController.instance;

    return Scaffold(
      backgroundColor: _background,
      body: RefreshIndicator(
        onRefresh: ctrl.fetch,
        color: _accent,
        backgroundColor: const Color(0xFF151515),
        child: CustomScrollView(
          // Keeps pull-to-refresh reachable while the list is empty or short.
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            _Header(controller: ctrl),
            SliverToBoxAdapter(child: _Toolbar(controller: ctrl)),
            Obx(() {
              if (ctrl.isLoading.value && ctrl.songs.isEmpty) {
                return const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Padding(
                    padding: EdgeInsets.only(top: 60),
                    child: Center(
                      child: CircularProgressIndicator(color: _accent),
                    ),
                  ),
                );
              }

              if (ctrl.songs.isEmpty) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: _EmptyState(
                    message: ctrl.errorMessage.value,
                    onRetry: ctrl.fetch,
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
                sliver: SliverList.separated(
                  itemCount: ctrl.songs.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 6),
                  itemBuilder: (_, index) => _SongRow(
                    song: ctrl.songs[index],
                    position: index + 1,
                    controller: ctrl,
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  /// `durationMs` comes back as 0 for songs the backend never measured, so
  /// fall back to whatever the player measured the last time it played one.
  static String? formatDuration(String songId, int durationMs) {
    var value = Duration(milliseconds: durationMs);
    if (value == Duration.zero && Get.isRegistered<PlayerController>()) {
      value =
          Get.find<PlayerController>().measuredDuration(songId) ??
          Duration.zero;
    }
    if (value == Duration.zero) return null;

    final minutes = value.inMinutes;
    final seconds = value.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

/// Collapsing header: cover mosaic over a wash of colour, the way the big
/// music apps front a playlist.
class _Header extends StatelessWidget {
  const _Header({required this.controller});

  final LikedSongsController controller;

  static const _expandedHeight = 380.0;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      expandedHeight: _expandedHeight,
      backgroundColor: LikedSongsScreen._background,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        onPressed: () => Navigator.maybePop(context),
        icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
      ),
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          final collapsedHeight =
              kToolbarHeight + MediaQuery.of(context).padding.top;
          // 1 while fully expanded, 0 once pinned — drives the crossfade
          // between the big header and the compact bar title.
          final expansion =
              ((constraints.maxHeight - collapsedHeight) /
                      (_expandedHeight - collapsedHeight))
                  .clamp(0.0, 1.0);

          return Stack(
            fit: StackFit.expand,
            children: [
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF23124A), LikedSongsScreen._background],
                  ),
                ),
              ),
              // Laid out from the bottom and left unconstrained in height, so
              // a collapsing bar slides it out of frame instead of
              // overflowing it.
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: Opacity(
                  opacity: expansion,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Obx(
                        () => _CoverMosaic(covers: controller.mosaicCovers),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Liked Songs',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Obx(
                        () => Text(
                          _subtitle(controller),
                          style: const TextStyle(
                            color: LikedSongsScreen._muted,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: MediaQuery.of(context).padding.top,
                left: 0,
                right: 0,
                height: kToolbarHeight,
                child: Opacity(
                  opacity: 1 - expansion,
                  child: const Center(
                    child: Text(
                      'Liked Songs',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  static String _subtitle(LikedSongsController controller) {
    if (!controller.hasLoaded.value) return 'Your favourites';

    final count = controller.songs.length;
    return count == 1 ? '1 song' : '$count songs';
  }
}

/// Up to four covers in a square, falling back to a heart while there is
/// nothing to show.
class _CoverMosaic extends StatelessWidget {
  const _CoverMosaic({required this.covers});

  /// At most four, already stripped of songs that have no cover.
  final List<String> covers;

  static const _size = 160.0;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _size,
      height: _size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: LikedSongsScreen._artGradient,
        ),
        boxShadow: [
          BoxShadow(
            color: LikedSongsScreen._artGradient.last.withValues(alpha: 0.35),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: covers.length < 4
            ? _single(covers)
            : GridView.count(
                crossAxisCount: 2,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  for (final url in covers) _Cover(url: url, size: _size / 2),
                ],
              ),
      ),
    );
  }

  Widget _single(List<String> covers) {
    if (covers.isEmpty) {
      return const Center(
        child: Icon(Icons.favorite_rounded, color: Colors.white, size: 62),
      );
    }
    return _Cover(url: covers.first, size: _size);
  }
}

class _Cover extends StatelessWidget {
  const _Cover({required this.url, required this.size});

  final String url;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.network(
      url,
      width: size,
      height: size,
      fit: BoxFit.cover,
      // A missing cover should leave the gradient behind it showing rather
      // than punch a grey hole in the mosaic.
      errorBuilder: (_, _, _) => const SizedBox.shrink(),
      loadingBuilder: (context, child, progress) =>
          progress == null ? child : const SizedBox.shrink(),
    );
  }
}

/// Play and shuffle, sitting between the header and the list.
class _Toolbar extends StatelessWidget {
  const _Toolbar({required this.controller});

  final LikedSongsController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final enabled = controller.songs.isNotEmpty;

      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
        child: Row(
          children: [
            Expanded(
              child: _ToolbarButton(
                icon: Icons.play_arrow_rounded,
                label: 'Play',
                filled: true,
                onTap: enabled
                    ? () => controller.play(controller.songs.first)
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ToolbarButton(
                icon: Icons.shuffle_rounded,
                label: 'Shuffle',
                filled: false,
                onTap: enabled ? controller.shuffle : null,
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _ToolbarButton extends StatelessWidget {
  const _ToolbarButton({
    required this.icon,
    required this.label,
    required this.filled,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final bool filled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final foreground = filled
        ? const Color(0xFF05210A)
        : (enabled ? Colors.white : Colors.white38);

    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            gradient: filled
                ? const LinearGradient(
                    colors: [
                      LikedSongsScreen._accent,
                      LikedSongsScreen._accentAlt,
                    ],
                  )
                : null,
            color: filled ? null : const Color(0xFF1E1E1F),
            border: filled
                ? null
                : Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: foreground, size: 22),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: foreground,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SongRow extends StatelessWidget {
  const _SongRow({
    required this.song,
    required this.position,
    required this.controller,
  });

  final ListenMusicDetailsModel song;
  final int position;
  final LikedSongsController controller;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => controller.play(song),
      behavior: HitTestBehavior.opaque,
      child: Obx(() {
        // Both reads are reactive, so the row repaints when the player moves
        // to another track and when it measures a length this song lacked.
        final playing =
            Get.find<PlayerController>().trackId.value == song.id;
        final duration = LikedSongsScreen.formatDuration(
          song.id,
          song.durationMs,
        );

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: playing
                ? LikedSongsScreen._accent.withValues(alpha: 0.08)
                : Colors.transparent,
          ),
          child: Row(
            children: [
              SizedBox(
                width: 22,
                child: playing
                    ? const Icon(
                        Icons.equalizer_rounded,
                        color: LikedSongsScreen._accent,
                        size: 18,
                      )
                    : Text(
                        '$position',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: LikedSongsScreen._muted,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
              const SizedBox(width: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 52,
                  height: 52,
                  child: DecoratedBox(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: LikedSongsScreen._artGradient,
                      ),
                    ),
                    child: song.coverUrl.isEmpty
                        ? const Icon(
                            Icons.music_note_rounded,
                            color: Colors.white,
                            size: 24,
                          )
                        : _Cover(url: song.coverUrl, size: 52),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      song.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: playing
                            ? LikedSongsScreen._accent
                            : Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      [song.artist, ?duration].join('  •  '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: LikedSongsScreen._muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _UnlikeButton(song: song, controller: controller),
            ],
          ),
        );
      }),
    );
  }
}

class _UnlikeButton extends StatelessWidget {
  const _UnlikeButton({required this.song, required this.controller});

  final ListenMusicDetailsModel song;
  final LikedSongsController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final busy = controller.unliking.contains(song.id);

      return GestureDetector(
        onTap: busy ? null : () => controller.unlike(song),
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: 44,
          height: 44,
          child: busy
              ? const Center(
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: LikedSongsScreen._muted,
                    ),
                  ),
                )
              : const Icon(
                  Icons.favorite_rounded,
                  color: Color(0xFFFF4D6D),
                  size: 22,
                ),
        ),
      );
    });
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message, required this.onRetry});

  /// The failure that left the list empty, or empty when it is simply empty.
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final failed = message.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 50, 32, 32),
      child: Column(
        children: [
          Icon(
            failed ? Icons.cloud_off_rounded : Icons.favorite_border_rounded,
            color: Colors.white24,
            size: 58,
          ),
          const SizedBox(height: 18),
          Text(
            failed ? 'Could not load your likes' : 'No liked songs yet',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            failed
                ? message
                : 'Tap the heart while a song is playing and it will show up '
                      'here.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: LikedSongsScreen._muted,
              fontSize: 13,
              height: 1.45,
            ),
          ),
          if (failed) ...[
            const SizedBox(height: 22),
            _ToolbarButton(
              icon: Icons.refresh_rounded,
              label: 'Try again',
              filled: true,
              onTap: onRetry,
            ),
          ],
        ],
      ),
    );
  }
}
