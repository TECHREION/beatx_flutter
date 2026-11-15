import 'package:get/get.dart';

import '../../home/controller/offline_content_controller.dart';
import '../../home/model/downloaded_song_model.dart';
import '../../home/services/song_download_service.dart';

/// Offline downloads for videos (`contentType: video`). A saved video reuses
/// the song record ([DownloadedSong]): `artist` holds the channel name,
/// `fileName` the video file.
class VideoDownloadController extends OfflineContentController {
  VideoDownloadController({SongDownloadService? service})
    : super(
        contentType: 'video',
        noun: 'video',
        service:
            service ??
            SongDownloadService(folder: 'video_downloads', video: true),
      );

  /// The shared instance, registered on first use.
  static VideoDownloadController get instance {
    if (!Get.isRegistered<VideoDownloadController>()) {
      Get.put(VideoDownloadController(), permanent: true);
    }
    return Get.find<VideoDownloadController>();
  }

  /// Every saved video, newest first.
  RxList<DownloadedSong> get videos => files;

  List<DownloadedSong> get visibleVideos => visibleFiles;
}
