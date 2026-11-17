import 'package:flutter/material.dart';

import '../../../home/presentation/widgets/downloaded_item_list.dart';
import '../../controller/video_download_controller.dart';
import '../screen/video_screen.dart';

/// The videos saved on this device, for the Downloads screen. Works with no
/// connection: the video page plays the saved file.
class DownloadedVideoList extends StatelessWidget {
  const DownloadedVideoList({
    super.key,
    required this.accent,
    required this.formatBytes,
  });

  final Color accent;
  final String Function(int bytes) formatBytes;

  @override
  Widget build(BuildContext context) {
    return DownloadedItemList(
      controller: VideoDownloadController.instance,
      accent: accent,
      formatBytes: formatBytes,
      singular: 'video',
      plural: 'videos',
      playLabel: 'Watch',
      wideCover: true,
      placeholderIcon: Icons.smart_display_rounded,
      emptyIcon: Icons.video_library_outlined,
      emptyBody:
          'Tap the download button under a video to keep it on this device '
          'and watch without internet.',
      onPlay: (files) => MusicPlayerScreen.open(files.first.id),
    );
  }
}
