import '../../../core/api_handler/base_repository.dart';
import '../../../core/api_handler/paged_result.dart';
import '../../../core/api_handler/success.dart';
import '../../../core/helpers/typedefs.dart';
import '../model/get_stream_url_model.dart';
import '../model/like_unlike_model.dart';
import '../model/video_details_model.dart';
import '../model/video_progress_model.dart';
import '../model/watch_model.dart';

abstract base class VideoInterface extends BaseRepository {
  FutureRequest<Success<HomeData>> videoHome();
  FutureRequest<Success<VideoDetailsModel>> videoDetails(String id);
  FutureRequest<Success<VideoStreamUrlModel>> getStreamUrl(String id);
  FutureRequest<Success<List<VideoModel>>> relatedVideos(String id);
  FutureRequest<Success<LikeUnlikeModel>> likeUnlike(String id);
  /// Videos matching [query] and/or [genreId]. Both are empty when unset, and
  /// an unset filter is left off the request rather than sent blank.
  FutureRequest<Success<PagedResult<VideoModel>>> searchVideo({
    required String query,
    required String genreId,
    required int page,
    required int limit,
  });
  /// Saves how far the signed-in user has watched [id].
  ///
  /// There is no matching read: the position saved here comes back on the
  /// video details response as `userProgress`, which is what playback resumes
  /// from.
  FutureRequest<Success<VideoProgressModel>> saveVideoProgress(
    String id, {
    required int positionMs,
    bool completed = false,
  });
}