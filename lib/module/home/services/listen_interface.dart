import '../../../core/api_handler/base_repository.dart';
import '../../../core/api_handler/paged_result.dart';
import '../../../core/api_handler/success.dart';
import '../../../core/helpers/typedefs.dart';
import '../model/listem_miusic_detalis_model.dart';
import '../model/listen_model.dart';
import '../model/miusic_stream.dart';
import '../model/offline_download_model.dart';
import '../model/on_repeat_model.dart';
import '../model/recently_played_model.dart';
import '../model/save_progress_model.dart';
import '../model/song_like_model.dart';

abstract base class ListenInterface extends BaseRepository {
  FutureRequest<Success<ListenMusicModel>> getListen();
  FutureRequest<Success<SongStreamUrlModel>> getListenStreamUrl(
    String listenId,
  );
  FutureRequest<Success<ListenMusicDetailsModel>> getListenDetails(
    String listenId,
  );

  /// Registers [songId] as downloaded on this device and returns a fresh link
  /// to its file. Calling it again for the same song and device refreshes it.
  ///
  /// [contentType] is `song` or `video` (`POST /downloads` takes both); for a
  /// video, [songId] is the video's id.
  FutureRequest<Success<SongDownloadGrant>> createSongDownload({
    required String songId,
    required String deviceId,
    required String deviceName,
    String contentType = 'song',
  });
  FutureRequest<Success<void>> reportDownloadStatus(
    String downloadId, {
    required bool completed,
  });
  FutureRequest<Success<void>> deleteDownload(String downloadId);

  /// Checks in the downloads held on this device. Files of the ids it lists in
  /// `remove` must be deleted.
  FutureRequest<Success<DownloadSyncResult>> syncDownloads({
    required String deviceId,
    required List<String> downloadIds,
  });
  FutureRequest<Success<SongLikeModel>> likesong(String songId);
  FutureRequest<Success<List<ListenMusicDetailsModel>>> getLikedSong();

  /// One page of the user's liked songs, with the total across all pages.
  FutureRequest<Success<PagedResult<ListenMusicDetailsModel>>> likedSongsPage({
    required int page,
    required int limit,
  });
  FutureRequest<Success<RecentlyPlayedPage>> recentlyPlayed(
    String userId, {
    required int page,
    required int limit,
  });
  FutureRequest<Success<OnRepeatPage>> onRepeatedSong({
    required int page,
    required int limit,
  });

  /// Songs matching [query] and/or [genreId]. Both are empty when unset, and
  /// an unset filter is left off the request rather than sent blank.
  /// One page of [feed]: new releases, trending, or every song (newest
  /// first), narrowed to [genreId] when it is set.
  FutureRequest<Success<PagedResult<ListenMusicDetailsModel>>> browseSongs({
    required SongFeed feed,
    required String genreId,
    required int page,
    required int limit,
  });

  FutureRequest<Success<PagedResult<ListenMusicDetailsModel>>> searchSong({
    required String query,
    required String genreId,
    required int page,
    required int limit,
  });

  /// The day's picks for the signed-in user. Answers with one unpaged list,
  /// capped at [limit].
  FutureRequest<Success<List<ListenMusicDetailsModel>>> dailyDiscover({
    required int limit,
  });

  /// Records how far the signed-in user has listened to [songId]. The saved
  /// position comes back as the song details' `userProgress`.
  FutureRequest<Success<SaveProgressModel>> saveProgress(
    String songId, {
    required int positionMs,
    bool completed = false,
  });
}

/// The song lists that can be browsed in full.
enum SongFeed {
  newReleases('New Releases'),
  trending('Trending'),
  all('All Songs');

  const SongFeed(this.label);

  final String label;
}
