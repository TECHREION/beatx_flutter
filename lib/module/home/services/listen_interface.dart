import '../../../core/api_handler/base_repository.dart';
import '../../../core/api_handler/success.dart';
import '../../../core/helpers/typedefs.dart';
import '../model/listem_miusic_detalis_model.dart';
import '../model/listen_model.dart';
import '../model/miusic_stream.dart';

abstract base class ListenInterface extends BaseRepository {
  FutureRequest<Success<ListenMusicModel>> getListen();
  FutureRequest<Success<SongStreamUrlModel>> getListenStreamUrl(String listenId);
  FutureRequest<Success<ListenMusicDetailsModel>> getListenDetails(String listenId);
}