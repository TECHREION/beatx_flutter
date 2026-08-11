import '../../../core/api_handler/base_repository.dart';
import '../../../core/api_handler/success.dart';
import '../../../core/helpers/typedefs.dart';
import '../model/watch_model.dart';

abstract base class VideoInterface extends BaseRepository {
  FutureRequest<Success<HomeData>> videoHome();
}