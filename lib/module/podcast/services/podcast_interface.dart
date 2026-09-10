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
  FutureRequest<Success<List<EpisodeModel>>> podcastEpisodes(String id);
  FutureRequest<Success<EpisodeDetailsData>> episodeDetails(String id);
  FutureRequest<Success<SaveProgressData>> saveProgress(
    String id,
    int positionMs,
  );
  FutureRequest<Success<SearchCategoryData>> searchCategory(String id);

  /// Podcasts matching [query] and/or [genreId]. Both are empty when unset,
  /// and an unset filter is left off the request rather than sent blank.
  ///
  /// [genreId] is a podcast *category* id — the ids on a show's `category`,
  /// which are a different set from the ones `/genre` hands out.
  FutureRequest<Success<PagedResult<CategoryPodcast>>> searchPodcast({
    required String query,
    required String genreId,
    required int page,
    required int limit,
  });
  FutureRequest<Success<PodcastLikeModel>> likePodcast(String podcastid);
  FutureRequest<Success<List<Podcast>>> getLikedPodcast();
}
