import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/common/widget/liked_collection.dart';
import '../../../../core/notifiers/snackbar_notifier.dart';
import '../../controller/download_controller.dart';

/// The download actions the player and the Downloads screen share, with
/// their feedback. A download can outlive the screen that started it, so the
/// result is reported through whatever context is still mounted.
abstract final class DownloadActions {
  static Future<void> start(
    BuildContext context,
    DownloadRequest request,
  ) async {
    final error = await DownloadController.instance.download(request);
    _report(
      context.mounted ? context : null,
      error,
      success: '"${request.title}" downloaded',
    );
  }

  static Future<void> retry(BuildContext context, String songId) async {
    final error = await DownloadController.instance.retry(songId);
    _report(context.mounted ? context : null, error);
  }

  /// Asks before deleting, through the same sheet the liked lists use.
  static void confirmRemove(
    BuildContext context, {
    required String songId,
    required String title,
    VoidCallback? onPlay,
  }) {
    LikedActionsSheet.show(
      context,
      title: title,
      actions: [
        if (onPlay != null)
          LikedAction(
            icon: Icons.play_arrow_rounded,
            label: 'Play',
            onTap: onPlay,
          ),
        LikedAction(
          icon: Icons.delete_outline_rounded,
          label: 'Remove Download',
          onTap: () async {
            await DownloadController.instance.remove(songId);
            _report(
              context.mounted ? context : null,
              null,
              success: 'Download removed',
            );
          },
        ),
      ],
    );
  }

  /// Offers to stop a download that is running.
  static void confirmCancel(
    BuildContext context, {
    required String songId,
    required String title,
  }) {
    LikedActionsSheet.show(
      context,
      title: title,
      actions: [
        LikedAction(
          icon: Icons.close_rounded,
          label: 'Cancel Download',
          onTap: () => DownloadController.instance.cancel(songId),
        ),
      ],
    );
  }

  /// [context] is null once the screen that asked has gone, and the app's
  /// root context reports instead.
  static void _report(BuildContext? context, String? error, {String? success}) {
    final target = context ?? Get.context;
    if (target == null || !target.mounted) return;

    final notifier = SnackbarNotifier(context: target);
    if (error != null) {
      notifier.notifyError(message: error);
    } else if (success != null) {
      notifier.notifySuccess(message: success);
    }
  }
}
