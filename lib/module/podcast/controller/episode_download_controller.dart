import 'package:get/get.dart';

import '../../home/controller/offline_content_controller.dart';
import '../../home/services/song_download_service.dart';

/// Offline downloads for podcast episodes (`contentType: episode`). A saved
/// episode's `artist` holds the show's title.
class EpisodeDownloadController extends OfflineContentController {
  EpisodeDownloadController({SongDownloadService? service})
    : super(
        contentType: 'episode',
        noun: 'episode',
        service: service ?? SongDownloadService(folder: 'episode_downloads'),
      );

  /// The shared instance, registered on first use.
  static EpisodeDownloadController get instance {
    if (!Get.isRegistered<EpisodeDownloadController>()) {
      Get.put(EpisodeDownloadController(), permanent: true);
    }
    return Get.find<EpisodeDownloadController>();
  }
}
