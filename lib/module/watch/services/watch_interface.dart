import '../../../core/api_handler/base_repository.dart';
import '../../../core/api_handler/success.dart';
import '../../../core/helpers/typedefs.dart';
import '../model/get_stream_url_model.dart';
import '../model/video_details_model.dart';
import '../model/watch_model.dart';

abstract base class VideoInterface extends BaseRepository {
  FutureRequest<Success<HomeData>> videoHome();
  FutureRequest<Success<VideoDetailsModel>> videoDetails(String id);
  FutureRequest<Success<VideoStreamUrlModel>> getStreamUrl(String id) ;
}