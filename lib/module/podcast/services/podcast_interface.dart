import '../../../core/api_handler/base_repository.dart';
import '../../../core/api_handler/success.dart';
import '../../../core/helpers/typedefs.dart';
import '../model/episodes_details.dart';
import '../model/episodes_model.dart';
import '../model/get_stream_url_model.dart';
import '../model/podcast_details_model.dart';
import '../model/podcast_home_model.dart';
import '../model/save_progress_data.dart';

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
}