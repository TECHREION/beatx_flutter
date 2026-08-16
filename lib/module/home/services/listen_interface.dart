import '../../../core/api_handler/base_repository.dart';
import '../../../core/api_handler/paged_result.dart';
import '../../../core/api_handler/success.dart';
import '../../../core/helpers/typedefs.dart';
import '../model/listem_miusic_detalis_model.dart';
import '../model/listen_model.dart';
import '../model/miusic_stream.dart';
import '../model/on_repeat_model.dart';
import '../model/recently_played_model.dart';
import '../model/song_like_model.dart';

abstract base class ListenInterface extends BaseRepository {
  FutureRequest<Success<ListenMusicModel>> getListen();
  FutureRequest<Success<SongStreamUrlModel>> getListenStreamUrl(String listenId);
  FutureRequest<Success<ListenMusicDetailsModel>> getListenDetails(String listenId);
  FutureRequest<Success<SongLikeModel>> likesong(String songId);
  FutureRequest<Success<List<ListenMusicDetailsModel>>> getLikedSong();
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
  FutureRequest<Success<PagedResult<ListenMusicDetailsModel>>> searchSong({
    required String query,
    required String genreId,
    required int page,
    required int limit,
  });
}