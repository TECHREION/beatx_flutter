import 'package:get/get.dart';

import '../../home/controller/offline_content_controller.dart';
import '../../home/services/song_download_service.dart';

/// Offline downloads for audiobooks (`contentType: audiobook`): one download
/// per book, one saved file per chapter. Each chapter is saved under its
/// chapter id, so the book screen's chapter rows find their files directly.
class AudiobookDownloadController extends OfflineContentController {
  AudiobookDownloadController({SongDownloadService? service})
    : super(
        contentType: 'audiobook',
        noun: 'audiobook',
        service: service ?? SongDownloadService(folder: 'audiobook_downloads'),
      );

  /// The shared instance, registered on first use.
  static AudiobookDownloadController get instance {
    if (!Get.isRegistered<AudiobookDownloadController>()) {
      Get.put(AudiobookDownloadController(), permanent: true);
    }
    return Get.find<AudiobookDownloadController>();
  }
}
