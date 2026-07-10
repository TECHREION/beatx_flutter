import '../../../core/api_handler/base_repository.dart';
import '../../../core/api_handler/success.dart';
import '../../../core/helpers/typedefs.dart';
import '../model/audiobook_model.dart';

abstract base class AudioBookInterface extends BaseRepository {
  FutureRequest<Success<HomeAudiobookData>> audiobookHome();
}
