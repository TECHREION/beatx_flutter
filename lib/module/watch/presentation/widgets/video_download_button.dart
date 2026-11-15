import 'package:flutter/material.dart';

import '../../../home/controller/download_controller.dart';
import '../../../home/presentation/widgets/offline_download_button.dart';
import '../../controller/video_download_controller.dart';
import '../../model/video_details_model.dart';

/// The video page's download action: saves the video for watching offline.
class VideoDownloadButton extends StatelessWidget {
  const VideoDownloadButton({
    super.key,
    required this.videoId,
    required this.details,
  });

  final String videoId;

  /// Null until the video's details have loaded.
  final VideoDetailsModel? details;

  @override
  Widget build(BuildContext context) {
    final info = details;
    return OfflineDownloadButton(
      controller: VideoDownloadController.instance,
      itemId: videoId,
      title: info?.title ?? 'Video',
      savedMessage: 'saved for offline viewing',
      request: info == null
          ? null
          : DownloadRequest(
              songId: videoId,
              title: info.title,
              artist: info.ownerId.name,
              coverUrl: info.coverUrl,
              durationMs: info.durationMs,
              genre: info.genre.name,
            ),
    );
  }
}
