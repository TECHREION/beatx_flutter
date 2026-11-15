import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/notifiers/snackbar_notifier.dart';
import '../../../../core/player/player_controller.dart';
import '../../../home/model/downloaded_song_model.dart';
import '../../../home/presentation/screens/audio_play_screen.dart';
import '../../../home/presentation/widgets/downloaded_item_list.dart';
import '../../controller/episode_download_controller.dart';
import '../../controller/save_progress_controller.dart';

/// The podcast episodes saved on this device, for the Downloads screen.
/// Plays straight from the saved file, so it works with no connection.
class DownloadedEpisodeList extends StatelessWidget {
  const DownloadedEpisodeList({
    super.key,
    required this.accent,
    required this.formatBytes,
  });

  final Color accent;
  final String Function(int bytes) formatBytes;

  /// Plays a saved episode and opens the player.
  static Future<void> play(DownloadedSong episode) async {
    final downloads = EpisodeDownloadController.instance;
    final path = await downloads.playablePath(episode.id);
    if (path == null) {
      final context = Get.context;
      if (context != null && context.mounted) {
        SnackbarNotifier(
          context: context,
        ).notifyError(message: 'This episode is no longer on the device.');
      }
      return;
    }
    if (!Get.isRegistered<PlayerController>()) {
      Get.put(PlayerController(), permanent: true);
    }
    Get.find<PlayerController>().play(
      title: episode.title,
      artist: episode.artist,
      imageAsset: downloads.coverPath(episode) ?? episode.artworkUrl,
      audioAsset: path,
      trackId: episode.id,
    );
    // Reports how far the user got whenever there is a connection.
    if (!Get.isRegistered<SaveProgressController>()) {
      Get.put(SaveProgressController(), permanent: true);
    }
    Get.find<SaveProgressController>().start(episode.id);
    Get.to(
      () => const PlayerScreen(),
      transition: Transition.downToUp,
      preventDuplicates: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return DownloadedItemList(
      controller: EpisodeDownloadController.instance,
      accent: accent,
      formatBytes: formatBytes,
      singular: 'episode',
      plural: 'episodes',
      placeholderIcon: Icons.mic_rounded,
      emptyIcon: Icons.podcasts_rounded,
      emptyBody:
          'Tap the download button on an episode to keep it on this device '
          'and listen without internet.',
      onPlay: (files) => play(files.first),
    );
  }
}
