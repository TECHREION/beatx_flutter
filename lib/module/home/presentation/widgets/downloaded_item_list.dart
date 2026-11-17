import 'dart:io';
import 'package:beatx_flutter/core/services/image_cache/cached_image.dart';
import 'package:beatx_flutter/core/common/widget/mini_player_host.dart';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/common/widget/liked_collection.dart';
import '../../../../core/notifiers/snackbar_notifier.dart';
import '../../controller/download_controller.dart';
import '../../controller/offline_content_controller.dart';
import '../../model/downloaded_song_model.dart';

/// One tab of the Downloads screen for videos, episodes or audiobooks: the
/// items saved on this device. Reads only local storage, so it works with no
/// connection.
class DownloadedItemList extends StatelessWidget {
  const DownloadedItemList({
    super.key,
    required this.controller,
    required this.accent,
    required this.formatBytes,
    required this.onPlay,
    required this.singular,
    required this.plural,
    required this.emptyBody,
    required this.emptyIcon,
    this.playLabel = 'Play',
    this.wideCover = false,
    this.placeholderIcon = Icons.headphones_rounded,
  });

  final OfflineContentController controller;
  final Color accent;
  final String Function(int bytes) formatBytes;

  /// Plays an item, given its saved files in order.
  final void Function(List<DownloadedSong> files) onPlay;

  /// "video" / "videos", for the count line and the empty state.
  final String singular;
  final String plural;
  final String emptyBody;
  final IconData emptyIcon;
  final String playLabel;

  /// A 16:9 thumbnail (videos) instead of a square cover.
  final bool wideCover;
  final IconData placeholderIcon;

  @override
  Widget build(BuildContext context) {
    final locked = DownloadController.instance.isLocked;

    return Obx(() {
      if (!controller.isReady.value) {
        return Center(child: CircularProgressIndicator(color: accent));
      }
      final items = controller.visibleItems;
      if (items.isEmpty) {
        return SingleChildScrollView(
          child: LikedEmptyState(
            message: '',
            emptyTitle: locked.value
                ? 'Connect to use your downloads'
                : 'No downloaded $plural yet',
            emptyBody: locked.value
                ? 'Your downloads are safe. Go online and reopen BeatX to use '
                      'them again.'
                : emptyBody,
            accent: accent,
            emptyIcon: emptyIcon,
            onRetry: () {},
          ),
        );
      }

      final bytes = items
          .expand((files) => files)
          .fold<int>(0, (sum, file) => sum + file.fileSize);
      return Obx(
        () => ListView.separated(
          padding: MiniPlayerHost.padded(
            const EdgeInsets.fromLTRB(16, 4, 16, 32),
          ),
          itemCount: items.length + 1,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (_, index) {
            if (index == 0) {
              return Row(
                children: [
                  const Icon(
                    Icons.sd_storage_outlined,
                    color: LikedPalette.muted,
                    size: 15,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${items.length} ${items.length == 1 ? singular : plural}'
                      '  •  ${formatBytes(bytes)} on this device',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: LikedPalette.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              );
            }
            return _ItemRow(list: this, files: items[index - 1]);
          },
        ),
      );
    });
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.list, required this.files});

  final DownloadedItemList list;

  /// The item's saved files, in order; never empty.
  final List<DownloadedSong> files;

  DownloadedSong get _first => files.first;
  bool get _grouped => _first.groupId.isNotEmpty;
  String get _title => _grouped ? _first.groupTitle : _first.title;

  static String _duration(int ms) {
    if (ms <= 0) return '';
    final d = Duration(milliseconds: ms);
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (d.inHours > 0) {
      final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
      return '${d.inHours}:$m:$s';
    }
    return '${d.inMinutes}:$s';
  }

  @override
  Widget build(BuildContext context) {
    final cover = list.controller.coverPath(_first);
    final length = _duration(
      files.fold(0, (sum, file) => sum + file.durationMs),
    );
    final size = files.fold(0, (sum, file) => sum + file.fileSize);
    final subtitle = [
      if (_first.artist.isNotEmpty) _first.artist,
      if (_grouped)
        files.length == 1 ? '1 chapter' : '${files.length} chapters',
      list.formatBytes(size),
    ].join('  •  ');
    final width = list.wideCover ? 112.0 : 63.0;

    return GestureDetector(
      onTap: () => list.onPlay(files),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: LikedPalette.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: width,
                height: 63,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // The saved cover first, so it shows offline.
                    if (cover != null)
                      Image.file(
                        File(cover),
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => _placeholder(),
                      )
                    else if (_first.artworkUrl.isNotEmpty)
                      CachedImage.network(
                        _first.artworkUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => _placeholder(),
                      )
                    else
                      _placeholder(),
                    if (list.wideCover)
                      const Center(
                        child: Icon(
                          Icons.play_circle_fill_rounded,
                          color: Colors.white70,
                          size: 26,
                        ),
                      ),
                    if (length.isNotEmpty)
                      Positioned(
                        right: 4,
                        bottom: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            length,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: LikedPalette.muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => _actions(context),
              behavior: HitTestBehavior.opaque,
              child: const SizedBox(
                width: 30,
                height: 30,
                child: Icon(
                  Icons.more_vert_rounded,
                  color: Colors.white38,
                  size: 19,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() => ColoredBox(
    color: LikedPalette.chip,
    child: Icon(list.placeholderIcon, color: Colors.white38, size: 24),
  );

  void _actions(BuildContext context) {
    LikedActionsSheet.show(
      context,
      title: _title,
      actions: [
        LikedAction(
          icon: Icons.play_arrow_rounded,
          label: list.playLabel,
          onTap: () => list.onPlay(files),
        ),
        LikedAction(
          icon: Icons.delete_outline_rounded,
          label: 'Remove Download',
          onTap: () async {
            await list.controller.remove(_first.itemId);
            if (context.mounted) {
              SnackbarNotifier(
                context: context,
              ).notifySuccess(message: 'Download removed');
            }
          },
        ),
      ],
    );
  }
}
