import 'dart:async';

import 'package:app_pigeon/app_pigeon.dart';
import 'package:get/get.dart';

import '../../../core/common/widget/now_playing_sheet.dart';
import '../../../core/player/now_playing.dart';
import '../../../core/player/player_controller.dart';
import '../../../core/player/progress_store.dart';
import '../model/episodes_model.dart';
import '../services/podcast_interface.dart';
import '../services/podcast_interface_impl.dart';
import 'episode_download_controller.dart';
import 'podcast_like_controller.dart';
import 'save_progress_controller.dart';

/// Tells the shared player which show an episode belongs to and where it
/// sits in it ("S2 · E5"), and makes the show's episodes the queue, oldest
/// first, so next/previous and the end of an episode move through the show.
///
/// Every place that starts an episode calls [attach] just before
/// `PlayerController.play`.
class PodcastNowPlaying {
  PodcastNowPlaying._();

  static NowPlayingContext? _show;

  /// The show's episodes by id, for playing one from the list.
  static final _episodes = <String, PodcastEpisode>{};
  static String _coverUrl = '';

  /// How long to wait on the server for a resume point before starting from
  /// what this device remembers. Offline the request fails at once; this only
  /// bounds a connection that is up but crawling.
  static const _resumeWait = Duration(seconds: 3);

  /// Where [episodeId] should start: where this user left off, from the
  /// server or this device (whichever is newer), or the beginning when it
  /// was finished. [durationMs] is used when the server reports no length.
  static Future<Duration> resumeFor(
    String episodeId, {
    int durationMs = 0,
  }) async {
    await ProgressStore.ready();
    ({Duration position, bool completed, DateTime? savedAt})? server;
    var length = Duration(milliseconds: durationMs);
    try {
      final result = await _interface()
          .episodeDetails(episodeId)
          .timeout(_resumeWait);
      result.fold((_) {}, (success) {
        final data = success.data;
        if (data == null) return;
        if (data.episode.durationMs > 0) {
          length = Duration(milliseconds: data.episode.durationMs);
        }
        final progress = data.userProgress;
        server = (
          position: Duration(milliseconds: progress?.positionMs ?? 0),
          completed: progress?.completed ?? false,
          savedAt: progress?.lastListenedAt,
        );
      });
    } catch (_) {
      // Timed out: go with what the device has.
    }
    return ProgressStore.choose(id: episodeId, length: length, server: server);
  }

  /// "S2 · E5", or "Episode 5" for a show without seasons.
  static String episodeLabel({
    required int seasonNumber,
    required int episodeNumber,
  }) {
    if (episodeNumber <= 0) return 'Episode';
    if (seasonNumber <= 0) return 'Episode $episodeNumber';
    return 'S$seasonNumber · E$episodeNumber';
  }

  static void attach({
    required String podcastId,
    required String podcastTitle,
    String? podcastCoverUrl,
    required String episodeId,
    required String episodeTitle,
    int seasonNumber = 0,
    int episodeNumber = 0,
    int durationMs = 0,
  }) {
    if (podcastId.isEmpty || episodeId.isEmpty) return;
    final entry = NowPlayingEntry(
      id: episodeId,
      title: episodeTitle,
      label: episodeLabel(
        seasonNumber: seasonNumber,
        episodeNumber: episodeNumber,
      ),
      durationMs: durationMs,
    );

    var show = _show;
    if (show == null || show.collectionId != podcastId) {
      _episodes.clear();
      _coverUrl = podcastCoverUrl ?? '';
      show = NowPlayingContext(
        kind: NowPlayingKind.episode,
        collectionId: podcastId,
        collectionTitle: podcastTitle,
        collectionCoverUrl: _coverUrl,
        entries: [entry],
        playEntry: _playEpisode,
      );
      _show = show;
      unawaited(_loadEpisodes(show));
    } else if (!show.contains(episodeId)) {
      show.entries.add(entry);
    }

    _setQueue(show, episodeId);
    attachNowPlaying(show);
  }

  static PlayerController get _player => Get.isRegistered<PlayerController>()
      ? Get.find<PlayerController>()
      : Get.put(PlayerController(), permanent: true);

  static void _setQueue(NowPlayingContext show, String current) {
    _player.setQueue(
      [for (final e in show.entries) e.id],
      current: current,
      start: _playEpisode,
    );
  }

  static PodcastInterface _interface() {
    if (!Get.isRegistered<PodcastInterface>() &&
        Get.isRegistered<AuthorizedPigeon>()) {
      Get.put<PodcastInterface>(
        PodcastInterfaceImpl(Get.find<AuthorizedPigeon>()),
      );
    }
    return Get.find<PodcastInterface>();
  }

  /// Fills in the rest of the show once playback is under way.
  static Future<void> _loadEpisodes(NowPlayingContext show) async {
    final result = await _interface().podcastEpisodes(show.collectionId);
    final episodes = result.fold(
      (_) => const <PodcastEpisode>[],
      (success) => (success.data ?? const []).expand((p) => p.data).toList(),
    );
    if (episodes.isEmpty || _show != show) return;

    // Listening order: season by season, episode by episode.
    episodes.sort((a, b) {
      final bySeason = a.seasonNumber.compareTo(b.seasonNumber);
      if (bySeason != 0) return bySeason;
      final byNumber = a.episodeNumber.compareTo(b.episodeNumber);
      if (byNumber != 0) return byNumber;
      return (a.publishedAt ?? DateTime(0)).compareTo(
        b.publishedAt ?? DateTime(0),
      );
    });
    final seasons = episodes.map((e) => e.seasonNumber).toSet();
    final grouped = seasons.length > 1;

    for (final e in episodes) {
      _episodes[e.id] = e;
    }
    final loaded = [
      for (final e in episodes)
        NowPlayingEntry(
          id: e.id,
          title: e.title,
          label: episodeLabel(
            seasonNumber: e.seasonNumber,
            episodeNumber: e.episodeNumber,
          ),
          group: grouped && e.seasonNumber > 0
              ? 'Season ${e.seasonNumber}'
              : '',
          durationMs: e.durationMs,
        ),
    ];
    // Keep whatever is playing listed even if the first page missed it.
    final playingId = _player.trackId.value;
    final missing = show.entries.where(
      (e) => e.id == playingId && !loaded.any((l) => l.id == e.id),
    );
    show.entries.assignAll([...loaded, ...missing]);

    if (_player.nowPlaying.value == show) _setQueue(show, playingId);
  }

  /// Plays another episode of the show: from the device when downloaded,
  /// else streamed.
  static Future<void> _playEpisode(String episodeId) async {
    final show = _show;
    if (show == null) return;
    final episode = _episodes[episodeId];
    final entry = show.entry(episodeId);

    final resume = resumeFor(
      episodeId,
      durationMs: episode?.durationMs ?? entry?.durationMs ?? 0,
    );
    final saved = await EpisodeDownloadController.instance.playablePath(
      episodeId,
    );
    var url = saved ?? '';
    if (url.isEmpty) {
      final result = await _interface().getStreamUrl(episodeId);
      url = result.fold((_) => '', (s) => s.data?.streamUrl ?? '');
    }
    if (url.isEmpty) return;

    attach(
      podcastId: show.collectionId,
      podcastTitle: show.collectionTitle,
      podcastCoverUrl: _coverUrl,
      episodeId: episodeId,
      episodeTitle: episode?.title ?? entry?.title ?? '',
      seasonNumber: episode?.seasonNumber ?? 0,
      episodeNumber: episode?.episodeNumber ?? 0,
      durationMs: episode?.durationMs ?? entry?.durationMs ?? 0,
    );
    await _player.play(
      title: episode?.title ?? entry?.title ?? '',
      artist: show.collectionTitle,
      imageAsset: episode?.coverUrl ?? _coverUrl,
      audioAsset: url,
      startAt: await resume,
      trackId: episodeId,
    );

    if (!Get.isRegistered<SaveProgressController>()) {
      Get.put(SaveProgressController(), permanent: true);
    }
    Get.find<SaveProgressController>().start(episodeId);
    PodcastLikeController.instance.load(podcastId: show.collectionId);
  }
}
