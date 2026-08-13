import 'package:beatx_flutter/module/audiobook/model/audio_book_details_model.dart';

import '../../../core/api_handler/base_repository.dart';
import '../../../core/api_handler/success.dart';
import '../../../core/helpers/typedefs.dart';
import '../model/audio_book_stream_url_model.dart';
import '../model/audiobook_model.dart';

abstract base class AudioBookInterface extends BaseRepository {
  FutureRequest<Success<HomeAudiobookData>> audiobookHome();
  FutureRequest<Success<AudiobookDetailsData>> audiobookDetails(String audiobookId);
  FutureRequest<Success<AudioBookStreamUrlModel>> audiobookStreamUrl(String audiobookId, String chapterId);
}
