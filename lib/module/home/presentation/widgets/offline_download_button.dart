import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/common/widget/liked_collection.dart';
import '../../../../core/notifiers/snackbar_notifier.dart';
import '../../controller/download_controller.dart';
import '../../controller/offline_content_controller.dart';

/// Draws the button around the download icon: a screen's own button shape.
typedef DownloadButtonFrame =
    Widget Function(
      BuildContext context, {
      required Widget icon,
      required String semantics,
      VoidCallback? onTap,
    });

/// Saves an item (video, episode, audiobook) for offline use, shows how far
/// that has got, and offers to cancel or remove it.
class OfflineDownloadButton extends StatelessWidget {
  const OfflineDownloadButton({
    super.key,
    required this.controller,
    required this.itemId,
    required this.request,
    required this.title,
    this.accent = Colors.cyanAccent,
    this.iconSize = 24,
    this.frame = plainFrame,
    this.savedMessage = 'saved for offline listening',
  });

  final OfflineContentController controller;
  final String itemId;

  /// Null until the item's details have loaded; nothing can be saved
  /// without a title to list it under.
  final DownloadRequest? request;

  /// Names the item in the cancel and remove sheets.
  final String title;
  final Color accent;
  final double iconSize;
  final DownloadButtonFrame frame;

  /// Follows the item's quoted title in the success message.
  final String savedMessage;

  static const done = Color(0xFF9BFF4D);

  /// A bare icon with some room to tap.
  static Widget plainFrame(
    BuildContext context, {
    required Widget icon,
    required String semantics,
    VoidCallback? onTap,
  }) {
    return Semantics(
      button: true,
      label: semantics,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(padding: const EdgeInsets.all(6), child: icon),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (itemId.isEmpty) {
      return frame(
        context,
        icon: _icon(Icons.download, Colors.white24),
        semantics: 'Download',
      );
    }
    final state = controller.stateFor(itemId);

    return Obx(() {
      switch (state.status.value) {
        case DownloadStatus.downloading:
          return frame(
            context,
            onTap: () => _confirmCancel(context),
            semantics: 'Downloading, tap to cancel',
            icon: SizedBox(
              width: iconSize - 2,
              height: iconSize - 2,
              child: CircularProgressIndicator(
                // Spins while the size is unknown.
                value: state.progress.value,
                strokeWidth: 2.4,
                color: accent,
                backgroundColor: Colors.white12,
              ),
            ),
          );
        case DownloadStatus.downloaded:
          return frame(
            context,
            onTap: () => _confirmRemove(context),
            semantics: 'Downloaded',
            icon: _icon(Icons.download_done_rounded, done),
          );
        case DownloadStatus.failed:
          return frame(
            context,
            onTap: () => _run(context, controller.retry(itemId)),
            semantics: 'Download failed, tap to retry',
            icon: _icon(Icons.refresh_rounded, Colors.orangeAccent),
          );
        case DownloadStatus.notDownloaded:
          final info = request;
          return frame(
            context,
            onTap: info == null
                ? null
                : () => _run(
                    context,
                    controller.download(info),
                    success: '"${info.title}" $savedMessage',
                  ),
            semantics: 'Download',
            icon: _icon(Icons.download, info == null ? Colors.white24 : accent),
          );
      }
    });
  }

  Widget _icon(IconData icon, Color color) =>
      Icon(icon, color: color, size: iconSize);

  /// Reports how [work] ended, through whatever context is still around:
  /// a download can outlive the page that started it.
  Future<void> _run(
    BuildContext context,
    Future<String?> work, {
    String? success,
  }) async {
    final error = await work;
    final target = context.mounted ? context : Get.context;
    if (target == null || !target.mounted) return;
    final notifier = SnackbarNotifier(context: target);
    if (error != null) {
      notifier.notifyError(message: error);
    } else if (success != null &&
        // Not after a cancel, which also ends without an error.
        controller.stateFor(itemId).status.value == DownloadStatus.downloaded) {
      notifier.notifySuccess(message: success);
    }
  }

  void _confirmCancel(BuildContext context) {
    LikedActionsSheet.show(
      context,
      title: title,
      actions: [
        LikedAction(
          icon: Icons.close_rounded,
          label: 'Cancel Download',
          onTap: () => controller.cancel(itemId),
        ),
      ],
    );
  }

  void _confirmRemove(BuildContext context) {
    LikedActionsSheet.show(
      context,
      title: title,
      actions: [
        LikedAction(
          icon: Icons.delete_outline_rounded,
          label: 'Remove Download',
          onTap: () async {
            await controller.remove(itemId);
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
