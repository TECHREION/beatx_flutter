import 'package:beatx_flutter/module/audiobook/model/audio_book_details_model.dart';

import '../../../core/api_handler/base_repository.dart';
import '../../../core/api_handler/paged_result.dart';
import '../../../core/api_handler/success.dart';
import '../../../core/helpers/typedefs.dart';
import '../model/audio_book_like_model.dart';
import '../model/audio_book_stream_url_model.dart';
import '../model/audiobook_model.dart';

abstract base class AudioBookInterface extends BaseRepository {
  FutureRequest<Success<HomeAudiobookData>> audiobookHome();
  FutureRequest<Success<AudiobookDetailsData>> audiobookDetails(
    String audiobookId,
  );
  FutureRequest<Success<AudioBookStreamUrlModel>> audiobookStreamUrl(
    String audiobookId,
    String chapterId,
  );
  FutureRequest<Success<AudioBookLikeModel>> likeAudiobook(String audiobookId);
  FutureRequest<Success<List<Audiobook>>> getLikedAudiobooks();

  /// Saves where the listener is in [audiobookId]: [positionMs] into
  /// [chapterId]. [completed] means the whole book, never one chapter.
  FutureRequest<Success<void>> saveAudiobookProgress(
    String audiobookId, {
    required String chapterId,
    required int positionMs,
    bool completed = false,
  });

  /// Books in the same genre as [audiobookId], to suggest after it.
  FutureRequest<Success<List<Audiobook>>> relatedAudiobooks(
    String audiobookId, {
    int limit = 10,
  });
  FutureRequest<Success<PagedResult<Audiobook>>> searchAudiobook({
    required String query,
    required String genreId,
    required int page,
    required int limit,
  });
}
