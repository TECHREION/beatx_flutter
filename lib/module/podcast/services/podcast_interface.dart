import '../../../core/api_handler/base_repository.dart';
import '../../../core/api_handler/paged_result.dart';
import '../../../core/api_handler/success.dart';
import '../../../core/helpers/typedefs.dart';
import '../model/episodes_details.dart';
import '../model/episodes_model.dart';
import '../model/get_stream_url_model.dart';
import '../model/podcast_details_model.dart';
import '../model/podcast_home_model.dart';
import '../model/podcast_like_model.dart';
import '../model/save_progress_data.dart';
import '../model/search_category_model.dart';

abstract base class PodcastInterface extends BaseRepository {
  FutureRequest<Success<PodcastHomeData>> podcastHome();
  FutureRequest<Success<PodcastDetailsModel>> podcastDetails(String id);
  FutureRequest<Success<EpisodeStreamData>> getStreamUrl(String id);

  /// One page of a show's episodes (the API caps [limit] at 100).
  FutureRequest<Success<List<EpisodeModel>>> podcastEpisodes(
    String id, {
    int page = 1,
    int limit = 100,
  });
  FutureRequest<Success<EpisodeDetailsData>> episodeDetails(String id);
  FutureRequest<Success<SaveProgressData>> saveProgress(
    String id,
    int positionMs, {
    bool completed = false,
  });
  FutureRequest<Success<SearchCategoryData>> searchCategory(String id);
  FutureRequest<Success<PagedResult<CategoryPodcast>>> searchPodcast({
    required String query,
    required String genreId,
    required int page,
    required int limit,
  });
  FutureRequest<Success<PodcastLikeModel>> likePodcast(String podcastid);
  FutureRequest<Success<List<Podcast>>> getLikedPodcast();

  /// One page of the user's likes, with the total across all pages.
  FutureRequest<Success<PagedResult<Podcast>>> likedPodcastsPage({
    required int page,
    required int limit,
  });
}
